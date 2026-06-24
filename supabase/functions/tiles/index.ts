// ============================================================================
// Edge Function: tiles
// ----------------------------------------------------------------------------
// Proxies raster map tiles from MapTiler (hybrid basemap) and OWM
// (precipitation / clouds / temp / wind / snow / pressure overlays).
//
// Why: the keys for these services must NOT be bundled into the Flutter
// APK. By routing tile requests through this function, the keys stay on
// the server. The function also caches responses in the Supabase edge
// cache (CDN) for 1 hour per tile.
//
// URL scheme from Flutter:
//   GET /functions/v1/tiles/maptiler/hybrid/{z}/{x}/{y}
//   GET /functions/v1/tiles/owm/precipitation_new/{z}/{x}/{y}
//
// We also support the legacy `style` parameter (?style=clouds) for
// OWM variants to keep the URL template short for Flutter.
// ============================================================================

// @ts-expect-error — Deno runtime
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const MAPTILER_KEY = Deno.env.get("MAPTILER_API_KEY");
const OWM_KEY = Deno.env.get("OWM_API_KEY");

Deno.serve(async (req) => {
    const url = new URL(req.url);

    // CORS preflight
    if (req.method === "OPTIONS") {
        return new Response(null, {
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, OPTIONS",
                "Access-Control-Allow-Headers": "*",
                "Access-Control-Max-Age": "86400",
            },
        });
    }

    // /functions/v1/tiles/{provider}/{style}/{z}/{x}/{y}
    // Examples:
    //   tiles/maptiler/hybrid/8/203/142
    //   tiles/owm/precipitation_new/8/203/142
    const parts = url.pathname.split("/").filter(Boolean);
    // parts = ["functions","v1","tiles","maptiler","hybrid","8","203","142"]
    const tilesIdx = parts.indexOf("tiles");
    const segs = parts.slice(tilesIdx + 1); // ["maptiler","hybrid","8","203","142"]

    if (segs.length !== 5) {
        return new Response("Bad tile path", { status: 400 });
    }
    const [provider, style, z, x, y] = segs;
    if (!/^\d{1,2}$/.test(z) || !/^\d{1,8}$/.test(x) || !/^\d{1,8}$/.test(y)) {
        return new Response("Bad tile coords", { status: 400 });
    }

    let upstream: string;
    if (provider === "maptiler") {
        if (!MAPTILER_KEY) return new Response("Server misconfigured", { status: 500 });
        upstream =
            `https://api.maptiler.com/maps/${style}/${z}/${x}/${y}.jpg?key=${MAPTILER_KEY}`;
    } else if (provider === "owm") {
        if (!OWM_KEY) return new Response("Server misconfigured", { status: 500 });
        upstream =
            `https://tile.openweathermap.org/map/${style}/${z}/${x}/${y}.png?appid=${OWM_KEY}`;
    } else {
        return new Response(`Unknown provider: ${provider}`, { status: 404 });
    }

    try {
        const resp = await fetch(upstream, {
            headers: { "User-Agent": "nerv-d-prevention/1.0" },
        });
        if (!resp.ok) {
            // Return transparent 1x1 PNG for missing tiles so flutter_map
            // doesn't show a broken-image pattern.
            if (resp.status === 404) {
                return transparentPng();
            }
            return new Response(`Upstream ${resp.status}`, { status: 502 });
        }
        const body = await resp.arrayBuffer();
        const contentType =
            resp.headers.get("Content-Type") ??
            (provider === "maptiler" ? "image/jpeg" : "image/png");

        return new Response(body, {
            status: 200,
            headers: {
                "Content-Type": contentType,
                // 1 hour at the edge CDN — tiles are stable for weather overlays
                // (precipitation refreshes every ~10 min upstream).
                "Cache-Control": "public, max-age=3600",
                "Access-Control-Allow-Origin": "*",
            },
        });
    } catch (err) {
        console.error("tile fetch failed:", err);
        return transparentPng();
    }
});

// 1x1 transparent PNG — used as a graceful fallback for missing tiles.
function transparentPng(): Response {
    // Hex bytes of a 1x1 transparent PNG.
    const png = Uint8Array.from([
        0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00,
        0x0d, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
    ]);
    return new Response(png, {
        status: 200,
        headers: {
            "Content-Type": "image/png",
            "Cache-Control": "public, max-age=3600",
        },
    });
}