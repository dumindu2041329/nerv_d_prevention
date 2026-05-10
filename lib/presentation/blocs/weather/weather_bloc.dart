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
    Location? targetLocation = event.location;

    if (targetLocation == null || targetLocation.isGps) {
      final cachedLocation = _weatherRepository.getCachedLocation();
      if (cachedLocation != null) {
        targetLocation = cachedLocation;
      }
    }

    final location = targetLocation ?? const Location(
      id: 'default',
      name: 'Colombo',
      country: 'Sri Lanka',
      latitude: 6.9271,
      longitude: 79.8612,
    );

    final cached = await _weatherRepository.getCachedWeatherData();
    if (cached != null) {
      emit(WeatherLoaded(
        weatherData: cached,
        location: location,
        isStaleCache: true,
      ));

      add(_FetchWeatherInBackground(location: location, forceRefresh: event.forceRefresh));
    } else {
      emit(WeatherLoading());
      if (targetLocation == null || targetLocation.isGps) {
        targetLocation = await _weatherRepository.getLocationFromGps();
        final finalLocation = targetLocation ?? location;
        if (targetLocation != null) {
          await _weatherRepository.cacheLocation(targetLocation);
        }
        add(_FetchWeatherInBackground(location: finalLocation, forceRefresh: event.forceRefresh));
      } else {
        add(_FetchWeatherInBackground(location: location, forceRefresh: event.forceRefresh));
      }
    }
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

      emit(WeatherLoaded(
        weatherData: weatherData,
        location: location,
        isStaleCache: false,
      ));
    } catch (e) {
      final currentState = state;
      if (currentState is WeatherLoaded) {
        emit(WeatherLoaded(
          weatherData: currentState.weatherData,
          location: currentState.location,
          isStaleCache: true,
        ));
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

        emit(WeatherLoaded(
          weatherData: weatherData,
          location: currentState.location,
          isStaleCache: false,
        ));
      } catch (e) {
        emit(WeatherLoaded(
          weatherData: currentState.weatherData,
          location: currentState.location,
          isStaleCache: true,
        ));
      }
    }
  }

  Future<void> _onSearchLocations(
    SearchLocations event,
    Emitter<WeatherState> emit,
  ) async {
    if (event.query.length < 2) {
      if (state is WeatherLoaded) {
        emit((state as WeatherLoaded)
            .copyWith(searchResults: [], isSearching: false));
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
        emit(currentState.copyWith(
          searchResults: locations,
          isSearching: false,
        ));
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
