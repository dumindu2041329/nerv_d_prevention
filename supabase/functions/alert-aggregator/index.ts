/// <reference path="../globals.d.ts" />
// ═══════════════════════════════════════════════════════════════════
// Edge Function: alert-aggregator
// ═══════════════════════════════════════════════════════════════════
// Schedule: every 10 minutes via Supabase Cron, or invoke manually
//           with the service role key.
// Auth:     This function uses SUPABASE_URL +
//           SUPABASE_SERVICE_ROLE_KEY. Do NOT call from the Flutter
//           client directly.
// Sources:  Open-Meteo (forecast) + GDACS RSS.
// Output:   upserts into public.alerts + public.timeline_events.
//
// Deploy:
//   supabase functions deploy alert-aggregator \
//     --project-ref ebccdpydoptajlkmqefx --no-verify-jwt
// ═══════════════════════════════════════════════════════════════════

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-expect-error - JSR module URL, resolved by Supabase at deploy time
import { createClient } from "jsr:@supabase/supabase-js@2.45.4";

// ── Types ─────────────────────────────────────────────────────────
type District = {
  slug: string;
  display_name: string;
  latitude: number;
  longitude: number;
  is_highland: boolean;
  is_coastal: boolean;
};

type Severity =
  | "critical"
  | "emergency"
  | "warning"
  | "advisory"
  | "info"
  | "calm";

type DerivedAlert = {
  id: string;
  type: string;
  headline: string;
  description: string;
  severity: Severity;
  district: string;
  latitude: number;
  longitude: number;
  source: "open_meteo" | "gdacs" | "derived";
  expires_at: string | null;
  metadata: Record<string, unknown>;
};

// ── Config ────────────────────────────────────────────────────────
const OM_BASE = "https://api.open-meteo.com/v1/forecast";
const GDACS_RSS = "https://www.gdacs.org/xml/rss.xml";

const FLOOD_6H_MM = 50;
const FLOOD_24H_MM = 100;
const FLOOD_24H_CRITICAL_MM = 150;
const LANDSLIDE_24H_MM = 100; // highland districts
const COASTAL_WIND_KMH = 40;
const CYCLONE_WIND_KMH = 60;

const SL_BBOX = { latMin: 5.5, latMax: 10.0, lngMin: 79.0, lngMax: 82.5 };

// ── Supabase client (service role) ────────────────────────────────
function client() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
}

// ── Step 1: load the 25 districts from the reference table ────────
async function loadDistricts(): Promise<District[]> {
  const supa = client();
  const { data, error } = await supa
    .from("districts")
    .select(
      "slug, display_name, latitude, longitude, is_highland, is_coastal",
    )
    .order("sort_order");
  if (error) throw error;
  return (data ?? []) as District[];
}

// ── Step 2: derive flood / lightning / coastal / cyclone alerts
//           from Open-Meteo precipitation + wind forecasts ─────────
async function deriveFromOpenMeteo(
  districts: District[],
): Promise<DerivedAlert[]> {
  const out: DerivedAlert[] = [];
  // Batched call: pass all district centres comma-separated.
  const lats = districts.map((d) => d.latitude).join(",");
  const lngs = districts.map((d) => d.longitude).join(",");
  const url =
    `${OM_BASE}?latitude=${lats}&longitude=${lngs}` +
    `&hourly=precipitation,wind_speed_10m,weather_code` +
    `&forecast_days=2&timezone=UTC`;

  const resp = await fetch(url, {
    headers: { "User-Agent": "nerv-aggregator/1.0" },
  });
  if (!resp.ok) {
    console.error("Open-Meteo error", resp.status, await resp.text());
    return out;
  }

  const series = (await resp.json()) as Array<{
    latitude: number;
    longitude: number;
    hourly?: {
      time: string[];
      precipitation: number[];
      wind_speed_10m: number[];
      weather_code: number[];
    };
  }>;

  const now = Date.now();
  for (let i = 0; i < districts.length && i < series.length; i++) {
    const d = districts[i];
    const s = series[i];
    if (!s.hourly) continue;
    const { time, precipitation, wind_speed_10m, weather_code } = s.hourly;
    const startIdx = time.findIndex((t) => new Date(t).getTime() >= now);
    if (startIdx < 0) continue;

    // Windowed precipitation totals
    let precip6h = 0;
    let precip24h = 0;
    for (let h = 0; h < 24 && startIdx + h < precipitation.length; h++) {
      const p = precipitation[startIdx + h] ?? 0;
      if (h < 6) precip6h += p;
      precip24h += p;
    }

    const maxWind = Math.max(
      ...wind_speed_10m
        .slice(startIdx, startIdx + 24)
        .filter((v) => Number.isFinite(v)),
    );
    const thunderIn6h = weather_code
      .slice(startIdx, startIdx + 6)
      .some((c) => c >= 95 && c <= 99);

    // Flood alerts (tiered by rainfall)
    if (precip24h >= FLOOD_24H_CRITICAL_MM) {
      out.push(
        makeAlert(
          d,
          "flood",
          "critical",
          `Critical Flood Warning — ${d.display_name}`,
          `Forecast ${precip24h.toFixed(0)} mm/24h exceeds critical threshold.`,
          "open_meteo",
          { precip6h, precip24h, maxWind },
        ),
      );
    } else if (precip24h >= FLOOD_24H_MM) {
      out.push(
        makeAlert(
          d,
          "flood",
          "emergency",
          `Emergency Flood Warning — ${d.display_name}`,
          `Forecast ${precip24h.toFixed(0)} mm/24h.`,
          "open_meteo",
          { precip6h, precip24h, maxWind },
        ),
      );
    } else if (precip6h >= FLOOD_6H_MM) {
      out.push(
        makeAlert(
          d,
          "flood",
          "warning",
          `Flood Warning — ${d.display_name}`,
          `${precip6h.toFixed(0)} mm forecast in next 6 hours.`,
          "open_meteo",
          { precip6h, precip24h, maxWind },
        ),
      );
    }

    // Landslide (highland districts only)
    if (d.is_highland && precip24h >= LANDSLIDE_24H_MM) {
      out.push(
        makeAlert(
          d,
          "landslide",
          "warning",
          `Landslide Alert — ${d.display_name}`,
          `${precip24h.toFixed(0)} mm/24h in highland district.`,
          "open_meteo",
          { precip24h },
        ),
      );
    }

    // Lightning (thunderstorm codes 95-99)
    if (thunderIn6h) {
      out.push(
        makeAlert(
          d,
          "lightning",
          "advisory",
          `Lightning Alert — ${d.display_name}`,
          "Thunderstorms forecast within 6 hours.",
          "open_meteo",
          {},
        ),
      );
    }

    // Coastal warning (coastal districts + sustained wind)
    if (
      d.is_coastal &&
      maxWind >= COASTAL_WIND_KMH &&
      maxWind < CYCLONE_WIND_KMH
    ) {
      out.push(
        makeAlert(
          d,
          "coastalWarning",
          "advisory",
          `Coastal Warning — ${d.display_name}`,
          `Sustained winds ${maxWind.toFixed(0)} km/h along coast.`,
          "open_meteo",
          { maxWind },
        ),
      );
    }

    // Cyclone (high wind anywhere)
    if (maxWind >= CYCLONE_WIND_KMH) {
      out.push(
        makeAlert(
          d,
          "cyclone",
          "emergency",
          `Cyclone Advisory — ${d.display_name}`,
          `Sustained winds ${maxWind.toFixed(0)} km/h.`,
          "open_meteo",
          { maxWind },
        ),
      );
    }
  }
  return out;
}

function makeAlert(
  d: District,
  type: string,
  severity: Severity,
  headline: string,
  description: string,
  source: DerivedAlert["source"],
  metadata: Record<string, unknown>,
): DerivedAlert {
  const expires = new Date(Date.now() + 6 * 60 * 60 * 1000).toISOString();
  return {
    // 30-minute bucket keeps the same alert id across re-aggregations,
    // so the upsert is a true idempotent update.
    id: `${type}-${d.slug}-${Math.floor(Date.now() / (30 * 60 * 1000))}`,
    type,
    headline,
    description,
    severity,
    district: d.slug,
    latitude: d.latitude,
    longitude: d.longitude,
    source,
    expires_at: expires,
    metadata,
  };
}

// ── Step 3: parse GDACS RSS for cyclones / tsunamis ───────────────
async function deriveFromGdacs(): Promise<DerivedAlert[]> {
  const out: DerivedAlert[] = [];
  try {
    const resp = await fetch(GDACS_RSS, {
      headers: { "User-Agent": "nerv-aggregator/1.0" },
    });
    if (!resp.ok) return out;
    const xml = await resp.text();
    const items = xml.match(/<item>[\s\S]*?<\/item>/g) ?? [];

    for (const item of items) {
      const title =
        item.match(/<title>([\s\S]*?)<\/title>/)?.[1]?.trim() ?? "";
      const link =
        item.match(/<link>([\s\S]*?)<\/link>/)?.[1]?.trim() ?? "";
      const desc =
        item.match(/<description>([\s\S]*?)<\/description>/)?.[1]?.trim() ??
          "";
      const pubDate =
        item.match(/<pubDate>([\s\S]*?)<\/pubDate>/)?.[1]?.trim() ?? "";
      const ts = Date.parse(pubDate) || Date.now();

      const isCyclone = /cyclone|tropical/i.test(title + " " + link);
      const isTsunami = /tsunami/i.test(title + " " + link);
      if (!isCyclone && !isTsunami) continue;

      // Crude lat/lng extraction (GDACS uses "(lat, lng)" in descriptions)
      const m = desc.match(/\(([-\d.]+),\s*([-\d.]+)\)/);
      const lat = m ? parseFloat(m[1]) : null;
      const lng = m ? parseFloat(m[2]) : null;
      const nearSL =
        lat !== null &&
        lng !== null &&
        lat >= SL_BBOX.latMin &&
        lat <= SL_BBOX.latMax &&
        lng >= SL_BBOX.lngMin &&
        lng <= SL_BBOX.lngMax;

      if (isCyclone) {
        out.push({
          id: `gdacs-cyclone-${ts}`,
          type: "cyclone",
          headline: `GDACS Cyclone — ${
            nearSL ? "Sri Lanka Vicinity" : "Indian Ocean"
          }`,
          description: title,
          severity: "critical",
          district: nearSL ? "batticaloa" : "colombo",
          latitude: lat ?? 7.8731,
          longitude: lng ?? 80.7718,
          source: "gdacs",
          expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
          metadata: { link, nearSL },
        });
      }
      if (isTsunami) {
        out.push({
          id: `gdacs-tsunami-${ts}`,
          type: "tsunami",
          headline: "GDACS Tsunami Bulletin — Indian Ocean",
          description: title,
          severity: "critical",
          district: "colombo",
          latitude: lat ?? 0,
          longitude: lng ?? 0,
          source: "gdacs",
          expires_at: new Date(Date.now() + 12 * 60 * 60 * 1000).toISOString(),
          metadata: { link },
        });
      }
    }
  } catch (e) {
    console.error("GDACS parse error", e);
  }
  return out;
}

// ── Step 4: upsert into public.alerts + mirror to timeline_events
async function persist(alerts: DerivedAlert[]) {
  if (alerts.length === 0) return { upserted: 0, events: 0 };
  const supa = client();
  const now = new Date().toISOString();
  const rows = alerts.map((a) => ({
    id: a.id,
    type: a.type,
    headline: a.headline,
    description: a.description,
    severity: a.severity,
    issued_at: now,
    expiry_at: a.expires_at,
    location: a.district,
    district: a.district,
    latitude: a.latitude,
    longitude: a.longitude,
    source: a.source,
    metadata: a.metadata,
  }));
  const { error } = await supa
    .from("alerts")
    .upsert(rows, { onConflict: "id" });
  if (error) {
    console.error("alerts.upsert error", error);
    throw error;
  }

  const events = rows.map((r) => ({
    id: `${r.id}-timeline`,
    alert_id: r.id,
    title: r.headline,
    description: r.description,
    event_type: r.type,
    severity: r.severity,
    occurred_at: r.issued_at,
    district: r.district,
    latitude: r.latitude,
    longitude: r.longitude,
    location: r.district,
    metadata: r.metadata,
  }));
  const { error: tErr } = await supa
    .from("timeline_events")
    .upsert(events, { onConflict: "id" });
  if (tErr) {
    console.error("timeline_events.upsert error", tErr);
    throw tErr;
  }
  return { upserted: rows.length, events: events.length };
}

// ── HTTP handler ──────────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  if (req.method !== "GET" && req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }
  const startedAt = new Date().toISOString();
  try {
    const districts = await loadDistricts();
    const [om, gdacs] = await Promise.all([
      deriveFromOpenMeteo(districts),
      deriveFromGdacs(),
    ]);
    const all = [...om, ...gdacs];
    const persisted = await persist(all);
    return new Response(
      JSON.stringify(
        {
          ok: true,
          started_at: startedAt,
          districts: districts.length,
          derived: all.length,
          ...persisted,
        },
        null,
        2,
      ),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("aggregator error", e);
    return new Response(
      JSON.stringify({
        ok: false,
        error: String(e),
        started_at: startedAt,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
