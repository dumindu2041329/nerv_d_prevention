import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../blocs/settings/settings_bloc.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildTitle(context),
                _buildColorStripe(),
                _buildSavedRegions(context),
                const SizedBox(height: 16),
                _buildSettingsSection(context, state, l10n),
                _buildAboutSection(context, l10n),
                _buildFooter(context, l10n),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          l10n.t('menu.title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildColorStripe() {
    return Container(
      height: 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF1744),
            Color(0xFFFF9100),
            Color(0xFFFFEA00),
            Color(0xFF00E676),
            Color(0xFF00B0FF),
            Color(0xFF651FFF),
            Color(0xFFFF4081),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedRegions(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Saved Regions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '0 / 3',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'None',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'You can add up to 3 regions',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      color: theme.colorScheme.onSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    SettingsState state,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.t('settings.title')),
        _buildMenuItem(
          context,
          l10n.t('menu.language'),
          trailing: l10n.t(_languageKey(state.language)),
          onTap: () => _showLanguageSelector(context, state.language),
        ),
        InkWell(
          onTap: () => _showAppearanceSelector(context, state.isDarkMode),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                Expanded(
                  child: Text(
                    'Appearance',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  state.isDarkMode ? 'Dark' : 'Light',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  state.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        _buildNotificationsToggle(context, state),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildSectionTitle(context, l10n.t('menu.about')),
        _buildMenuItem(
          context,
          l10n.t('menu.version'),
          trailing: '1.0.0',
          showChevron: false,
        ),
        _buildMenuItem(context, 'Contact Us', onTap: () => context.push('/contact-us')),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      color: theme.colorScheme.surfaceTint.withValues(alpha: 0.12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title, {
    String? trailing,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            if (showChevron) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsToggle(BuildContext context, SettingsState state) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            Icons.notifications_outlined,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.t('settings.notifications'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.notificationsEnabled ? 'On' : 'Off',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: state.notificationsEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: state.notificationsEnabled,
            onChanged: (_) {
              context
                  .read<SettingsBloc>()
                  .add(const ToggleNotifications());
            },
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_outlined,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Theo DC_',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('settings.alertsDmc'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _languageKey(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'menu.language.english';
      case AppLanguage.sinhala:
        return 'menu.language.sinhala';
      case AppLanguage.tamil:
        return 'menu.language.tamil';
    }
  }

  void _showAppearanceSelector(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(context);

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Light'),
                  selected: !isDarkMode,
                  trailing: !isDarkMode ? const Icon(Icons.check) : null,
                  onTap: () {
                    if (isDarkMode) {
                      context.read<SettingsBloc>().add(const ToggleDarkMode());
                    }
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  title: const Text('Dark'),
                  selected: isDarkMode,
                  trailing: isDarkMode ? const Icon(Icons.check) : null,
                  onTap: () {
                    if (!isDarkMode) {
                      context.read<SettingsBloc>().add(const ToggleDarkMode());
                    }
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageSelector(BuildContext context, AppLanguage current) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('menu.language'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...AppLanguage.values.map(
                  (lang) => ListTile(
                    title: Text(l10n.t(_languageKey(lang))),
                    selected: lang == current,
                    trailing: lang == current ? const Icon(Icons.check) : null,
                    onTap: () {
                      context.read<SettingsBloc>().add(
                        SetLanguage(language: lang),
                      );
                      Navigator.pop(sheetContext);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
