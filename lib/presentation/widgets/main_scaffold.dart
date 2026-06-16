import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';

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
    _NavItemKey(
      'nav.home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _NavItemKey(
      'nav.timeline',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
    ),
    _NavItemKey(
      'nav.map',
      icon: Icons.cloud_outlined,
      selectedIcon: Icons.cloud,
    ),
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

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: theme.dividerTheme.color ?? const Color(0xFF2A2A2A),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onItemTapped,
          height:
              AppConstants.bottomNavHeight +
              MediaQuery.of(context).padding.bottom,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: _navItemsBase.map((item) {
            return NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: l10n.t(item.labelKey),
            );
          }).toList(),
        ),
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
