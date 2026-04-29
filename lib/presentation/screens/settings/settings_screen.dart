import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../core/di/injection.dart';
import '../../blocs/settings/settings_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context),
                ),
                SliverToBoxAdapter(
                  child: _buildAccessibilitySection(context, state),
                ),
                SliverToBoxAdapter(
                  child: _buildNotificationSection(context, state),
                ),
                SliverToBoxAdapter(
                  child: _buildAboutSection(context),
                ),
                SliverToBoxAdapter(
                  child: _buildFooter(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space5,
        AppSpacing.space4,
        AppSpacing.space5,
        AppSpacing.space2,
      ),
      child: Row(
        children: [
          Text(
            '設定',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            'Settings',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilitySection(BuildContext context, SettingsState state) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            title: 'アクセシビリティ',
            subtitle: 'Accessibility',
            icon: Icons.accessibility_new,
          ),
          const SizedBox(height: AppSpacing.space3),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: theme.dividerTheme.color ?? Colors.grey,
              ),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.dark_mode,
                  title: 'ダークモード',
                  subtitle: 'Dark Mode',
                  trailing: Switch(
                    value: state.isDarkMode,
                    onChanged: (_) {
                      context.read<SettingsBloc>().add(const ToggleDarkMode());
                    },
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.dividerTheme.color,
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.text_fields,
                  title: '文字サイズ',
                  subtitle: 'Font Size: ${state.textSizeScale.label}',
                  onTap: () => _showTextSizeSelector(context, state),
                ),
                Divider(
                  height: 1,
                  color: theme.dividerTheme.color,
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.format_size,
                  title: '文字の太さ',
                  subtitle: 'Font Weight: ${_getFontWeightLabel(state.fontWeightScale)}',
                  onTap: () => _showFontWeightSelector(context, state),
                ),
                Divider(
                  height: 1,
                  color: theme.dividerTheme.color,
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.palette_outlined,
                  title: '色覚特性',
                  subtitle: 'Colour Vision: ${state.colourVisionMode.label}',
                  onTap: () => _showColourVisionSelector(context, state),
                ),
                Divider(
                  height: 1,
                  color: theme.dividerTheme.color,
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.contrast,
                  title: 'コントラスト',
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            title: '通知設定',
            subtitle: 'Notifications',
            icon: Icons.notifications_outlined,
          ),
          const SizedBox(height: AppSpacing.space3),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: theme.dividerTheme.color ?? Colors.grey,
              ),
            ),
            child: Column(
              children: [
                _buildNotificationToggle(
                  context,
                  title: '重大アラート',
                  subtitle: 'Critical Alerts',
                  value: true,
                  onChanged: (_) {},
                ),
                Divider(
                  height: 1,
                  color: theme.dividerTheme.color,
                ),
                _buildNotificationToggle(
                  context,
                  title: '地震的通知',
                  subtitle: 'Earthquake Alerts',
                  value: true,
                  onChanged: (_) {},
                ),
                Divider(
                  height: 1,
                  color: theme.dividerTheme.color,
                ),
                _buildNotificationToggle(
                  context,
                  title: ' tsunami 注意報',
                  subtitle: 'Tsunami Alerts',
                  value: true,
                  onChanged: (_) {},
                ),
                Divider(
                  height: 1,
                  color: theme.dividerTheme.color,
                ),
                _buildNotificationToggle(
                  context,
                  title: '気象警報',
                  subtitle: 'Weather Warnings',
                  value: true,
                  onChanged: (_) {},
                ),
                Divider(
                  height: 1,
                  color: theme.dividerTheme.color,
                ),
                _buildNotificationToggle(
                  context,
                  title: 'Jアラート',
                  subtitle: 'J-Alert',
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

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            title: 'アプリについて',
            subtitle: 'About',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: AppSpacing.space3),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: theme.dividerTheme.color ?? Colors.grey,
              ),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'NERVについて',
                  subtitle: 'About NERV',
                  onTap: () => _showAboutDialog(context),
                ),
                Divider(
                  height: 1,
                  color: theme.dividerTheme.color,
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'プライバシー policy',
                  subtitle: 'Privacy Policy',
                  onTap: () {},
                ),
                Divider(
                  height: 1,
                  color: theme.dividerTheme.color,
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.description_outlined,
                  title: '利用規約',
                  subtitle: 'Terms of Service',
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space5,
        vertical: AppSpacing.space4,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SeverityLevel.calm.color,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                'NERV',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Version 1.0.0',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Weather data: Open-Meteo.com (CC BY 4.0)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.space3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
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
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.space2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
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
      title: '文字サイズ',
      titleEn: 'Font Size',
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
      title: '文字の太さ',
      titleEn: 'Font Weight',
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
      title: '色覚特性',
      titleEn: 'Colour Vision',
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
      title: 'コントラスト',
      titleEn: 'Contrast',
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
    required String titleEn,
    required List<T> options,
    required T currentValue,
    required String Function(T) labelBuilder,
    required ValueChanged<T> onSelected,
  }) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        titleEn,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              ...options.map((option) {
                final isSelected = option == currentValue;
                return Material(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: InkWell(
                    onTap: () {
                      onSelected(option);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.space4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              labelBuilder(option),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          title: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SeverityLevel.calm.color,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Text(
                'NERV',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'バージョン / Version 1.0.0',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'NERV防災アプリは、地震・ tsunami ・噴火・特別警報の速報や洪水や土砂災害といった防災気象情報を、利用者の現在地や登録地点に基づき最適化して配信するスマートフォン用アプリです。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'Weather data provided by Open-Meteo under CC BY 4.0 licence.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '閉じる / Close',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}
