// ═══════════════════════════════════════════════════════════════════
// Shared ambient declarations for the Supabase edge functions.
//
// The `import "jsr:@supabase/functions-js/edge-runtime.d.ts"` line in
// each function is meant to load Deno's global types at runtime, but
// tsc with `moduleResolution: Bundler` does not actually resolve JSR
// URLs, so the types never get loaded. This file provides a minimal
// subset of the Deno global that every edge function needs.
// ═══════════════════════════════════════════════════════════════════

declare global {
  const Deno: {
    readonly env: {
      get(name: string): string | undefined;
    };
    serve(
      handler: (req: Request) => Response | Promise<Response>,
    ): void;
  };
}

export {};
