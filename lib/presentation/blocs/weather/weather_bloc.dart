import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/weather_data.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/repositories/weather_repository.dart';

part 'weather_event.dart';
part 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherRepository _weatherRepository;

  WeatherBloc({required WeatherRepository weatherRepository})
    : _weatherRepository = weatherRepository,
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

    // Resolve real GPS in background and update
    _weatherRepository.getLocationFromGps().then((gpsLocation) {
      if (gpsLocation != null) {
        _weatherRepository.cacheLocation(gpsLocation);
        add(_FetchWeatherInBackground(location: gpsLocation, forceRefresh: true));
      }
    });
  }

  Future<void> _onFetchWeatherInBackground(
    _FetchWeatherInBackground event,
    Emitter<WeatherState> emit,
  ) async {
    try {
      Location location = event.location;

      if (location.isGps) {
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
}
