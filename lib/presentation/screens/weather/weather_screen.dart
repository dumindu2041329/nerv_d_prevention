import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/di/injection.dart';
import '../../blocs/weather/weather_bloc.dart';
import '../../widgets/national_local_toggle.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _isNational = true;
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WeatherBloc>()..add(const LoadWeather()),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Map background
            Positioned.fill(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(36.0, 138.0),
                  initialZoom: 5,
                  minZoom: 3,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.nerv_d_prevention',
                  ),
                ],
              ),
            ),
            // Toggle at top
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: NationalLocalToggle(
                isNational: _isNational,
                onChanged: (val) => setState(() => _isNational = val),
              ),
            ),
            // Draggable bottom sheet
            DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.15,
              maxChildSize: 0.85,
              controller: _sheetController,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: BlocBuilder<WeatherBloc, WeatherState>(
                    builder: (context, state) {
                      return CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildSheetHeader(context),
                          ),
                          if (state is WeatherLoaded)
                            _buildCityGrid(context, state)
                          else if (state is WeatherLoading)
                            const SliverFillRemaining(
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF00BCD4),
                                ),
                              ),
                            )
                          else
                            SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'Weather data unavailable',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = weekdays[now.weekday - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF4A4A4A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isNational ? 'National Weather' : 'Local Weather',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${now.year}/${now.month}/${now.day}　($dayName)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            color: Colors.white.withValues(alpha: 0.1),
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildCityGrid(BuildContext context, WeatherLoaded state) {
    final cities = _getCityData(state);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Two cities per row
            final leftIndex = index * 2;
            final rightIndex = index * 2 + 1;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCityRow(cities[leftIndex]),
                  ),
                  if (rightIndex < cities.length)
                    Expanded(
                      child: _buildCityRow(cities[rightIndex]),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            );
          },
          childCount: (cities.length / 2).ceil(),
        ),
      ),
    );
  }

  Widget _buildCityRow(_CityWeather city) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              city.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            city.icon,
            size: 18,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${city.high}°C',
              style: const TextStyle(
                color: Color(0xFFFF6B00),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 36,
            child: Text(
              '${city.low}°C',
              style: TextStyle(
                color: const Color(0xFF00BCD4).withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  List<_CityWeather> _getCityData(WeatherLoaded state) {
    // Use actual weather data for the current location plus demo cities
    final current = state.weatherData.current;
    final daily = state.weatherData.daily;
    final locationName = state.location?.displayName ?? 'Current';

    final todayHigh = daily.isNotEmpty ? daily.first.temperatureMax.round() : current.temperature.round() + 3;
    final todayLow = daily.isNotEmpty ? daily.first.temperatureMin.round() : current.temperature.round() - 5;

    return [
      _CityWeather(locationName, Icons.cloud, todayHigh, todayLow),
      _CityWeather('Nagoya', Icons.wb_sunny_outlined, 30, 16),
      _CityWeather('Sapporo', Icons.cloud_outlined, 20, 11),
      _CityWeather('Ōsaka', Icons.wb_sunny_outlined, 31, 17),
      _CityWeather('Sendai', Icons.wb_sunny_outlined, 22, 12),
      _CityWeather('Hiroshima', Icons.wb_sunny_outlined, 30, 16),
      _CityWeather('Niigata', Icons.wb_sunny_outlined, 28, 13),
      _CityWeather('Kōchi', Icons.wb_sunny_outlined, 29, 16),
      _CityWeather('Kanazawa', Icons.wb_sunny_outlined, 28, 14),
      _CityWeather('Fukuoka', Icons.wb_sunny_outlined, 30, 16),
      _CityWeather('Matsumoto', Icons.wb_sunny_outlined, 34, 12),
      _CityWeather('Kagoshima', Icons.wb_sunny_outlined, 29, 17),
      _CityWeather('Tōkyō', Icons.wb_sunny_outlined, 29, 16),
      _CityWeather('Naha', Icons.wb_sunny_outlined, 26, 21),
    ];
  }
}

class _CityWeather {
  final String name;
  final IconData icon;
  final int high;
  final int low;

  const _CityWeather(this.name, this.icon, this.high, this.low);
}
