import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../blocs/settings/settings_bloc.dart';
import '../../widgets/nerv/nerv_styles.dart';
import '../../widgets/nerv/deck_header.dart';
import '../../widgets/nerv/island_mark.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: DeckHeader(
                    title: 'Settings',
                    eyebrowText: 'SRI LANKA · CONFIG',
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildAccessibilitySection(context, state),
                ),
                SliverToBoxAdapter(
                  child: _buildNotificationSection(context, state),
                ),
                SliverToBoxAdapter(child: _buildAboutSection(context)),
                SliverToBoxAdapter(child: _buildFooter(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccessibilitySection(BuildContext context, SettingsState state) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(l10n.t('settings.accessibility')),
          const SizedBox(height: 3),
          Text(
            l10n.t('settings.displayText'),
            style: context.nerv.dataLabel,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: l10n.t('settings.darkMode'),
                  trailing: Switch(
                    value: state.isDarkMode,
                    onChanged: (_) {
                      context.read<SettingsBloc>().add(const ToggleDarkMode());
                    },
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                ),
                _divider(context),
                _buildSettingsTile(
                  context,
                  icon: Icons.text_fields,
                  title: l10n.t('settings.textSize'),
                  subtitle: 'Font Size: ${state.textSizeScale.label}',
                  onTap: () => _showTextSizeSelector(context, state),
                ),
                _divider(context),
                _buildSettingsTile(
                  context,
                  icon: Icons.format_size,
                  title: l10n.t('settings.fontWeight'),
                  subtitle:
                      'Font Weight: ${_getFontWeightLabel(state.fontWeightScale)}',
                  onTap: () => _showFontWeightSelector(context, state),
                ),
                _divider(context),
                _buildSettingsTile(
                  context,
                  icon: Icons.palette_outlined,
                  title: l10n.t('settings.colourVision'),
                  subtitle: 'Colour Vision: ${state.colourVisionMode.label}',
                  onTap: () => _showColourVisionSelector(context, state),
                ),
                _divider(context),
                _buildSettingsTile(
                  context,
                  icon: Icons.contrast,
                  title: l10n.t('settings.contrast'),
                  subtitle: 'Contrast: ${state.contrastMode.label}',
                  onTap: () => _showContrastSelector(context, state),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(BuildContext context, SettingsState state) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(l10n.t('settings.notifications')),
          const SizedBox(height: 3),
          Text(
            l10n.t('settings.alertSettings'),
            style: context.nerv.dataLabel,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
            ),
            child: Column(
              children: [
                _buildNotificationToggle(
                  context,
                  title: l10n.t('settings.criticalAlerts'),
                  subtitle: 'Emergency Warnings',
                  value: true,
                  onChanged: (_) {},
                ),
                _divider(context),
                _buildNotificationToggle(
                  context,
                  title: l10n.t('settings.floodAlerts'),
                  subtitle: 'River & Urban Flooding',
                  value: true,
                  onChanged: (_) {},
                ),
                _divider(context),
                _buildNotificationToggle(
                  context,
                  title: l10n.t('settings.landslideAlerts'),
                  subtitle: 'Slope Failure Warnings',
                  value: true,
                  onChanged: (_) {},
                ),
                _divider(context),
                _buildNotificationToggle(
                  context,
                  title: l10n.t('settings.cycloneAdvisories'),
                  subtitle: 'Tropical Storm Warnings',
                  value: true,
                  onChanged: (_) {},
                ),
                _divider(context),
                _buildNotificationToggle(
                  context,
                  title: l10n.t('settings.lightningAlerts'),
                  subtitle: 'High Lightning Activity',
                  value: true,
                  onChanged: (_) {},
                ),
                _divider(context),
                _buildNotificationToggle(
                  context,
                  title: l10n.t('settings.coastalWarnings'),
                  subtitle: 'High Waves & Storm Surge',
                  value: true,
                  onChanged: (_) {},
                ),
                _divider(context),
                _buildNotificationToggle(
                  context,
                  title: l10n.t('settings.tsunamiBulletins'),
                  subtitle: 'Ocean Seismic Warnings',
                  value: true,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(l10n.t('settings.about')),
          const SizedBox(height: 3),
          Text(
            l10n.t('settings.appInformation'),
            style: context.nerv.dataLabel,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.help_outline,
                  title: l10n.t('settings.aboutNerv'),
                  onTap: () => _showAboutDialog(context),
                ),
                _divider(context),
                _buildSettingsTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.t('settings.privacyPolicy'),
                  onTap: () {},
                ),
                _divider(context),
                _buildSettingsTile(
                  context,
                  icon: Icons.description_outlined,
                  title: l10n.t('settings.termsOfService'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nerv = context.nerv;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IslandMark(
                size: 12,
                color: SeverityLevel.calm.color,
              ),
              const SizedBox(width: 8),
              Text(
                'NERV — SRI LANKA',
                style: TextStyle(
                  color: nerv.onSurface.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t('settings.version'),
            style: nerv.dataLabel.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('settings.weatherOpenMeteo'),
            style: nerv.dataLabel.copyWith(
              color: nerv.onSurface.withValues(alpha: 0.35),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.t('settings.alertsDmc'),
            style: nerv.dataLabel.copyWith(
              color: nerv.onSurface.withValues(alpha: 0.35),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: nerv.hairline),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      height: 1,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final nerv = context.nerv;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: theme.colorScheme.primary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: nerv.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: nerv.dataLabel.copyWith(fontSize: 11),
                      ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: nerv.onSurface.withValues(alpha: 0.3),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final nerv = context.nerv;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: nerv.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: nerv.dataLabel.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  String _getFontWeightLabel(FontWeightScale scale) {
    switch (scale) {
      case FontWeightScale.normal:
        return 'Normal';
      case FontWeightScale.medium:
        return 'Medium';
      case FontWeightScale.bold:
        return 'Bold';
    }
  }

  void _showTextSizeSelector(BuildContext context, SettingsState state) {
    _showSelectorSheet(
      context,
      title: 'TEXT SIZE',
      options: TextSizeScale.values,
      currentValue: state.textSizeScale,
      labelBuilder: (scale) => scale.label,
      onSelected: (scale) {
        context.read<SettingsBloc>().add(SetTextSizeScale(scale: scale));
      },
    );
  }

  void _showFontWeightSelector(BuildContext context, SettingsState state) {
    _showSelectorSheet(
      context,
      title: 'FONT WEIGHT',
      options: FontWeightScale.values,
      currentValue: state.fontWeightScale,
      labelBuilder: (scale) => _getFontWeightLabel(scale),
      onSelected: (scale) {
        context.read<SettingsBloc>().add(SetFontWeightScale(scale: scale));
      },
    );
  }

  void _showColourVisionSelector(BuildContext context, SettingsState state) {
    _showSelectorSheet(
      context,
      title: 'COLOUR VISION',
      options: ColourVisionMode.values,
      currentValue: state.colourVisionMode,
      labelBuilder: (mode) => mode.label,
      onSelected: (mode) {
        context.read<SettingsBloc>().add(SetColourVisionMode(mode: mode));
      },
    );
  }

  void _showContrastSelector(BuildContext context, SettingsState state) {
    _showSelectorSheet(
      context,
      title: 'CONTRAST',
      options: ContrastMode.values,
      currentValue: state.contrastMode,
      labelBuilder: (mode) => mode.label,
      onSelected: (mode) {
        context.read<SettingsBloc>().add(SetContrastMode(mode: mode));
      },
    );
  }

  void _showSelectorSheet<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required T currentValue,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
  }) {
    final theme = Theme.of(context);
    final nerv = context.nerv;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Eyebrow(title, color: nerv.onSurface.withValues(alpha: 0.6)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final isSelected = option == currentValue;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onSelected(option);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              border: index == options.length - 1
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                        color: nerv.onSurface
                                            .withValues(alpha: 0.06),
                                        width: 0.5,
                                      ),
                                    ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    labelBuilder(option),
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      fontSize: 14,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : nerv.onSurface.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final nerv = context.nerv;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          title: Row(
            children: [
              IslandMark(size: 16, color: SeverityLevel.calm.color),
              const SizedBox(width: 10),
              Eyebrow('NERV — SRI LANKA'),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version 1.0.0', style: nerv.dataLabel),
              const SizedBox(height: 12),
              Text(
                'NERV Disaster Prevention App delivers real-time alerts for '
                'earthquakes, tsunamis, volcanic eruptions, and special '
                'warnings. Weather and hazard information is optimized based '
                'on your current location or registered locations.',
                style: nerv.body.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Weather data provided by WeatherAPI.com.',
                style: nerv.dataLabel.copyWith(fontSize: 10),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}
