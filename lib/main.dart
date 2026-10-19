import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/alerts/alert_bloc.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() async {
  // runZonedGuarded catches every uncaught async error in the app — without
  // this, any stray future error would surface as a red stack trace in
  // debug builds and a silent crash in release.
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Catch synchronous Flutter framework errors (build/layout/paint).
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      if (details.stack != null) debugPrint('${details.stack}');
    };

    // Catch errors that escape the Flutter framework (platform channels,
    // async callbacks, native interop, etc.).
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PlatformDispatcher error: $error\n$stack');
      return true; // mark as handled so the engine doesn't kill the isolate
    };

    await dotenv.load(fileName: '.env');
    _assertNoSecretsInEnv();
    await initDependencies();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF000000),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    runApp(const NERVApp());
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

/// Environment keys that must NEVER be bundled in the client `.env` asset.
/// Provider keys (WeatherAPI / MapTiler / OWM) and the service-role key belong
/// in Supabase Secrets and are only read server-side by the Edge Functions.
const List<String> _forbiddenEnvKeys = <String>[
  'WEATHERAPI_KEY',
  'MAPTILER_API_KEY',
  'OWM_API_KEY',
  'SUPABASE_SERVICE_ROLE_KEY',
  'SERVICE_ROLE_KEY',
  'SUPABASE_SECRET_KEY',
];

/// Fails fast in release builds if a secret key has been added to `.env`.
/// The `.env` file ships as a Flutter asset and is trivially extractable from
/// an APK/IPA, so only public config (SUPABASE_URL + anon key) may live there.
void _assertNoSecretsInEnv() {
  if (!kReleaseMode) return;
  final leaked = dotenv.env.keys
      .where((k) => _forbiddenEnvKeys.contains(k.toUpperCase()))
      .toList();
  if (leaked.isNotEmpty) {
    throw StateError(
      'Release build must not bundle secret keys in .env: '
      '${leaked.join(', ')}. Move them to Supabase Secrets '
      '(supabase secrets set).',
    );
  }
}

class NERVApp extends StatelessWidget {
  const NERVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // App-wide auth session (Supabase email/password). Created in DI so
        // the restored session is already being observed.
        BlocProvider.value(value: getIt<AuthBloc>()),
        BlocProvider.value(
          value: getIt<SettingsBloc>()..add(const LoadSettings()),
        ),
        BlocProvider(
          create: (_) => getIt<AlertBloc>()..add(const LoadAlerts()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return AppLocalizationScope(
            localizations: AppLocalizations(settingsState.language),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                return _buildApp(settingsState, authState);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildApp(SettingsState settingsState, AuthState authState) {
    if (authState is AuthAuthenticated) {
      return _buildRouterApp(settingsState);
    }
    if (authState is AuthStatusLoading) {
      return _buildShellApp(
        settingsState,
        home: const _SplashScreen(),
      );
    }
    // AuthUnauthenticated
    return _buildShellApp(
      settingsState,
      home: const LoginScreen(),
    );
  }

  Widget _buildRouterApp(SettingsState settingsState) {
    return MaterialApp.router(
      title: 'NERV Disaster Prevention',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(
        textSizeScale: settingsState.textSizeScale,
        fontWeightScale: settingsState.fontWeightScale,
      ),
      darkTheme: AppTheme.darkTheme(
        visionMode: settingsState.colourVisionMode,
        contrast: settingsState.contrastMode,
        textSizeScale: settingsState.textSizeScale,
        fontWeightScale: settingsState.fontWeightScale,
      ),
      themeMode:
          settingsState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }

  /// A plain [MaterialApp] used for the signed-out / splash states, which
  /// live outside the authenticated router shell.
  Widget _buildShellApp(SettingsState settingsState, {required Widget home}) {
    return MaterialApp(
      title: 'NERV Disaster Prevention',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(
        textSizeScale: settingsState.textSizeScale,
        fontWeightScale: settingsState.fontWeightScale,
      ),
      darkTheme: AppTheme.darkTheme(
        visionMode: settingsState.colourVisionMode,
        contrast: settingsState.contrastMode,
        textSizeScale: settingsState.textSizeScale,
        fontWeightScale: settingsState.fontWeightScale,
      ),
      themeMode:
          settingsState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: home,
    );
  }
}

/// Minimal splash shown while the persisted auth session is being resolved.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}