import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/alerts/alert_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
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
}

class NERVApp extends StatelessWidget {
  const NERVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
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
            child: ClerkAuth(
              config: ClerkAuthConfig(
                publishableKey: ApiConstants.clerkPublishableKey,
              ),
              child: ClerkErrorListener(
                child: ClerkAuthBuilder(
                  signedInBuilder: (context, authState) =>
                      _buildSignedInApp(settingsState),
                  signedOutBuilder: (context, authState) =>
                      _buildSignedOutApp(settingsState),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignedInApp(SettingsState settingsState) {
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

  Widget _buildSignedOutApp(SettingsState settingsState) {
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
      home: const Scaffold(
        body: SafeArea(child: ClerkAuthentication()),
      ),
    );
  }
}