// ============================================================================
// Edge Function: contact
// ----------------------------------------------------------------------------
// Receives Contact-Us form submissions from the Flutter app and persists
// them to the `contact_messages` table. No longer uses mailto:.
//
// Optional: forward to an email inbox via Resend / SendGrid by adding
// `RESEND_API_KEY` as a Supabase Secret and uncommenting the mail block.
// ============================================================================

// @ts-expect-error — Deno runtime
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-expect-error — Deno remote import
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
// const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY"); // optional email relay

const SUPPORT_INBOX = "nervd.app2demo@gmail.com";

Deno.serve(async (req) => {
    if (req.method === "OPTIONS") {
        return cors(new Response(null));
    }
    if (req.method !== "POST") {
        return json({ error: "Method not allowed" }, 405);
    }

    let body: {
        name?: string;
        email?: string;
        subject?: string;
        message?: string;
        user_id?: string;
    };
    try {
        body = await req.json();
    } catch {
        return json({ error: "Invalid JSON body" }, 400);
    }

    // Basic validation — keep this aggressive. Edge Functions are public.
    const name = (body.name ?? "").trim();
    const email = (body.email ?? "").trim();
    const subject = (body.subject ?? "").trim();
    const message = (body.message ?? "").trim();

    if (name.length < 2 || name.length > 100) {
        return json({ error: "Invalid name" }, 400);
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        return json({ error: "Invalid email" }, 400);
    }
    if (subject.length < 3 || subject.length > 200) {
        return json({ error: "Invalid subject" }, 400);
    }
    if (message.length < 10 || message.length > 5000) {
        return json({ error: "Message must be 10–5000 chars" }, 400);
    }

    // Simple abuse guard: hash the client IP. Same IP can't submit twice
    // within 60 seconds. (Replace with a proper rate limiter for prod.)
    const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "0.0.0.0";
    const ipHash = await sha256(ip);

    const userAgent = req.headers.get("user-agent") ?? null;

    const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { error } = await admin.from("contact_messages").insert({
        name,
        email,
        subject,
        message,
        user_id: body.user_id ?? null,
        user_agent: userAgent,
        ip_hash: ipHash,
    });

    if (error) {
        console.error("contact_messages insert failed:", error);
        return json({ error: "Could not save message" }, 500);
    }

    // Optional: forward via Resend. Uncomment when RESEND_API_KEY is set.
    // if (RESEND_API_KEY) {
    //     await fetch("https://api.resend.com/emails", {
    //         method: "POST",
    //         headers: {
    //             "Authorization": `Bearer ${RESEND_API_KEY}`,
    //             "Content-Type": "application/json",
    //         },
    //         body: JSON.stringify({
    //             from: "NERV App <noreply@nerv.app>",
    //             to: SUPPORT_INBOX,
    //             reply_to: email,
    //             subject: `[Contact] ${subject}`,
    //             text: `From: ${name} <${email}>\n\n${message}`,
    //         }),
    //     }).catch((e) => console.error("Resend relay failed:", e));
    // }

    return json({ ok: true }, 200);
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
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, content-type, apikey",
    };
}

async function sha256(input: string): Promise<string> {
    const bytes = new TextEncoder().encode(input);
    const hash = await crypto.subtle.digest("SHA-256", bytes);
    return Array.from(new Uint8Array(hash))
        .map((b) => b.toString(16).padStart(2, "0"))
        .join("");
}