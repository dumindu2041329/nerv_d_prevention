part of 'weather_bloc.dart';

abstract class WeatherState extends Equatable {
  const WeatherState();

  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherLoaded extends WeatherState {
  final WeatherData weatherData;
  final Location? location;
  final bool isStaleCache;
  final List<Location> searchResults;

  const WeatherLoaded({
    required this.weatherData,
    this.location,
    this.isStaleCache = false,
    this.searchResults = const [],
  });

  @override
  List<Object?> get props => [weatherData, location, isStaleCache, searchResults];

  WeatherLoaded copyWith({
    WeatherData? weatherData,
    Location? location,
    bool? isStaleCache,
    List<Location>? searchResults,
  }) {
    return WeatherLoaded(
      weatherData: weatherData ?? this.weatherData,
      location: location ?? this.location,
      isStaleCache: isStaleCache ?? this.isStaleCache,
      searchResults: searchResults ?? this.searchResults,
    );
  }
}

class WeatherError extends WeatherState {
  final String message;
  final WeatherData? cachedData;

  const WeatherError({required this.message, this.cachedData});

  @override
  List<Object?> get props => [message, cachedData];
}
