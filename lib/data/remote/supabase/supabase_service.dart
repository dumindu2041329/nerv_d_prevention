import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes the Supabase client and exposes a singleton handle.
///
/// The Supabase client is used for:
///   - Calling Edge Functions (weather, geocode, tiles, contact, crisis-pins)
///   - Reading/writing Postgres tables (alerts, sos_alerts, crisis_pins, ...)
///   - Subscribing to Realtime channels (live alert updates on Home)
///
/// Auth is intentionally NOT used — Clerk is the auth provider. Supabase
/// auth is disabled in `supabase/config.toml`. The anon key is safe to
/// ship in the client; server-side secrets (WEATHERAPI_KEY etc.) live in
/// Supabase Secrets and are never exposed.
class SupabaseService {
  SupabaseClient get client => Supabase.instance.client;

  /// The Supabase project URL, used to construct Edge Function URLs and
  /// tile proxy URLs.
  String get baseUrl => dotenv.get('SUPABASE_URL');

  /// Construct the public URL for an Edge Function invocation.
  ///
  ///   functionUrl('weather') =>
  ///     'https://{project-ref}.supabase.co/functions/v1/weather'
  String functionUrl(String functionName) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/functions/v1/$functionName';
  }

  /// Initialize Supabase. Call once during app startup, BEFORE any
  /// DI that depends on [SupabaseService].
  Future<void> init() async {
    final url = dotenv.get('SUPABASE_URL');
    final anonKey = dotenv.get('SUPABASE_ANON_KEY');

    if (url.contains('YOUR-PROJECT-REF') ||
        anonKey.contains('YOUR-ANON-KEY')) {
      // Hard fail at startup so the developer sees a clear message
      // instead of obscure network errors at runtime.
      throw StateError(
        'Supabase is not configured. Update SUPABASE_URL and '
        'SUPABASE_ANON_KEY in .env (see supabase/README.md).',
      );
    }

    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
      // Realtime uses long-lived websockets. The default settings work
      // for mobile, but we explicitly disable debug logs in release.
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        // Auth is handled by Clerk. Disable Supabase's auto-refresh so it
        // does not interfere with the Clerk session lifecycle.
        autoRefreshToken: false,
      ),
    );
  }
}