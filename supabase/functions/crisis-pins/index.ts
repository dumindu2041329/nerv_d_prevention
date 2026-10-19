/// <reference path="../globals.d.ts" />
// ============================================================================
// Edge Function: crisis-pins
// ----------------------------------------------------------------------------
// Community-reported crisis resources: shelters, water points, toilets,
// road closures, waste sites, relief supply points.
//
// Endpoints:
//   GET  /functions/v1/crisis-pins              -> list all (with filters)
//   GET  /functions/v1/crisis-pins?type=shelter
//   GET  /functions/v1/crisis-pins?bbox=s,w,n,e
//   POST /functions/v1/crisis-pins              -> create new pin (public)
//
// Pin deletion/update are reserved for a future admin tool — not in this
// function yet.
// ============================================================================

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-expect-error — JSR module URL, resolved by Supabase at deploy time
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const VALID_TYPES = new Set([
    "shelter",
    "water",
    "toilet",
    "road",
    "waste",
    "relief_supply",
]);

Deno.serve(async (req: Request) => {
    if (req.method === "OPTIONS") {
        return cors(new Response(null));
    }

    const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    if (req.method === "GET") {
        const url = new URL(req.url);
        const type = url.searchParams.get("type");
        const bbox = url.searchParams.get("bbox"); // "south,west,north,east"

        let query = admin.from("crisis_pins").select("*").order("posted_at", {
            ascending: false,
        });

        if (type && VALID_TYPES.has(type)) {
            query = query.eq("type", type);
        }
        if (bbox) {
            const [s, w, n, e] = bbox.split(",").map(Number);
            if (
                Number.isFinite(s) && Number.isFinite(w) &&
                Number.isFinite(n) && Number.isFinite(e)
            ) {
                query = query
                    .gte("latitude", s)
                    .lte("latitude", n)
                    .gte("longitude", w)
                    .lte("longitude", e);
            }
        }

        const { data, error } = await query.limit(500);
        if (error) {
            console.error("crisis-pins read failed:", error);
            return json({ error: "Read failed" }, 500);
        }
        return json({ pins: data ?? [] }, 200);
    }

    if (req.method === "POST") {
        let body: Record<string, unknown>;
        try {
            body = await req.json();
        } catch {
            return json({ error: "Invalid JSON body" }, 400);
        }

        // verify_jwt=true guarantees the gateway passed a valid JWT. Resolve
        // the actual user so attribution can never be forged via the body.
        const token = req.headers.get("authorization")?.replace(/^Bearer\s+/i, "") ?? "";
        let verifiedUserId: string | null = null;
        if (token) {
            const { data: userData } = await admin.auth.getUser(token);
            verifiedUserId = userData?.user?.id ?? null;
        }
        if (!verifiedUserId) {
            return json({ error: "Authentication required to post a pin" }, 401);
        }

        const type = String(body.type ?? "");
        const name = String(body.name ?? "").trim();
        const lat = Number(body.latitude);
        const lon = Number(body.longitude);
        const description = body.description
            ? String(body.description).trim()
            : null;

        if (!VALID_TYPES.has(type)) {
            return json({ error: `Invalid type. Must be one of: ${[...VALID_TYPES].join(", ")}` }, 400);
        }
        if (name.length < 2 || name.length > 100) {
            return json({ error: "Name must be 2–100 chars" }, 400);
        }
        if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
            return json({ error: "latitude and longitude are required" }, 400);
        }
        if (Math.abs(lat) > 90 || Math.abs(lon) > 180) {
            return json({ error: "Coordinates out of range" }, 400);
        }
        const capacity = body.capacity != null ? Number(body.capacity) : null;
        if (capacity != null && (!Number.isFinite(capacity) || capacity < 0)) {
            return json({ error: "Invalid capacity" }, 400);
        }

        // Validate the expiry server-side: must be a real future timestamp no
        // more than 90 days out. Never trust a client-supplied value blindly.
        let expiresAt: string | null = null;
        if (body.expires_at != null) {
            const t = Date.parse(String(body.expires_at));
            const maxFuture = Date.now() + 90 * 24 * 60 * 60 * 1000;
            if (!Number.isNaN(t) && t > Date.now() && t <= maxFuture) {
                expiresAt = new Date(t).toISOString();
            }
        }

        const pin = {
            id: crypto.randomUUID(),
            type,
            name,
            description,
            latitude: lat,
            longitude: lon,
            address: body.address ? String(body.address).trim() : null,
            capacity,
            is_open: body.is_open === false ? false : true,
            // Derived from the verified session — ignore any client-supplied
            // posted_by so disaster-pin attribution can't be spoofed.
            posted_by: verifiedUserId,
            is_verified: false,
            watch_count: 0,
            expires_at: expiresAt,
        };

        const { data, error } = await admin
            .from("crisis_pins")
            .insert(pin)
            .select()
            .single();

        if (error) {
            console.error("crisis-pins insert failed:", error);
            return json({ error: "Could not create pin" }, 500);
        }
        return json({ pin: data }, 201);
    }

    return json({ error: "Method not allowed" }, 405);
});

function json(body: unknown, status = 200): Response {
    return new Response(JSON.stringify(body), {
        status,
        headers: { "Content-Type": "application/json", ...corsHeaders() },
    });
}

function cors(response: Response): Response {
    for (const [k, v] of Object.entries(corsHeaders())) response.headers.set(k, v);
    return response;
}

function corsHeaders(): Record<string, string> {
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        // Wildcard so supabase-js headers (x-client-info, ...) pass
        // preflight when the app runs on web.
        "Access-Control-Allow-Headers": "*",
    };
}