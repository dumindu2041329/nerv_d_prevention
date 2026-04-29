import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_constants.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  static const _routes = ['/home', '/map', '/timeline', '/settings'];

  static const _navItems = [
    _NavItem(labelJa: 'ホーム', labelEn: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home),
    _NavItem(labelJa: '地図', labelEn: 'Map', icon: Icons.map_outlined, selectedIcon: Icons.map),
    _NavItem(labelJa: 'タイムライン', labelEn: 'Timeline', icon: Icons.timeline_outlined, selectedIcon: Icons.timeline),
    _NavItem(labelJa: '設定', labelEn: 'Settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings),
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

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.dividerTheme.color ?? Colors.grey,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onItemTapped,
          height: AppConstants.bottomNavHeight + MediaQuery.of(context).padding.bottom,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: _navItems.map((item) {
            final isSelected = _currentIndex == _navItems.indexOf(item);
            return NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: '${item.labelJa}\n${item.labelEn}',
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final String labelJa;
  final String labelEn;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem({
    required this.labelJa,
    required this.labelEn,
    required this.icon,
    required this.selectedIcon,
  });
}
