import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/timeline_event.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/map/map_screen.dart';
import '../../presentation/screens/timeline/timeline_screen.dart';
import '../../presentation/screens/timeline/timeline_event_detail_screen.dart';
import '../../presentation/screens/weather/weather_screen.dart';
import '../../presentation/screens/menu/menu_screen.dart';
import '../../presentation/screens/contact/contact_us_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/weather_detail/weather_detail_screen.dart';
import '../../presentation/widgets/main_scaffold.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/timeline',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TimelineScreen(),
            ),
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MapScreen(),
            ),
          ),
          GoRoute(
            path: '/weather',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WeatherScreen(),
            ),
          ),
          GoRoute(
            path: '/menu',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MenuScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/weather-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WeatherDetailScreen(),
      ),
      GoRoute(
        path: '/contact-us',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/timeline-event-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final event = state.extra as TimelineEvent;
          return TimelineEventDetailScreen(event: event);
        },
      ),
    ],
  );
}
