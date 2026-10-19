import 'package:supabase_flutter/supabase_flutter.dart';

/// Sends Contact-Us form submissions to the Supabase `contact` Edge
/// Function, which persists them to the `contact_messages` table.
///
/// Previously this used `mailto:` to hand off to the user's mail client.
/// The Supabase route lets us:
///   - Capture submissions for support review
///   - Rate-limit abuse via the Edge Function
///   - (Optionally) forward to email via Resend when RESEND_API_KEY is set
///
/// See `supabase/functions/contact/index.ts`.
class ContactApiClient {
  /// Placeholder support inbox for local/dev builds ONLY. Production
  /// deployments must not surface a hardcoded personal mailbox: the real
  /// recipient lives server-side in the `contact` Edge Function's
  /// SUPPORT_INBOX secret, and this client no longer displays or uses an
  /// address in the UI. Retained solely so the Resend-relay note compiles.
  static const String supportEmail = '';

  final SupabaseClient _client;

  ContactApiClient({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Submits the contact form via the Supabase `contact` Edge Function.
  /// Returns `true` if the server accepted the message (HTTP 200),
  /// `false` on any error or validation rejection.
  Future<bool> sendMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      // Resolve the signed-in user at call time so the attribution always
      // reflects the current Supabase Auth session.
      final userId = _client.auth.currentUser?.id;
      final response = await _client.functions.invoke(
        'contact',
        body: {
          'name': name,
          'email': email,
          'subject': subject,
          'message': message,
          'user_id': ?userId,
        },
      );
      return response.status == 200;
    } catch (_) {
      return false;
    }
  }
}
