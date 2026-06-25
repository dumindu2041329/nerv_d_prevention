import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/local/hive/hive_service.dart';
import '../../core/di/injection.dart';
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
import '../../presentation/screens/location_gate/location_gate_screen.dart';
import '../../presentation/widgets/main_scaffold.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  /// In-memory cache so we skip the Hive read on every redirect after the
  /// gate has been passed once during this session.
  static bool _locationGatePassed = false;

  /// Called by [LocationGateScreen] after the user acknowledges the gate
  /// so subsequent redirects in this session skip the Hive lookup.
  static void markGatePassed() => _locationGatePassed = true;

  static Future<bool> _checkGatePassed() async {
    if (_locationGatePassed) return true;
    final hive = getIt<HiveService>();
    final acknowledged =
        await hive.getSetting<bool>('location_gate_acknowledged') ?? false;
    if (acknowledged) _locationGatePassed = true;
    return _locationGatePassed;
  }

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) async {
      final location = state.matchedLocation;
      if (location == '/location-gate') return null;
      if (await _checkGatePassed()) return null;
      return '/location-gate';
    },
    routes: [
      GoRoute(
        path: '/location-gate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LocationGateScreen(),
      ),
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
