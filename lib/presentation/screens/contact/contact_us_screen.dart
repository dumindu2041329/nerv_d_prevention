import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/di/injection.dart';
import '../../../data/remote/contact/contact_api_client.dart';

/// Contact-Us form. Collects name, email, subject, and message, then
/// hands the content off to the user's mail client via [ContactApiClient]
/// (mailto: scheme) — actual delivery happens in the OS mail app.
class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _contactClient = getIt<ContactApiClient>();
  bool _sending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ── Validators ──────────────────────────────────────────────────────

  String? _validateRequired(String? value, {int minLength = 1}) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value.trim().length < minLength) {
      return 'Must be at least $minLength characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Required';
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@"
      r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
      r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
    );
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  // ── Send ────────────────────────────────────────────────────────────

  Future<void> _onSend() async {
    if (_sending) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _sending = true);
    final ok = await _contactClient.sendMessage(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _showSnack('Message sent. We will reply to your email shortly.');
      // Reset form on successful send so the user starts fresh if
      // they navigate back and open Contact Us again.
      _formKey.currentState?.reset();
      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();
    } else {
      _showSnack(
        'Could not send message. Please try again or email '
        '${ContactApiClient.supportEmail} directly.',
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ??
            theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: onSurface, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Contact Us',
          style: TextStyle(
            color: onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Send us a message and we will get back to you.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),
                _buildField(
                  context,
                  label: 'Name',
                  controller: _nameController,
                  validator: _validateRequired,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.space4),
                _buildField(
                  context,
                  label: 'Email Address',
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.space4),
                _buildField(
                  context,
                  label: 'Subject',
                  controller: _subjectController,
                  validator: (v) => _validateRequired(v, minLength: 3),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.space4),
                _buildField(
                  context,
                  label: 'Message',
                  controller: _messageController,
                  validator: (v) => _validateRequired(v, minLength: 10),
                  minLines: 5,
                  maxLines: 10,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: AppSpacing.space6),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _onSend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _sending
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Text('Send'),
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                Center(
                  child: Text(
                    'Messages are delivered to ${ContactApiClient.supportEmail}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int minLines = 1,
    int? maxLines,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.space1,
            bottom: AppSpacing.space2,
          ),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          minLines: minLines,
          maxLines: maxLines,
          style: TextStyle(color: onSurface, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1A1E29).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.96),
            hintText: label,
            hintStyle: TextStyle(
              color: onSurface.withValues(alpha: 0.35),
              fontSize: 15,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: onSurface.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: onSurface.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}