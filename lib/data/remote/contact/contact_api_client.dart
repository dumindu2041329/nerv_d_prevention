import 'package:url_launcher/url_launcher.dart';

/// Sends Contact-Us form submissions to the support inbox.
///
/// The app has no backend server, so the actual email transport is
/// delegated to the user's mail client via the `mailto:` scheme. Tapping
/// Send opens the OS mail app pre-filled with the form contents; the
/// user confirms the send from there.
///
/// If a backend relay is later added (e.g. EmailJS, Formspree, or a
/// custom endpoint), swap [sendMessage] for an HTTP POST — the screen
/// only depends on this single method.
class ContactApiClient {
  /// Recipient inbox for all Contact-Us submissions.
  static const String supportEmail = 'nervd.app2demo@gmail.com';

  /// Opens the user's mail client with a pre-filled `mailto:` URL.
  ///
  /// Returns `true` if the mail client was launched, `false` if no mail
  /// app is installed or the URL could not be opened.
  Future<bool> sendMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final body = StringBuffer()
      ..writeln('From: $name <$email>')
      ..writeln()
      ..writeln(message);
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': subject,
        'body': body.toString(),
      },
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}