part of 'weather_bloc.dart';

abstract class WeatherState extends Equatable {
  const WeatherState();

  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherRefreshing extends WeatherState {
  final WeatherData weatherData;
  final Location? location;
  final bool isStaleCache;
  final SLDistrict? selectedDistrict;

  const WeatherRefreshing({
    required this.weatherData,
    this.location,
    this.isStaleCache = false,
    this.selectedDistrict,
  });

  @override
  List<Object?> get props => [
    weatherData,
    location,
    isStaleCache,
    selectedDistrict,
  ];
}

class WeatherLoaded extends WeatherState {
  final WeatherData weatherData;
  final Location? location;
  final bool isStaleCache;
  final List<Location> searchResults;
  final bool isSearching;
  final SLDistrict? selectedDistrict;

  const WeatherLoaded({
    required this.weatherData,
    this.location,
    this.isStaleCache = false,
    this.searchResults = const [],
    this.isSearching = false,
    this.selectedDistrict,
  });

  @override
  List<Object?> get props => [
    weatherData,
    location,
    isStaleCache,
    searchResults,
    isSearching,
    selectedDistrict,
  ];

  WeatherLoaded copyWith({
    WeatherData? weatherData,
    Location? location,
    bool? isStaleCache,
    List<Location>? searchResults,
    bool? isSearching,
    SLDistrict? selectedDistrict,
    bool clearDistrict = false,
  }) {
    return WeatherLoaded(
      weatherData: weatherData ?? this.weatherData,
      location: location ?? this.location,
      isStaleCache: isStaleCache ?? this.isStaleCache,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      selectedDistrict: clearDistrict
          ? null
          : selectedDistrict ?? this.selectedDistrict,
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
