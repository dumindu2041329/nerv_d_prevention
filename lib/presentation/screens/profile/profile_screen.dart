import 'dart:async';

import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_spacing.dart';

/// Profile screen — shows the signed-in user's email addresses and provides
/// actions to manage the account (add / set-primary / remove emails, reset
/// password, sign out).
///
/// Clerk does not support editing an existing email in place, so the model is
/// "add a new email, verify it, then promote it to primary". The old email
/// is removed explicitly by the user from the list.
///
/// Implemented as a [StatefulWidget] so async flows have a stable,
/// lifecycle-aware [BuildContext] and the [ScaffoldMessengerState] can
/// be captured before any [await] to avoid "use_build_context_synchronously"
/// style runtime crashes.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Set while any Clerk call is mid-flight to avoid duplicate taps
  /// and to keep the [Scaffold] from rebuilding the action tiles.
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: onSurface, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ClerkAuthBuilder(
          signedOutBuilder: (context, authState) =>
              const _SignedOutNotice(),
          signedInBuilder: (context, authState) {
            final user = authState.user;
            final emails = user?.emailAddresses ?? const <clerk.Email>[];
            final hasPassword = user?.passwordEnabled == true;

            return AbsorbPointer(
              absorbing: _busy,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.space5),
                children: [
                  _buildEmailAddressesCard(
                    context,
                    theme,
                    authState,
                    emails,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  // Password is only editable in-app when the account
                  // already has one. Social-login-only accounts can't
                  // have a password added from the Frontend API
                  // (Clerk's `updateUserPassword` requires the current
                  // password and the SDK exposes no `addPassword`).
                  // We show a one-liner explaining the situation
                  // instead of a broken button.
                  if (hasPassword)
                    _buildActionTile(
                      context,
                      theme,
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Update your password using your current one',
                      onTap: _busy ? null : () => _changePassword(authState),
                    )
                  else
                    _buildInfoTile(
                      context,
                      theme,
                      icon: Icons.lock_open,
                      title: 'Password not set',
                      subtitle:
                          'This account was created with a social login. '
                          'Sign out and create a new account with an email '
                          'and password, then link it from the same email '
                          'address to keep your data.',
                    ),
                  const SizedBox(height: AppSpacing.space6),
                  _buildSignOutButton(context, theme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI builders
  // ---------------------------------------------------------------------------

  Widget _buildEmailAddressesCard(
    BuildContext context,
    ThemeData theme,
    ClerkAuthState authState,
    List<clerk.Email> emails,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              AppSpacing.space4,
              AppSpacing.space2,
              AppSpacing.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Email addresses',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _addEmail(authState, emails),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add email'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (emails.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space2,
                AppSpacing.space4,
                AppSpacing.space4,
              ),
              child: Text(
                'No email on file',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            for (var i = 0; i < emails.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                ),
              _buildEmailRow(context, theme, authState, emails[i]),
            ],
        ],
      ),
    );
  }

  Widget _buildEmailRow(
    BuildContext context,
    ThemeData theme,
    ClerkAuthState authState,
    clerk.Email email,
  ) {
    final isPrimary = authState.user?.primaryEmailAddressId == email.id;
    final isVerified = email.isVerified;
    final isOnlyEmail =
        (authState.user?.emailAddresses?.length ?? 0) <= 1;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 20,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        email.emailAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isPrimary) ...[
                      const SizedBox(width: 8),
                      _Badge(
                        label: 'Primary',
                        color: const Color(0xFF00E676),
                        icon: Icons.verified,
                      ),
                    ] else if (isVerified) ...[
                      const SizedBox(width: 8),
                      _Badge(
                        label: 'Linked',
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.45),
                        icon: null,
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      _Badge(
                        label: 'Unverified',
                        color: theme.colorScheme.error,
                        icon: Icons.error_outline,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'added ${timeago.format(email.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<_EmailAction>(
            tooltip: 'Email actions',
            icon: Icon(
              Icons.more_horiz,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
            onSelected: (action) => _onEmailAction(
              context,
              authState,
              email,
              action,
              isPrimary: isPrimary,
              isOnlyEmail: isOnlyEmail,
            ),
            itemBuilder: (popupContext) {
              final entries = <PopupMenuEntry<_EmailAction>>[];
              if (!isPrimary) {
                entries.add(
                  PopupMenuItem<_EmailAction>(
                    value: _EmailAction.setPrimary,
                    child: Row(
                      children: const [
                        Icon(Icons.star_outline, size: 18),
                        SizedBox(width: 10),
                        Text('Set as primary'),
                      ],
                    ),
                  ),
                );
              }
              if (!isVerified) {
                entries.add(
                  PopupMenuItem<_EmailAction>(
                    value: _EmailAction.verify,
                    child: Row(
                      children: const [
                        Icon(Icons.mark_email_read_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Resend code'),
                      ],
                    ),
                  ),
                );
              }
              if (!isOnlyEmail) {
                entries.add(
                  PopupMenuItem<_EmailAction>(
                    value: _EmailAction.remove,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Remove',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (entries.isEmpty) {
                entries.add(
                  const PopupMenuItem<_EmailAction>(
                    enabled: false,
                    child: Text('No actions available'),
                  ),
                );
              }
              return entries;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space4,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              size: 22,
            ),
            const SizedBox(width: AppSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Read-only row used for informational entries (e.g. "Password not
  /// set" for social-login accounts). Same look as [_buildActionTile]
  /// minus the chevron and the tappable feedback, so the user can tell
  /// the row is not interactive.
  Widget _buildInfoTile(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            size: 22,
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _confirmAndSignOut,
        icon: Icon(Icons.logout, size: 20, color: theme.colorScheme.error),
        label: Text(
          'Sign Out',
          style: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: theme.colorScheme.error, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Email actions
  // ---------------------------------------------------------------------------

  Future<void> _onEmailAction(
    BuildContext context,
    ClerkAuthState authState,
    clerk.Email email,
    _EmailAction action, {
    required bool isPrimary,
    required bool isOnlyEmail,
  }) async {
    switch (action) {
      case _EmailAction.setPrimary:
        await _setPrimary(authState, email);
      case _EmailAction.verify:
        await _resendCode(authState, email);
      case _EmailAction.remove:
        await _removeEmail(context, authState, email, isPrimary: isPrimary);
    }
  }

  /// Adds a new email to the account, verifying it via the email code.
  /// The user is then asked whether to promote the new email to primary.
  Future<void> _addEmail(
    ClerkAuthState authState,
    List<clerk.Email> existing,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    // 1. Collect the new email.
    final newEmail = await _promptNewEmail(existing);
    if (newEmail == null) return;
    if (!_isValidEmail(newEmail)) {
      _snack(messenger, 'Please enter a valid email address.');
      return;
    }
    if (existing.any((e) =>
        e.emailAddress.toLowerCase() == newEmail.toLowerCase())) {
      _snack(messenger, 'That email is already on your account.');
      return;
    }

    // Defer the setState until after the dialog has fully torn down.
    // Calling setState synchronously after `showDialog` returns fires
    // Flutter's `_dependents.isEmpty` assertion because the dialog's
    // InheritedWidgets are still being deactivated.
    await _awaitNextFrame();
    if (!mounted) return;
    setState(() => _busy = true);

    // 2. Register the new email with Clerk — sends the verification code.
    clerk.UserIdentifyingData? newUid;
    try {
      newUid = await _addIdentifyingData(authState, newEmail);
    } catch (e, st) {
      debugPrint('ProfileScreen._addEmail _addIdentifyingData error: $e\n$st');
    }

    if (newUid == null) {
      if (mounted) setState(() => _busy = false);
      _snack(messenger, 'Could not send the verification code. Please try again.');
      return;
    }

    final clerk.UserIdentifyingData uid = newUid;

    // 3. Verify the code, with retry / resend / edit options.
    while (true) {
      if (!mounted) {
        setState(() => _busy = false);
        return;
      }
      messenger.hideCurrentSnackBar();

      final code = await _promptVerificationCode(newEmail);
      if (code == null) {
        if (mounted) setState(() => _busy = false);
        _snack(
          messenger,
          'Email added but not verified. You can resend the code from the list.',
        );
        return;
      }
      if (!mounted) {
        setState(() => _busy = false);
        return;
      }

      bool ok = false;
      try {
        ok = await _verifyCode(authState, uid, newEmail, code);
      } catch (e, st) {
        debugPrint('ProfileScreen._addEmail _verifyCode error: $e\n$st');
      }

      if (ok) break;

      final retry = await _promptCodeRetry(newEmail);
      if (retry == _CodeRetry.resend) {
        try {
          await authState.addIdentifyingData(
            newEmail,
            clerk.IdentifierType.emailAddress,
          );
          _snack(messenger, 'A new verification code has been sent.');
        } catch (e, st) {
          debugPrint('resend error: $e\n$st');
          _snack(messenger, 'Could not resend the code. Please try again.');
        }
        continue;
      }
      if (retry == _CodeRetry.edit || retry == _CodeRetry.cancel) {
        if (mounted) setState(() => _busy = false);
        _snack(
          messenger,
          'Email added but not verified. You can resend the code from the list.',
        );
        return;
      }
    }

    if (!mounted) {
      setState(() => _busy = false);
      return;
    }

    // 4. Ask the user if they want to make the new email primary.
    final promote = await _confirmPromote(newEmail);
    if (promote == true) {
      final promoted = await _setPrimary(authState, uid);
      if (!mounted) {
        return;
      }
      if (!promoted) {
        _snack(
          messenger,
          'Email verified but could not be set as primary.',
        );
      } else {
        _snack(messenger, '$newEmail is now your primary email.');
      }
    } else {
      if (!mounted) return;
      _snack(messenger, '$newEmail added and verified.');
    }

    if (mounted) setState(() => _busy = false);
  }

  /// Promotes an already-verified email to primary. Returns `true` if
  /// Clerk confirmed the change.
  Future<bool> _setPrimary(
    ClerkAuthState authState,
    clerk.UserIdentifyingData uid,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!uid.isVerified) {
      _snack(messenger, 'Verify the email before making it primary.');
      return false;
    }
    setState(() => _busy = true);
    try {
      await authState.updateUser(primaryEmailAddressId: uid.id);
      if (mounted) {
        _snack(messenger, 'Primary email updated.');
      }
      return true;
    } on clerk.ClerkError catch (e) {
      debugPrint('updateUser ClerkError: ${e.message}');
      if (mounted) _snack(messenger, 'Could not update: ${e.message}');
      return false;
    } catch (e, st) {
      debugPrint('updateUser error: $e\n$st');
      if (mounted) {
        _snack(messenger, 'Could not update primary email. Please try again.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Re-runs the verification flow for an existing unverified email.
  Future<void> _resendCode(
    ClerkAuthState authState,
    clerk.Email email,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      // addIdentifyingData on an existing identifier is a safe no-op that
      // re-sends the verification code.
      await authState.addIdentifyingData(
        email.emailAddress,
        clerk.IdentifierType.emailAddress,
      );
      if (!mounted) return;
      final code = await _promptVerificationCode(email.emailAddress);
      if (code == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      if (!mounted) return;
      final ok = await _verifyCode(authState, email, email.emailAddress, code);
      if (!mounted) return;
      _snack(
        messenger,
        ok ? '${email.emailAddress} verified.' : 'Code did not match.',
      );
    } on clerk.ClerkError catch (e) {
      debugPrint('resend ClerkError: ${e.message}');
      if (mounted) _snack(messenger, 'Could not resend: ${e.message}');
    } catch (e, st) {
      debugPrint('resend error: $e\n$st');
      if (mounted) {
        _snack(messenger, 'Could not resend the code. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Removes an email from the account, with a confirmation step. The
  /// primary email cannot be removed unless the user confirms — but the
  /// flow is not allowed at all if the email is the only one on the account.
  Future<void> _removeEmail(
    BuildContext context,
    ClerkAuthState authState,
    clerk.Email email, {
    required bool isPrimary,
  }) async {
    // Capture the messenger once — do not look it up again after an [await].
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isPrimary
              ? 'Remove primary email?'
              : 'Remove email?'),
          content: Text(isPrimary
              ? '${email.emailAddress} is your primary email. Removing it will leave your account without a primary email until you add and verify a new one.\n\nContinue?'
              : 'Remove ${email.emailAddress} from your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    if (!mounted) return;

    // Defer the setState until after the confirmation dialog has fully
    // torn down (same reason as `_addEmail`).
    await _awaitNextFrame();
    if (!mounted) return;
    setState(() => _busy = true);

    try {
      await authState.deleteIdentifyingData(email);
      if (mounted) {
        _snack(messenger, '${email.emailAddress} removed.');
      }
    } on clerk.ClerkError catch (e) {
      debugPrint('deleteIdentifyingData ClerkError: ${e.message}');
      if (mounted) _snack(messenger, 'Could not remove: ${e.message}');
    } catch (e, st) {
      debugPrint('deleteIdentifyingData error: $e\n$st');
      if (mounted) {
        _snack(messenger, 'Could not remove the email. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Clerk wrappers
  // ---------------------------------------------------------------------------

  Future<clerk.UserIdentifyingData?> _addIdentifyingData(
    ClerkAuthState authState,
    String newEmail,
  ) async {
    try {
      await authState.addIdentifyingData(
        newEmail,
        clerk.IdentifierType.emailAddress,
      );
      return authState.user?.identifierFrom(newEmail);
    } on clerk.ClerkError catch (e) {
      debugPrint('addIdentifyingData ClerkError: ${e.message}');
      return null;
    } catch (e, st) {
      debugPrint('addIdentifyingData error: $e\n$st');
      return null;
    }
  }

  Future<bool> _verifyCode(
    ClerkAuthState authState,
    clerk.UserIdentifyingData uid,
    String newEmail,
    String code,
  ) async {
    try {
      await authState.verifyIdentifyingData(uid, code);
      final refreshed = authState.user?.identifierFrom(newEmail);
      return refreshed?.isVerified ?? false;
    } on clerk.ClerkError catch (e) {
      debugPrint('verifyIdentifyingData ClerkError: ${e.message}');
      return false;
    } catch (e, st) {
      debugPrint('verifyIdentifyingData error: $e\n$st');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Password change flow
  // ---------------------------------------------------------------------------

  /// Shows the in-app change-password form and, on submit, calls Clerk's
  /// `updateUserPassword` to swap the password immediately. No email
  /// verification code is involved. Only available for accounts that
  /// already have a password (i.e. not social-login-only accounts).
  Future<void> _changePassword(ClerkAuthState authState) async {
    final messenger = ScaffoldMessenger.of(context);

    final result = await _ChangePasswordDialog.show(context);
    if (result == null) return;

    // Defer the setState until after the dialog has fully torn down
    // (same reason as `_addEmail`).
    await _awaitNextFrame();
    if (!mounted) return;
    setState(() => _busy = true);

    try {
      await authState.updateUserPassword(
        result.currentPassword,
        result.newPassword,
      );
      if (!mounted) return;
      _snack(messenger, 'Password updated.');
    } on clerk.ClerkError catch (e) {
      debugPrint('updateUserPassword ClerkError: ${e.message}');
      if (mounted) {
        _snack(
          messenger,
          _friendlyPasswordError(e),
        );
      }
    } catch (e, st) {
      debugPrint('updateUserPassword error: $e\n$st');
      if (mounted) {
        _snack(messenger, 'Could not update your password. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Maps common ClerkError codes for password update to user-friendly
  /// messages. Falls back to the raw Clerk message if the code isn't
  /// recognised.
  String _friendlyPasswordError(clerk.ClerkError e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('current password') || msg.contains('incorrect')) {
      return 'Current password is incorrect.';
    }
    if (msg.contains('too short') || msg.contains('password length')) {
      return 'New password is too short.';
    }
    if (msg.contains('same as') || msg.contains('identical')) {
      return 'New password must be different from the current one.';
    }
    return 'Could not update your password: ${e.message}';
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  Future<void> _confirmAndSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text("You'll need to sign in again to use NERV."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      await ClerkAuth.of(context).signOut();
      if (!mounted) return;
      context.pop();
    } catch (e, st) {
      debugPrint('signOut error: $e\n$st');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  Future<String?> _promptNewEmail(List<clerk.Email> existing) {
    return _AddEmailDialog.show(context);
  }

  /// Shows a prominent dialog asking the user to enter the 6-digit code
  /// that Clerk just emailed to [email]. Returns the trimmed code, or
  /// `null` if the user cancels.
  Future<String?> _promptVerificationCode(String email) {
    return _VerificationCodeDialog.show(context, email: email);
  }

  /// After an incorrect code, lets the user choose to resend, edit the
  /// email, or cancel the whole flow.
  Future<_CodeRetry> _promptCodeRetry(String email) async {
    final result = await showDialog<_CodeRetry>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Wrong code'),
          content: Text(
            "The code you entered didn't match. Would you like to:\n\n"
            '• Resend a new code to $email\n'
            '• Edit the email address\n'
            '• Cancel',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_CodeRetry.cancel),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_CodeRetry.edit),
              child: const Text('Edit email'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_CodeRetry.resend),
              child: const Text('Resend code'),
            ),
          ],
        );
      },
    );
    return result ?? _CodeRetry.cancel;
  }

  /// Asks the user if they want to promote the new, verified email to primary.
  Future<bool?> _confirmPromote(String email) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set as primary?'),
          content: Text(
            '$email is now verified. Would you like to make it your primary '
            'email? You can do this later from the list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Set as primary'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value);
  }

  /// Resolves on the next post-frame callback. Use this to defer a
  /// [setState] until after a dialog has finished tearing down — calling
  /// [setState] synchronously in the same microtask as a `Navigator.pop`
  /// trips Flutter's `_dependents.isEmpty` assertion in
  /// `InheritedElement.deactivate`.
  Future<void> _awaitNextFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  void _snack(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _EmailAction { setPrimary, verify, remove }

enum _CodeRetry { resend, edit, cancel }

/// Small pill used for "Primary" / "Linked" / "Unverified" status badges
/// on each email row.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal dialog that asks for the current password, a new password,
/// and a confirmation. Returns a [_ChangePasswordResult] on success, or
/// `null` if cancelled. No email verification is involved — the change
/// is applied immediately via Clerk's `updateUserPassword`.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  /// Convenience launcher so the State can stay private.
  static Future<_ChangePasswordResult?> show(BuildContext context) {
    return showDialog<_ChangePasswordResult>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
  }

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitted = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  static const int _minPasswordLength = 8;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  String? _validateNewPassword(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v.length < _minPasswordLength) {
      return 'Must be at least $_minPasswordLength characters';
    }
    if (v == _currentController.text) {
      return 'New password must be different from current';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v != _newController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _submit() {
    if (_submitted) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final nav = Navigator.of(context);
    if (!nav.canPop()) return;
    _submitted = true;
    nav.pop(
      _ChangePasswordResult(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      ),
    );
  }

  void _cancel() {
    if (_submitted) return;
    final nav = Navigator.of(context);
    if (!nav.canPop()) return;
    _submitted = true;
    nav.pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Change password'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your current password and choose a new one.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentController,
                  obscureText: _obscureCurrent,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _obscureCurrent = !_obscureCurrent,
                      ),
                    ),
                  ),
                  validator: _validateRequired,
                  onChanged: (_) {
                    // Re-run the "new password" validator when the
                    // current value changes, since the same-as check
                    // depends on it.
                    _formKey.currentState?.validate();
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newController,
                  obscureText: _obscureNew,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: _validateNewPassword,
                  onChanged: (_) {
                    // The confirm field depends on this value.
                    if (_confirmController.text.isNotEmpty) {
                      _formKey.currentState?.validate();
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _obscureConfirm = !_obscureConfirm,
                      ),
                    ),
                  ),
                  validator: _validateConfirm,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Change'),
        ),
      ],
    );
  }
}

@immutable
class _ChangePasswordResult {
  const _ChangePasswordResult({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

/// Modal dialog that asks the user to enter a new email address to add
/// to their account. Returns the trimmed value, or `null` if cancelled.
///
/// Implemented as a [StatefulWidget] so the [TextEditingController] is
/// owned by the dialog's own [State] and disposed automatically. Sharing
/// a controller between the caller and the dialog can race with the
/// dialog's teardown and trigger the `_dependents.isEmpty` framework
/// assertion.
class _AddEmailDialog extends StatefulWidget {
  const _AddEmailDialog();

  /// Convenience launcher so the State can stay private.
  static Future<String?> show(BuildContext context) {
    return showDialog<String?>(
      context: context,
      builder: (_) => const _AddEmailDialog(),
    );
  }

  @override
  State<_AddEmailDialog> createState() => _AddEmailDialogState();
}

class _AddEmailDialogState extends State<_AddEmailDialog> {
  late final TextEditingController _controller;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    final nav = Navigator.of(context);
    if (!nav.canPop()) return;
    _submitted = true;
    nav.pop(_controller.text.trim());
  }

  void _cancel() {
    if (_submitted) return;
    final nav = Navigator.of(context);
    if (!nav.canPop()) return;
    _submitted = true;
    nav.pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Add email'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter the email address you'd like to add. We'll send a "
            'verification code to confirm it belongs to you.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Email address',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Send Code'),
        ),
      ],
    );
  }
}

/// Modal dialog that asks the user to enter the 6-digit verification code
/// Clerk sent to their email address. Returns the trimmed code, or
/// `null` if the user cancels.
class _VerificationCodeDialog extends StatefulWidget {
  const _VerificationCodeDialog({required this.email});

  final String email;

  /// Convenience launcher so the State can stay private.
  static Future<String?> show(
    BuildContext context, {
    required String email,
  }) {
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VerificationCodeDialog(email: email),
    );
  }

  @override
  State<_VerificationCodeDialog> createState() =>
      _VerificationCodeDialogState();
}

class _VerificationCodeDialogState extends State<_VerificationCodeDialog> {
  late final TextEditingController _controller;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    final value = _controller.text.trim();
    if (value.length != 6) return;
    final nav = Navigator.of(context);
    if (!nav.canPop()) return;
    _submitted = true;
    nav.pop(value);
  }

  void _cancel() {
    if (_submitted) return;
    final nav = Navigator.of(context);
    if (!nav.canPop()) return;
    _submitted = true;
    nav.pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Verify email'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter the 6-digit code we sent to:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (mounted) setState(() {});
            },
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Verification code',
              hintText: '••••••',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().length == 6 ? _submit : null,
          child: const Text('Verify'),
        ),
      ],
    );
  }
}

class _SignedOutNotice extends StatelessWidget {
  const _SignedOutNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space5),
        child: Text(
          'You are signed out.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
