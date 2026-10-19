// ============================================================================
// Edge Function: geocode
// ----------------------------------------------------------------------------
// Proxies MapTiler Geocoding API. Two operations:
//   POST {q: "Colombo"}                  -> forward search (list of matches)
//   POST {latitude, longitude}           -> reverse geocode (single result)
//
// MapTiler key lives in Supabase Secrets, never sent to client.
// ============================================================================

// Deno runtime globals (Deno, FetchEvent, Response, …)
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const MAPTILER_KEY = Deno.env.get("MAPTILER_API_KEY");
const GEOCODE_BASE = "https://api.maptiler.com/geocoding";

if (!MAPTILER_KEY) {
    console.error("Missing MAPTILER_API_KEY secret");
}

Deno.serve(async (req) => {
    if (req.method === "OPTIONS") {
        return cors(new Response(null));
    }
    if (req.method !== "POST") {
        return json({ error: "Method not allowed" }, 405);
    }
    if (!MAPTILER_KEY) {
        return json({ error: "Server misconfigured" }, 500);
    }

    let body: Record<string, unknown>;
    try {
        body = await req.json();
    } catch {
        return json({ error: "Invalid JSON body" }, 400);
    }

    const url = new URL(GEOCODE_BASE);

    if (typeof body.q === "string" && body.q.trim().length > 0) {
        // Forward geocode.
        const q = body.q.trim();
        // Bound the query length — an anon-key holder must not be able to
        // ship a megabyte of text to MapTiler through our proxied key.
        if (q.length > 120) {
            return json({ error: "Query too long (max 120 chars)" }, 400);
        }
        // Clamp limit to a sane 1–10 range; a raw Number() of an object is
        // NaN (→ 5) and 1e9 would request maximum results and burn quota.
        const rawLimit = Number(body.limit);
        const limit = Number.isFinite(rawLimit)
            ? Math.min(10, Math.max(1, Math.trunc(rawLimit)))
            : 5;
        url.pathname += `/${encodeURIComponent(q)}.json`;
        url.searchParams.set("key", MAPTILER_KEY);
        url.searchParams.set("limit", String(limit));
    } else if (
        Number.isFinite(body.latitude) &&
        Number.isFinite(body.longitude)
    ) {
        // Reverse geocode.
        const lat = Number(body.latitude);
        const lon = Number(body.longitude);
        if (Math.abs(lat) > 90 || Math.abs(lon) > 180) {
            return json({ error: "Coordinates out of range" }, 400);
        }
        url.pathname += `/${lon},${lat}.json`;
        url.searchParams.set("key", MAPTILER_KEY);
        url.searchParams.set("limit", "1");
        url.searchParams.set("types", "municipality,locality,place");
    } else {
        return json(
            { error: "Provide either `q` (string) or `latitude`+`longitude`" },
            400,
        );
    }

    try {
        const resp = await fetch(url.toString(), {
            headers: { "User-Agent": "nerv-d-prevention/1.0" },
        });
        if (!resp.ok) {
            console.error(`MapTiler error ${resp.status}`);
            return json({ error: "Upstream geocoder error" }, 502);
        }
        const data = await resp.json();
        return json(data, 200, {
            "Cache-Control": "public, max-age=3600",
        });
    } catch (err) {
        console.error("geocode fetch failed:", err);
        return json({ error: "Upstream fetch failed" }, 502);
    }
});

function json(
    body: unknown,
    status = 200,
    extra: Record<string, string> = {},
): Response {
    return new Response(JSON.stringify(body), {
        status,
        headers: {
            "Content-Type": "application/json",
            ...corsHeaders(),
            ...extra,
        },
    });
}

function cors(response: Response): Response {
    for (const [k, v] of Object.entries(corsHeaders())) {
        response.headers.set(k, v);
    }
    return response;
}

function corsHeaders(): Record<string, string> {
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        // Wildcard so supabase-js headers (x-client-info, ...) pass
        // preflight when the app runs on web.
        "Access-Control-Allow-Headers": "*",
    };
}