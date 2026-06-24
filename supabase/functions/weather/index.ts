// ============================================================================
// Edge Function: weather
// ----------------------------------------------------------------------------
// Proxies WeatherAPI.com /forecast.json. The API key lives in Supabase
// Secrets and is never sent to the client.
//
// Usage from Flutter:
//   POST {SUPABASE_URL}/functions/v1/weather
//   Body: { latitude: 7.8731, longitude: 80.7718 }
// ============================================================================

// @ts-expect-error — Deno runtime, remote import.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const WEATHER_API_KEY = Deno.env.get("WEATHERAPI_KEY");
const WEATHER_BASE_URL = "https://api.weatherapi.com/v1";

if (!WEATHER_API_KEY) {
    console.error("Missing WEATHERAPI_KEY secret");
}

Deno.serve(async (req) => {
    // CORS preflight for browser-based callers (Flutter native HTTP doesn't
    // send preflight, but this is harmless and helps debugging via browser).
    if (req.method === "OPTIONS") {
        return new Response(null, {
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": "authorization, content-type, apikey",
                "Access-Control-Max-Age": "86400",
            },
        });
    }

    if (req.method !== "POST") {
        return json({ error: "Method not allowed" }, 405);
    }

    if (!WEATHER_API_KEY) {
        return json({ error: "Server misconfigured" }, 500);
    }

    let body: { latitude?: number; longitude?: number };
    try {
        body = await req.json();
    } catch {
        return json({ error: "Invalid JSON body" }, 400);
    }

    const lat = Number(body.latitude);
    const lon = Number(body.longitude);
    if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
        return json({ error: "latitude and longitude are required" }, 400);
    }
    if (Math.abs(lat) > 90 || Math.abs(lon) > 180) {
        return json({ error: "Coordinates out of range" }, 400);
    }

    const upstream = new URL(`${WEATHER_BASE_URL}/forecast.json`);
    upstream.searchParams.set("key", WEATHER_API_KEY);
    upstream.searchParams.set("q", `${lat},${lon}`);
    upstream.searchParams.set("days", "5");
    upstream.searchParams.set("aqi", "no");
    upstream.searchParams.set("alerts", "no");

    try {
        const resp = await fetch(upstream.toString(), {
            headers: { "User-Agent": "nerv-d-prevention/1.0" },
        });

        if (!resp.ok) {
            const text = await resp.text();
            console.error(`WeatherAPI error ${resp.status}: ${text.slice(0, 200)}`);
            return json({ error: "Upstream weather provider error" }, 502);
        }

        const data = await resp.json();
        // 10-minute cache — matches ApiConstants.currentWeatherCacheTtl.
        return json(data, 200, {
            "Cache-Control": "public, max-age=600",
        });
    } catch (err) {
        console.error("weather fetch failed:", err);
        return json({ error: "Upstream fetch failed" }, 502);
    }
});

function json(body: unknown, status = 200, extra: Record<string, string> = {}): Response {
    return new Response(JSON.stringify(body), {
        status,
        headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            ...extra,
        },
    });
}