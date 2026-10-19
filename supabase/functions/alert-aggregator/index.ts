/// <reference path="../globals.d.ts" />
// ═══════════════════════════════════════════════════════════════════
// Edge Function: alert-aggregator
// ═══════════════════════════════════════════════════════════════════
// Schedule: every 10 minutes via Supabase Cron, or invoke manually
//           with the service role key.
// Auth:     The cron job sends the AGGREGATOR_CRON_SECRET (stored in
//           Supabase Vault / exposed as a function secret) as a Bearer
//           token. Manual operators may present the service-role key.
//           Do NOT call from the Flutter client directly.
// Sources:  Open-Meteo (forecast) + GDACS RSS.
// Output:   merges JSON into Supabase Storage bucket `table-exports`
//           (objects: alerts.json). No DB tables, no timeline object —
//           the client derives its timeline locally from the weather feed.
//
// Deploy:
//   supabase functions deploy alert-aggregator \
//     --project-ref muoaodsgpgbtbdhrmnfj
//   (verify_jwt=false is set in supabase/config.toml)
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

// WMO code → WeatherAPI.com condition code (1000–1282). The client's
// WeatherCodeMapping only understands WeatherAPI codes, so anything the
// aggregator derives from Open-Meteo WMO codes must be translated before
// it reaches alerts.json metadata.
function wmoToWeatherApi(wmo: number | null | undefined): number {
  if (wmo == null) return 1000; // Clear
  if (wmo === 0) return 1000; // Clear
  if (wmo === 1 || wmo === 2) return 1003; // Mainly clear / partly cloudy
  if (wmo === 3) return 1009; // Overcast
  if (wmo >= 45 && wmo <= 48) return 1030; // Fog
  if (wmo >= 51 && wmo <= 57) return 1063; // Drizzle
  if (wmo >= 61 && wmo <= 65) return 1195; // Rain (light–heavy)
  if (wmo >= 66 && wmo <= 67) return 1183; // Freezing rain
  if (wmo >= 71 && wmo <= 77) return 1219; // Snow
  if (wmo >= 80 && wmo <= 82) return 1063; // Rain showers
  if (wmo === 85 || wmo === 86) return 1219; // Snow showers
  if (wmo >= 95 && wmo <= 99) return 1276; // Thunderstorm
  return 1000;
}

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
          // Translate the WMO code to a WeatherAPI.com condition code so
          // the client's WeatherCodeMapping (1000–1282) can resolve it.
          { weatherCode: wmoToWeatherApi(weather_code[startIdx]) },
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
  // Deterministic id: bucket the current UTC 6-hour window into the key so
  // the id is stable for the whole life of the alert (expires_at matches
  // the bucket end exactly) and re-aggregation is a true idempotent
  // update. Previously the id rotated every 30 minutes while alerts lived
  // 6 hours, duplicating one persistent hazard up to 12 times.
  const bucket = Math.floor(Date.now() / (6 * 60 * 60 * 1000));
  const bucketEnd = (bucket + 1) * 6 * 60 * 60 * 1000;
  const expires = new Date(bucketEnd).toISOString();
  return {
    id: `${type}-${d.slug}-${severity}-${bucket}`,
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
      // Stable id component: the bulletin's own publish date (day-grain),
      // NOT Date.now() — otherwise every 10-minute poll minted a brand-new
      // "critical" alert and re-notified the whole user base.
      const dayKey = pubDate.slice(0, 16).replace(/[^A-Za-z0-9]/g, "") ||
        new Date().toISOString().slice(0, 10);

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
        Number.isFinite(lat) &&
        Number.isFinite(lng) &&
        lat >= SL_BBOX.latMin &&
        lat <= SL_BBOX.latMax &&
        lng >= SL_BBOX.lngMin &&
        lng <= SL_BBOX.lngMax;

      // This is a Sri Lanka–localized product. Events outside the SL bbox —
      // or bulletins whose coordinates we could not parse — must NOT be
      // published as local critical alerts pinned onto Colombo (or 0,0).
      if (!nearSL) continue;

      if (isCyclone) {
        out.push({
          id: `gdacs-cyclone-${dayKey}`,
          type: "cyclone",
          headline: `GDACS Cyclone — Sri Lanka Vicinity`,
          description: title,
          severity: "critical",
          district: "batticaloa",
          latitude: lat!,
          longitude: lng!,
          source: "gdacs",
          expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
          metadata: { link, nearSL },
        });
      }
      if (isTsunami) {
        out.push({
          id: `gdacs-tsunami-${dayKey}`,
          type: "tsunami",
          headline: "GDACS Tsunami Bulletin — Sri Lanka Vicinity",
          description: title,
          severity: "critical",
          district: "colombo",
          latitude: lat!,
          longitude: lng!,
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

// ── Step 4: merge into Supabase Storage (`table-exports` bucket) ──
// Replaces the old table upserts. Maintains two JSON objects — alerts.json and
// timeline_events.json — applying the same idempotent upsert-by-id semantics
// the DB had, then pruning expired alerts and trimming the timeline to a
// rolling window before writing back. The service-role client bypasses RLS.
type Supa = ReturnType<typeof client>;

const STORAGE_BUCKET = "table-exports";
const ALERTS_PATH = "alerts.json";

type StoredRow = Record<string, unknown> & {
  id: string;
  created_at?: string;
};

async function readStored(supa: Supa, path: string): Promise<StoredRow[]> {
  const { data, error } = await supa.storage
    .from(STORAGE_BUCKET)
    .download(path);
  // Missing object / download failure is treated as an empty store.
  if (error || !data) return [];
  try {
    const parsed: unknown = JSON.parse(await data.text());
    return Array.isArray(parsed) ? (parsed as StoredRow[]) : [];
  } catch {
    return [];
  }
}

// Incoming rows win on conflict but inherit created_at from any prior copy,
// so re-aggregating an existing alert id does not reset its original timestamp.
function mergeById(existing: StoredRow[], incoming: StoredRow[]): StoredRow[] {
  const byId = new Map<string, StoredRow>();
  for (const e of existing) byId.set(e.id, e);
  for (const e of incoming) {
    const prev = byId.get(e.id);
    byId.set(e.id, prev?.created_at ? { ...e, created_at: prev.created_at } : e);
  }
  return [...byId.values()];
}

async function writeJson(supa: Supa, path: string, rows: StoredRow[]) {
  const { error } = await supa.storage
    .from(STORAGE_BUCKET)
    .upload(path, JSON.stringify(rows), {
      contentType: "application/json",
      upsert: true,
      cacheControl: "30",
    });
  if (error) {
    console.error(`storage.upload(${path}) error`, error);
    throw error;
  }
}

async function persist(alerts: DerivedAlert[]) {
  const supa = client();
  const nowIso = new Date().toISOString();
  const nowMs = Date.now();

  const incomingAlerts: StoredRow[] = alerts.map((a) => ({
    id: a.id,
    type: a.type,
    headline: a.headline,
    description: a.description,
    severity: a.severity,
    issued_at: nowIso,
    expiry_at: a.expires_at,
    location: a.district,
    district: a.district,
    latitude: a.latitude,
    longitude: a.longitude,
    source: a.source,
    metadata: a.metadata,
    created_at: nowIso,
    updated_at: nowIso,
  }));

  // Only alerts.json is published. The former timeline_events.json mirror
  // had zero readers in the client (the Timeline screen derives its events
  // locally from the weather snapshot), so it was removed.
  const existingAlerts = await readStored(supa, ALERTS_PATH);

  // Prune expired alerts (parity with the retired expire_stale_alerts RPC).
  const liveAlerts = mergeById(existingAlerts, incomingAlerts).filter(
    (a) => !a.expiry_at || Date.parse(String(a.expiry_at)) > nowMs,
  );

  await writeJson(supa, ALERTS_PATH, liveAlerts);

  return {
    alerts: liveAlerts.length,
    written: incomingAlerts.length,
  };
}

// ── HTTP handler ──────────────────────────────────────────────────
Deno.serve(async (req: Request) => {
  if (req.method !== "GET" && req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // Only the Supabase Cron scheduler (which carries the
  // AGGREGATOR_CRON_SECRET as a Bearer token) or a manual operator
  // presenting the service-role key may invoke this feed-writer. Without
  // this guard any internet caller could burn Open-Meteo / GDACS quota AND
  // overwrite the alerts.json that every app user downloads — a
  // data-integrity attack surface for a disaster-prevention feed.
  // NOTE: verify_jwt=false in config.toml only disables the platform JWT
  // check — it does NOT inject an Authorization header, so pg_net must
  // send the secret explicitly (see the 20261020 migration).
  const auth = req.headers.get("authorization")?.replace(/^Bearer\s+/i, "") ??
    "";
  const cronSecret = Deno.env.get("AGGREGATOR_CRON_SECRET") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const authorized =
    (cronSecret !== "" && auth === cronSecret) ||
    (serviceKey !== "" && auth === serviceKey);
  if (!authorized) {
    return new Response("Forbidden", { status: 403 });
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
    // Never echo internal error/stack text back to the caller.
    return new Response(
      JSON.stringify({
        ok: false,
        error: "internal error",
        started_at: startedAt,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
