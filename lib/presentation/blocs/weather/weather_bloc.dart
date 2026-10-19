import 'dart:async';

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
  /// Instance-scoped (NOT static): the bloc is registered as a factory, and
  /// a static cooldown leaked across instances — a freshly created bloc was
  /// silently blocked from GPS by the previous instance's window.
  DateTime? _lastGpsAttempt;
  static const Duration _gpsCooldown = Duration(seconds: 30);

  /// Sri Lanka geographic centre (near Dambulla) — Island-wide fallback
  /// when Local mode cannot resolve GPS but the user has no cached fix.
  static const Location _islandWideFallback = Location(
    id: 'island_wide',
    name: 'Sri Lanka',
    latitude: 7.8731,
    longitude: 80.7718,
  );

  /// Monotonic id of the most recent fetch request. Results from older
  /// in-flight requests are discarded so a speculative cached-location
  /// fetch can never race (and overwrite) the fresher GPS fetch.
  int _fetchGeneration = 0;

  WeatherBloc({
    required WeatherRepository weatherRepository,
    required LocalNotificationService notificationService,
  }) : _weatherRepository = weatherRepository,
       _notificationService = notificationService,
       super(WeatherInitial()) {
    on<LoadWeather>(_onLoadWeather);
    on<_FetchWeatherInBackground>(_onFetchWeatherInBackground);
    on<RefreshWeather>(_onRefreshWeather);
    on<SearchLocations>(_onSearchLocations);
    on<SelectLocation>(_onSelectLocation);
  }

  Future<void> _onLoadWeather(
    LoadWeather event,
    Emitter<WeatherState> emit,
  ) async {
    // Fixed location provided (e.g. Island-wide). Use the TTL cache unless the
    // caller explicitly asked for a refresh — this is what makes an offline
    // cold-start fall back to cached weather instead of hanging in Loading.
    if (event.location != null && !event.useGps) {
      emit(WeatherLoading());
      add(_FetchWeatherInBackground(
        location: event.location!,
        forceRefresh: event.forceRefresh,
        generation: ++_fetchGeneration,
      ));
      return;
    }

    // GPS / Local mode
    emit(WeatherLoading());
    final cachedLocation = _weatherRepository.getCachedLocation();

    // Cooldown: skip GPS if we tried within the last 30s to avoid
    // spamming the permission dialog on rapid tab switches.
    final now = DateTime.now();
    if (_lastGpsAttempt != null &&
        now.difference(_lastGpsAttempt!) < _gpsCooldown) {
      // Serve the last known fix instead of firing a second provider call
      // this cycle; with no fix at all, degrade to the Island-wide frame.
      add(_FetchWeatherInBackground(
        location: cachedLocation ?? _islandWideFallback,
        forceRefresh: false,
        generation: ++_fetchGeneration,
      ));
      return;
    }
    _lastGpsAttempt = now;

    // Resolve real GPS in background and update exactly once. Guard against
    // the future throwing (location service off, plugin crash) and against
    // the bloc being closed (tab switch / back navigation) before it
    // completes. There is deliberately NO speculative cached-location fetch
    // running in parallel — it doubled every Local-mode provider call and
    // raced the GPS result.
    unawaited(_weatherRepository.getLocationFromGps().then((gpsLocation) {
      if (isClosed) return;
      if (gpsLocation != null) {
        _weatherRepository.cacheLocation(gpsLocation);
        add(_FetchWeatherInBackground(
          location: gpsLocation,
          forceRefresh: event.forceRefresh,
          generation: ++_fetchGeneration,
        ));
      } else {
        // GPS unavailable: reuse the cached fix if we have one, otherwise
        // degrade to Island-wide (NEVER lat/lon 0,0 — that is "Null
        // Island" in the Gulf of Guinea).
        add(_FetchWeatherInBackground(
          location: cachedLocation ?? _islandWideFallback,
          forceRefresh: event.forceRefresh,
          generation: ++_fetchGeneration,
        ));
      }
    }).catchError((_) {
      if (isClosed) return;
      add(_FetchWeatherInBackground(
        location: cachedLocation ?? _islandWideFallback,
        forceRefresh: event.forceRefresh,
        generation: ++_fetchGeneration,
      ));
    }));
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
        } else {
          // Legacy placeholder with no resolvable GPS: never fetch weather
          // for (0,0) and present it as the user's local conditions.
          if (isClosed) return;
          emit(
            const WeatherError(
              message: 'Location unavailable. Enable GPS or switch to '
                  'Island-wide mode.',
            ),
          );
          return;
        }
      }

      final weatherData = await _weatherRepository.getWeatherData(
        latitude: location.latitude,
        longitude: location.longitude,
        forceRefresh: event.forceRefresh,
      );

      if (isClosed) return;
      // A newer request superseded this one (e.g. cached fix replaced by a
      // fresh GPS fix mid-flight) — drop the stale result on the floor.
      if (event.generation != _fetchGeneration) return;

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
      if (isClosed) return;
      if (event.generation != _fetchGeneration) return;
      final currentState = state;
      if (currentState is WeatherLoaded) {
        emit(
          WeatherLoaded(
            weatherData: currentState.weatherData,
            location: currentState.location,
            isStaleCache: true,
          ),
        );
      } else {
        // Nothing to fall back to (cold start / first tab open). Surface a
        // real error instead of leaving the UI stuck on WeatherLoading.
        emit(
          const WeatherError(
            message:
                'Could not load weather. Check your connection and try again.',
          ),
        );
      }
    }
  }

  Future<void> _onRefreshWeather(
    RefreshWeather event,
    Emitter<WeatherState> emit,
  ) async {
    final currentState = state;
    if (currentState is WeatherLoaded && currentState.location != null) {
      final generation = ++_fetchGeneration;
      try {
        final weatherData = await _weatherRepository.getWeatherData(
          latitude: currentState.location!.latitude,
          longitude: currentState.location!.longitude,
          forceRefresh: true,
        );

        if (isClosed) return;
        if (generation != _fetchGeneration) return;
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
        if (isClosed) return;
        if (generation != _fetchGeneration) return;
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
