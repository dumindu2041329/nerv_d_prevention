import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';

/// Console rail — the bottom navigation.
///
/// Five fixed monitoring feeds. The active feed is flagged with a 2px
/// accent tick on top (same language as the severity state line), a
/// filled icon, and a tracked-uppercase label; inactive feeds sit quiet
/// in tertiary grey.
class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  static const _routes = ['/home', '/timeline', '/map', '/weather', '/menu'];

  static const _navItemsBase = [
    _NavItemKey('nav.home', icon: Icons.home_outlined, selectedIcon: Icons.home),
    _NavItemKey(
      'nav.timeline',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
    ),
    _NavItemKey('nav.map', icon: Icons.cloud_outlined, selectedIcon: Icons.cloud),
    _NavItemKey(
      'nav.weather',
      icon: Icons.wb_sunny_outlined,
      selectedIcon: Icons.wb_sunny,
    ),
    _NavItemKey('nav.menu', icon: Icons.menu, selectedIcon: Icons.menu),
  ];

  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
      context.go(_routes[index]);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    final index = _routes.indexOf(location);
    if (index != -1 && index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final accent = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: theme.dividerTheme.color ?? Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppConstants.bottomNavHeight,
            child: Row(
              children: _navItemsBase.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final selected = index == _currentIndex;

                return Expanded(
                  child: _NavCell(
                    item: item,
                    label: l10n.t(item.labelKey),
                    selected: selected,
                    accent: accent,
                    onSurface: onSurface,
                    onTap: () => _onItemTapped(index),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  final _NavItemKey item;
  final String label;
  final bool selected;
  final Color accent;
  final Color onSurface;
  final VoidCallback onTap;

  const _NavCell({
    required this.item,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onSurface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final idle = onSurface.withValues(alpha: 0.45);

    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Active tick
          Container(
            height: 2,
            width: 20,
            color: selected ? accent : Colors.transparent,
          ),
          const SizedBox(height: 6),
          Icon(
            selected ? item.selectedIcon : item.icon,
            size: 22,
            color: selected ? accent : idle,
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: selected ? accent : idle,
              fontSize: 9,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 1.0,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NavItemKey {
  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItemKey(
    this.labelKey, {
    required this.icon,
    required this.selectedIcon,
  });
}
