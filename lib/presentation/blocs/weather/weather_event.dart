part of 'weather_bloc.dart';

abstract class WeatherEvent extends Equatable {
  const WeatherEvent();

  @override
  List<Object?> get props => [];
}

class LoadWeather extends WeatherEvent {
  final Location? location;
  final bool forceRefresh;

  const LoadWeather({this.location, this.forceRefresh = false});

  @override
  List<Object?> get props => [location, forceRefresh];
}

class RefreshWeather extends WeatherEvent {
  const RefreshWeather();
}

class SearchLocations extends WeatherEvent {
  final String query;

  const SearchLocations({required this.query});

  @override
  List<Object?> get props => [query];
}

class SelectLocation extends WeatherEvent {
  final Location location;

  const SelectLocation({required this.location});

  @override
  List<Object?> get props => [location];
}
