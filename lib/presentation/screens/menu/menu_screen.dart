import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../widgets/nerv/nerv_styles.dart';
import '../../widgets/nerv/deck_header.dart';
import '../../widgets/nerv/island_mark.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DeckHeader(
                  title: l10n.t('menu.title'),
                  eyebrowText: 'SRI LANKA · SYSTEM',
                ),
                _buildSeverityStrip(context),
                _buildSavedRegions(context),
                _buildAccountSection(context),
                _buildSettingsSection(context, state),
                _buildAboutSection(context),
                _buildFooter(context),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The severity ladder as a 2px strip — replaces the old rainbow
  /// gradient with the design system's own ordered severity colours.
  Widget _buildSeverityStrip(BuildContext context) {
    final ladder = NervStyles.ladder;
    return Row(
      children: [
        for (final level in ladder)
          Expanded(
            child: Container(height: 2, color: level.color),
          ),
      ],
    );
  }

  Widget _buildSavedRegions(BuildContext context) {
    final nerv = context.nerv;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: nerv.onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Eyebrow('SAVED REGIONS'),
              const Spacer(),
              Text(
                '0 / 3',
                style: nerv.numeralSmall(size: 13).copyWith(
                  color: nerv.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'None',
                style: TextStyle(
                  color: nerv.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'You can add up to 3 regions',
                style: nerv.dataLabel.copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ADD REGION',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'ACCOUNT'),
        _buildMenuItem(
          context,
          'Profile',
          onTap: () => context.push('/profile'),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    SettingsState state,
  ) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, l10n.t('settings.title').toUpperCase()),
        _buildMenuItem(
          context,
          l10n.t('menu.language'),
          trailing: l10n.t(_languageKey(state.language)),
          onTap: () => _showLanguageSelector(context, state.language),
        ),
        _buildMenuItem(
          context,
          'Appearance',
          trailing: state.isDarkMode ? 'Dark' : 'Light',
          onTap: () => _showAppearanceSelector(context, state.isDarkMode),
        ),
        _buildNotificationsToggle(context, state),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildSectionTitle(context, l10n.t('menu.about').toUpperCase()),
        _buildMenuItem(
          context,
          l10n.t('menu.version'),
          trailing: '1.0.0',
          showChevron: false,
        ),
        _buildMenuItem(
          context,
          'Contact Us',
          onTap: () => context.push('/contact-us'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final nerv = context.nerv;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Eyebrow(title, color: nerv.onSurface.withValues(alpha: 0.45)),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title, {
    String? trailing,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    final nerv = context.nerv;

    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: nerv.onSurface.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: nerv.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: nerv.dataLabel.copyWith(fontSize: 12),
              ),
            if (showChevron) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: nerv.onSurface.withValues(alpha: 0.3),
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsToggle(
    BuildContext context,
    SettingsState state,
  ) {
    final nerv = context.nerv;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: nerv.onSurface.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.t('settings.notifications'),
                  style: TextStyle(
                    color: nerv.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.notificationsEnabled ? 'On' : 'Off',
                  style: nerv.dataLabel.copyWith(
                    fontSize: 11,
                    color: state.notificationsEnabled
                        ? theme.colorScheme.primary
                        : nerv.onSurface.withValues(alpha: 0.4),
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

  Widget _buildFooter(BuildContext context) {
    final nerv = context.nerv;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IslandMark(
                size: 12,
                color: nerv.onSurface.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 8),
              Text(
                'Theo DC_',
                style: nerv.dataLabel.copyWith(
                  color: nerv.onSurface.withValues(alpha: 0.35),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('settings.alertsDmc'),
            style: nerv.dataLabel.copyWith(
              color: nerv.onSurface.withValues(alpha: 0.25),
              fontSize: 10,
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
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('APPEARANCE'),
                const SizedBox(height: 12),
                _selectorRow(sheetContext, 'Light', !isDarkMode, () {
                  if (isDarkMode) {
                    context.read<SettingsBloc>().add(const ToggleDarkMode());
                  }
                  Navigator.pop(sheetContext);
                }),
                _selectorRow(sheetContext, 'Dark', isDarkMode, () {
                  if (!isDarkMode) {
                    context.read<SettingsBloc>().add(const ToggleDarkMode());
                  }
                  Navigator.pop(sheetContext);
                }),
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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(l10n.t('menu.language').toUpperCase()),
                const SizedBox(height: 12),
                ...AppLanguage.values.map(
                  (lang) => _selectorRow(
                    sheetContext,
                    l10n.t(_languageKey(lang)),
                    lang == current,
                    () {
                      context.read<SettingsBloc>().add(SetLanguage(language: lang));
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

  Widget _selectorRow(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final nerv = context.nerv;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: nerv.onSurface.withValues(alpha: 0.06),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                  color: selected
                      ? theme.colorScheme.primary
                      : nerv.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check, color: theme.colorScheme.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
