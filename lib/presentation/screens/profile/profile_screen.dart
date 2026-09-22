import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../blocs/auth/auth_bloc.dart';

/// Profile screen — shows the signed-in user's email and offers account
/// actions (change password, sign out).
///
/// Backed by the app's [AuthBloc] (Supabase email/password auth), which
/// replaced the previous Clerk integration. Implemented as a [StatefulWidget]
/// so the change-password dialog has a stable, lifecycle-aware build context.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthAuthenticated &&
          current.notice != null &&
          (previous is! AuthAuthenticated || previous.notice != current.notice),
      listener: (context, state) {
        final notice = (state as AuthAuthenticated).notice;
        if (notice != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(notice)));
        }
      },
      child: Scaffold(
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
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is! AuthAuthenticated) {
                return const _SignedOutNotice();
              }
              final email = state.user.email;

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.space5),
                children: [
                  _buildAccountCard(theme, email),
                  const SizedBox(height: AppSpacing.space4),
                  _buildActionTile(
                    context,
                    theme,
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Set a new password for your account',
                    onTap: () => _changePassword(context.read<AuthBloc>()),
                  ),
                  const SizedBox(height: AppSpacing.space6),
                  _buildSignOutButton(
                    context,
                    theme,
                    context.read<AuthBloc>(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI builders
  // ---------------------------------------------------------------------------

  Widget _buildAccountCard(ThemeData theme, String? email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(
              Icons.person_outline,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Signed in as',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (email == null || email.isEmpty) ? '—' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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

  Widget _buildSignOutButton(
    BuildContext context,
    ThemeData theme,
    AuthBloc bloc,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmAndSignOut(context, bloc),
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
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _changePassword(AuthBloc bloc) async {
    final result = await _ChangePasswordDialog.show(context);
    if (result == null) return;
    bloc.add(AuthPasswordChangeRequested(newPassword: result));
    // Success/failure is surfaced via the AuthAuthenticated.notice listener.
  }

  Future<void> _confirmAndSignOut(BuildContext context, AuthBloc bloc) async {
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
    // The app-wide auth gate in main.dart rebuilds to the login screen once
    // the session clears, so no explicit navigation is required here.
    bloc.add(const AuthSignOutRequested());
  }
}

/// Small read-only notice shown if the session clears while this screen is
/// mounted (e.g. sign-out in flight).
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

/// Modal dialog that collects (and confirms) a new password. Returns the new
/// password on submit, or `null` if cancelled. Supabase applies the change
/// for the already-authenticated user without requiring the current password.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  static Future<String?> show(BuildContext context) {
    return showDialog<String?>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
  }

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitted = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  static const int _minPasswordLength = 8;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateNewPassword(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v.length < _minPasswordLength) {
      return 'Must be at least $_minPasswordLength characters';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v != _newController.text) return 'Passwords do not match';
    return null;
  }

  void _submit() {
    if (_submitted) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final nav = Navigator.of(context);
    if (!nav.canPop()) return;
    _submitted = true;
    nav.pop(_newController.text);
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
                  'Choose a new password for your account.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newController,
                  obscureText: _obscureNew,
                  autofocus: true,
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
