import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/remote/open_meteo/open_meteo_client.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/local/hive/hive_service.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../presentation/blocs/weather/weather_bloc.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  await Hive.initFlutter();

  final hiveService = HiveService();
  await hiveService.init();
  getIt.registerSingleton<HiveService>(hiveService);

  final openMeteoClient = OpenMeteoClient();
  getIt.registerSingleton<OpenMeteoClient>(openMeteoClient);

  getIt.registerSingleton<WeatherRepository>(
    WeatherRepositoryImpl(
      client: getIt<OpenMeteoClient>(),
      hiveService: getIt<HiveService>(),
    ),
  );

  getIt.registerSingleton<SettingsRepository>(
    SettingsRepositoryImpl(hiveService: getIt<HiveService>()),
  );

  getIt.registerFactory<WeatherBloc>(
    () => WeatherBloc(weatherRepository: getIt<WeatherRepository>()),
  );

  getIt.registerSingleton<SettingsBloc>(
    SettingsBloc(settingsRepository: getIt<SettingsRepository>()),
  );
}
