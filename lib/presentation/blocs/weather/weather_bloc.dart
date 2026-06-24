import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants/weather_codes.dart';
import '../../../core/notifications/local_notification_service.dart';
import '../../../core/utils/weather_alert_deriver.dart';
import '../../../domain/entities/weather_data.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/repositories/weather_repository.dart';

part 'weather_event.dart';
part 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherRepository _weatherRepository;
  final LocalNotificationService _notificationService;

  /// Prevents rapid re-requests when switching screens with GPS off.
  static DateTime? _lastGpsAttempt;
  static const Duration _gpsCooldown = Duration(seconds: 30);

  WeatherBloc({
    required WeatherRepository weatherRepository,
    required LocalNotificationService notificationService,
  }) : _weatherRepository = weatherRepository,
       _notificationService = notificationService,
       super(WeatherInitial()) {
    on<LoadWeather>(_onLoadWeather);
    on<_FetchWeatherInBackground>(_onFetchWeatherInBackground);
    on<_GpsFailed>(_onGpsFailed);
    on<RefreshWeather>(_onRefreshWeather);
    on<SearchLocations>(_onSearchLocations);
    on<SelectLocation>(_onSelectLocation);
  }

  Future<void> _onLoadWeather(
    LoadWeather event,
    Emitter<WeatherState> emit,
  ) async {
    // Fixed location provided (e.g. Island-wide) — fetch fresh, no cache, no GPS
    if (event.location != null && !event.useGps) {
      emit(WeatherLoading());
      add(_FetchWeatherInBackground(location: event.location!, forceRefresh: true));
      return;
    }

    // GPS / Local mode
    emit(WeatherLoading());
    final cachedLocation = _weatherRepository.getCachedLocation();
    if (cachedLocation != null) {
      add(_FetchWeatherInBackground(location: cachedLocation, forceRefresh: true));
    }

    // Cooldown: skip GPS if we tried within the last 30s to avoid
    // spamming the permission dialog on rapid tab switches.
    final now = DateTime.now();
    if (_lastGpsAttempt != null &&
        now.difference(_lastGpsAttempt!) < _gpsCooldown) {
      if (cachedLocation == null) {
        add(const _GpsFailed());
      }
      return;
    }
    _lastGpsAttempt = now;

    // Resolve real GPS in background and update
    _weatherRepository.getLocationFromGps().then((gpsLocation) {
      if (gpsLocation != null) {
        _weatherRepository.cacheLocation(gpsLocation);
        add(_FetchWeatherInBackground(location: gpsLocation, forceRefresh: true));
      } else if (cachedLocation == null) {
        add(const _GpsFailed());
      }
    });
  }

  Future<void> _onFetchWeatherInBackground(
    _FetchWeatherInBackground event,
    Emitter<WeatherState> emit,
  ) async {
    try {
      Location location = event.location;

      if (location.isGps && location.latitude == 0 && location.longitude == 0) {
        final gpsLocation = await _weatherRepository.getLocationFromGps();
        if (gpsLocation != null) {
          location = gpsLocation;
          await _weatherRepository.cacheLocation(gpsLocation);
        }
      }

      final weatherData = await _weatherRepository.getWeatherData(
        latitude: location.latitude,
        longitude: location.longitude,
        forceRefresh: event.forceRefresh,
      );

      emit(
        WeatherLoaded(
          weatherData: weatherData,
          location: location,
          isStaleCache: false,
        ),
      );

      // After successfully emitting the new forecast, surface any
      // newly-discovered upcoming Critical/Emergency/Warning timeline
      // events as OS notifications (when notifications are enabled).
      _notifyTimelineEvents(weatherData, location);
    } catch (e) {
      final currentState = state;
      if (currentState is WeatherLoaded) {
        emit(
          WeatherLoaded(
            weatherData: currentState.weatherData,
            location: currentState.location,
            isStaleCache: true,
          ),
        );
      }
    }
  }

  Future<void> _onGpsFailed(
    _GpsFailed event,
    Emitter<WeatherState> emit,
  ) async {
    emit(
      WeatherError(
        message: 'Could not determine your location. '
            'Enable location services or search for a location.',
      ),
    );
  }

  Future<void> _onRefreshWeather(
    RefreshWeather event,
    Emitter<WeatherState> emit,
  ) async {
    final currentState = state;
    if (currentState is WeatherLoaded && currentState.location != null) {
      try {
        final weatherData = await _weatherRepository.getWeatherData(
          latitude: currentState.location!.latitude,
          longitude: currentState.location!.longitude,
          forceRefresh: true,
        );

        emit(
          WeatherLoaded(
            weatherData: weatherData,
            location: currentState.location,
            isStaleCache: false,
          ),
        );

        // Same as above: surface newly-discovered upcoming severe
        // timeline events as OS notifications after a manual refresh.
        _notifyTimelineEvents(weatherData, currentState.location);
      } catch (e) {
        emit(
          WeatherLoaded(
            weatherData: currentState.weatherData,
            location: currentState.location,
            isStaleCache: true,
          ),
        );
      }
    }
  }

  Future<void> _onSearchLocations(
    SearchLocations event,
    Emitter<WeatherState> emit,
  ) async {
    if (event.query.length < 2) {
      if (state is WeatherLoaded) {
        emit(
          (state as WeatherLoaded).copyWith(
            searchResults: [],
            isSearching: false,
          ),
        );
      }
      return;
    }

    if (state is WeatherLoaded) {
      emit((state as WeatherLoaded).copyWith(isSearching: true));
    }

    try {
      final locations = await _weatherRepository.searchLocations(event.query);
      final currentState = state;

      if (currentState is WeatherLoaded) {
        emit(
          currentState.copyWith(searchResults: locations, isSearching: false),
        );
      }
    } catch (e) {
      if (state is WeatherLoaded) {
        emit((state as WeatherLoaded).copyWith(isSearching: false));
      }
    }
  }

  Future<void> _onSelectLocation(
    SelectLocation event,
    Emitter<WeatherState> emit,
  ) async {
    add(LoadWeather(location: event.location, forceRefresh: true));
  }

  /// Derive timeline events from the freshly-loaded [weatherData] and
  /// forward them to the notification service. Failures are swallowed
  /// so a notification hiccup never breaks the bloc. [location] may
  /// be null on manual refresh paths; in that case we fall back to
  /// the bloc's current state location.
  void _notifyTimelineEvents(WeatherData weatherData, Location? location) {
    final effectiveLocation = location ?? _currentLocationOrNull();
    if (effectiveLocation == null) return;
    try {
      final events = WeatherAlertDeriver.deriveTimelineEvents(
        weatherData,
        districtName: effectiveLocation.name,
        realLatitude: effectiveLocation.latitude,
        realLongitude: effectiveLocation.longitude,
      );
      // Fire-and-forget; the service itself is idempotent and dedups.
      _notificationService.notifyIfNewTimelineEvent(events);

      // Also fire a single digest notification so users see a real
      // device toast even when nothing severe is on the timeline.
      _notifyCurrentConditionsDigest(
        weatherData,
        effectiveLocation,
        events,
      );
    } catch (_) {
      // Intentionally ignored — notifications are best-effort.
    }
  }

  /// Build a digest notification payload from the fresh weather and
  /// derived alerts, then hand it to the service.
  void _notifyCurrentConditionsDigest(
    WeatherData weatherData,
    Location location,
    List<dynamic> events,
  ) {
    try {
      final current = weatherData.current;
      final conditionsLabel = WeatherCodeMapping.getDescription(
        current.weatherCode,
        isDay: current.isDay,
      );
      final nonCalm = events
          .where((e) => (e.severity.name as String) != 'calm')
          .toList();
      final headline = nonCalm.isEmpty
          ? null
          : (nonCalm.first.title as String?);

      _notificationService.notifyCurrentConditionsDigest(
        locationName: location.name,
        temperatureC: current.temperature,
        conditionsLabel: conditionsLabel,
        nonCalmAlertCount: nonCalm.length,
        topAlertHeadline: headline,
      );
    } catch (_) {
      // Best-effort.
    }
  }

  Location? _currentLocationOrNull() {
    final s = state;
    if (s is WeatherLoaded) return s.location;
    return null;
  }
}
