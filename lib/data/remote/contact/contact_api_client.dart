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
  /// Recipient inbox for Contact-Us submissions. The inbox is no longer
  /// used directly by the client — it remains here for display in the UI
  /// ("Messages are delivered to …") and for the optional Resend relay
  /// configured inside the Edge Function.
  static const String supportEmail = 'nervd.app2demo@gmail.com';

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
