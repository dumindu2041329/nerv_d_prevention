import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/remote/alerts/sos_alert_api_client.dart';
import '../../data/remote/contact/contact_api_client.dart';
import '../../data/repositories/landslide_repository_impl.dart';
import '../../domain/repositories/landslide_repository.dart';
import '../../data/remote/weatherapi/weather_api_client.dart';
import '../../data/remote/maptiler/maptiler_geocoding_client.dart';
import '../../data/remote/supabase/supabase_service.dart';
import '../../data/repositories/alert_repository_impl.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/local/hive/hive_service.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../presentation/blocs/alerts/alert_bloc.dart';
import '../../presentation/blocs/weather/weather_bloc.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';
import '../notifications/local_notification_service.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // 1) Supabase must be initialised before any service that depends on it.
  //    We do this first so that the singleton [SupabaseService] and
  //    [SupabaseClient] are available to all subsequent registrations.
  final supabaseService = SupabaseService();
  await supabaseService.init();
  getIt.registerSingleton<SupabaseService>(supabaseService);

  // 2) Local cache (Hive) — unchanged from before the migration.
  await Hive.initFlutter();
  final hiveService = HiveService();
  await hiveService.init();
  getIt.registerSingleton<HiveService>(hiveService);

  // 3) API clients — all now route through Supabase Edge Functions.
  getIt.registerSingleton<WeatherApiClient>(WeatherApiClient());
  getIt.registerSingleton<MaptilerGeocodingClient>(MaptilerGeocodingClient());
  getIt.registerSingleton<LandslideRepository>(
    LandslideRepositoryImpl(),
  );
  getIt.registerSingleton<SosAlertApiClient>(SosAlertApiClient());
  getIt.registerSingleton<ContactApiClient>(ContactApiClient());

  // 4) Repositories — unchanged signatures; only the underlying clients
  //    now talk to Supabase.
  getIt.registerSingleton<WeatherRepository>(
    WeatherRepositoryImpl(
      client: getIt<WeatherApiClient>(),
      geocodingClient: getIt<MaptilerGeocodingClient>(),
      hiveService: getIt<HiveService>(),
    ),
  );

  getIt.registerSingleton<SettingsRepository>(
    SettingsRepositoryImpl(hiveService: getIt<HiveService>()),
  );

  getIt.registerSingleton<AlertRepository>(
    AlertRepositoryImpl(
      apiClient: getIt<SosAlertApiClient>(),
      hiveService: getIt<HiveService>(),
    ),
  );

  getIt.registerSingleton<LocalNotificationService>(
    LocalNotificationService(hiveService: getIt<HiveService>()),
  );

  getIt.registerFactory<WeatherBloc>(
    () => WeatherBloc(
      weatherRepository: getIt<WeatherRepository>(),
      notificationService: getIt<LocalNotificationService>(),
    ),
  );

  getIt.registerFactory<AlertBloc>(
    () => AlertBloc(
      repository: getIt<AlertRepository>(),
      notificationService: getIt<LocalNotificationService>(),
    ),
  );

  await getIt<LocalNotificationService>().init();

  getIt.registerSingleton<SettingsBloc>(
    SettingsBloc(
      settingsRepository: getIt<SettingsRepository>(),
      notificationService: getIt<LocalNotificationService>(),
    ),
  );
}