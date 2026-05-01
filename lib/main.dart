import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/settings/settings_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initDependencies();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0C10),
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
    return BlocProvider.value(
      value: getIt<SettingsBloc>()..add(const LoadSettings()),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
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
            themeMode: settingsState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
