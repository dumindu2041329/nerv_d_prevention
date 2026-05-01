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
    on<RefreshWeather>(_onRefreshWeather);
    on<SearchLocations>(_onSearchLocations);
    on<SelectLocation>(_onSelectLocation);
  }

  Future<void> _onLoadWeather(
    LoadWeather event,
    Emitter<WeatherState> emit,
  ) async {
    emit(WeatherLoading());

    try {
      Location? targetLocation = event.location;
      if (targetLocation == null || targetLocation.isGps) {
        targetLocation = await _weatherRepository.getLocationFromGps();
      }

      final location = targetLocation ?? const Location(
        id: 'default',
        name: 'Colombo',
        country: 'Sri Lanka',
        latitude: 6.9271,
        longitude: 79.8612,
      );

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
      final cached = await _weatherRepository.getCachedWeatherData();
      if (cached != null) {
        emit(WeatherLoaded(
          weatherData: cached,
          location: event.location,
          isStaleCache: true,
        ));
      } else {
        emit(WeatherError(message: e.toString()));
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
