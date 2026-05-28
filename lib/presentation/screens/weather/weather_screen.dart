import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/constants/app_sl_constants.dart';
import '../../../core/constants/weather_codes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/location.dart';
import '../../blocs/weather/weather_bloc.dart';
import '../../widgets/national_local_toggle.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _isIslandWide = true;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  void _onToggleChanged(bool isNational) {
    setState(() => _isIslandWide = isNational);
    if (isNational) {
      context.read<WeatherBloc>().add(
        LoadWeather(
          location: const Location(
            id: 'island_wide',
            name: 'Sri Lanka',
            country: 'Sri Lanka',
            latitude: 7.8731,
            longitude: 80.7718,
          ),
        ),
      );
    } else {
      context.read<WeatherBloc>().add(const LoadWeather(useGps: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WeatherBloc>()..add(
        LoadWeather(
          location: const Location(
            id: 'island_wide',
            name: 'Sri Lanka',
            country: 'Sri Lanka',
            latitude: 7.8731,
            longitude: 80.7718,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Map background
            Positioned.fill(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: SLMapConstants.center,
                  initialZoom: SLMapConstants.initialZoom,
                  minZoom: SLMapConstants.minZoom,
                  maxZoom: SLMapConstants.maxZoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: ApiConstants.mapTileHybrid,
                    userAgentPackageName: 'com.example.nerv_d_prevention',
                  ),
                  TileLayer(
                    urlTemplate: ApiConstants.owmPrecipitationOverlay,
                    userAgentPackageName: 'com.example.nerv_d_prevention',
                    tileDisplay: const TileDisplay.instantaneous(opacity: 0.6),
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
                isNational: _isIslandWide,
                onChanged: _onToggleChanged,
              ),
            ),
            // Draggable bottom sheet with real data
            DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.15,
              maxChildSize: 0.85,
              controller: _sheetController,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: BlocBuilder<WeatherBloc, WeatherState>(
                    builder: (context, state) {
                      if (state is WeatherLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF00BCD4),
                          ),
                        );
                      }

                      if (state is WeatherError) {
                        return Center(
                          child: Text(
                            state.message,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      }

                      if (state is WeatherLoaded) {
                        return _buildWeatherContent(
                          context,
                          scrollController,
                          state,
                        );
                      }

                      return Center(
                        child: Text(
                          'Loading weather...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
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

  Widget _buildWeatherContent(
    BuildContext context,
    ScrollController scrollController,
    WeatherLoaded state,
  ) {
    final data = state.weatherData;
    final current = data.current;
    final hourly = data.hourly;
    final daily = data.daily;
    final locationName =
        state.location?.name ??
        'Current Location';

    final now = DateTime.now();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = weekdays[now.weekday - 1];

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                  '$locationName Weather',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ($dayName)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
              ],
            ),
          ),
        ),

        // ── Current Conditions ──
        SliverToBoxAdapter(
          child: _buildCurrentConditionsDetail(current, locationName),
        ),

        // ── Hourly forecast strip ──
        SliverToBoxAdapter(child: _buildHourlySection(hourly)),

        // ── 5-Day forecast ──
        SliverToBoxAdapter(child: _buildDailySection(daily)),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // ── Current Conditions Detail ──────────────────────────────────────

  Widget _buildCurrentConditionsDetail(dynamic current, String locationName) {
    final weatherDesc = WeatherCodeMapping.getDescription(current.weatherCode);
    final weatherEmoji = WeatherCodeMapping.getIcon(current.weatherCode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Big temp display
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(weatherEmoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${current.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weatherDesc,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Detail grid: 2 columns × 4 rows
          Row(
            children: [
              Expanded(
                child: _detailTile(
                  'Feels Like',
                  '${current.apparentTemperature.toStringAsFixed(1)}°C',
                  Icons.thermostat,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _detailTile(
                  'Humidity',
                  '${current.humidity.toStringAsFixed(0)}%',
                  Icons.water_drop,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _detailTile(
                  'Wind',
                  '${current.windSpeed.toStringAsFixed(1)} km/h',
                  Icons.air,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _detailTile(
                  'Pressure',
                  '${current.surfacePressure.toStringAsFixed(0)} hPa',
                  Icons.speed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _detailTile(
                  'UV Index',
                  current.uvIndex.toStringAsFixed(1),
                  Icons.wb_sunny,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _detailTile(
                  'Cloud Cover',
                  '${current.cloudCover.toStringAsFixed(0)}%',
                  Icons.cloud,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hourly Forecast Strip ──────────────────────────────────────────

  Widget _buildHourlySection(dynamic hourly) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Hourly Forecast',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '12 hours',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: hourly.length,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final hour = hourly[index];
                return _buildHourlyChip(hour);
              },
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChip(dynamic hour) {
    final emoji = WeatherCodeMapping.getIcon(hour.weatherCode);
    final timeLabel = DateTimeUtils.formatTime(hour.time);

    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Text(
            '${hour.temperature.toStringAsFixed(0)}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            timeLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          if (hour.precipitationProbability > 0)
            Text(
              '${hour.precipitationProbability.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Color(0xFF00BCD4),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  // ── Daily Forecast ──────────────────────────────────────────────────

  Widget _buildDailySection(dynamic daily) {
    if (daily.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '5-Day Forecast',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...daily.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            return _buildDailyCard(day, index, index == daily.length - 1);
          }),
        ],
      ),
    );
  }

  Widget _buildDailyCard(dynamic day, int index, bool isLast) {
    final emoji = WeatherCodeMapping.getIcon(day.weatherCode);
    final desc = WeatherCodeMapping.getDescription(day.weatherCode);

    String dayLabel;
    if (index == 0) {
      dayLabel = 'Today';
    } else if (index == 1) {
      dayLabel = 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      dayLabel = weekdays[day.time.weekday - 1];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          // Day label + desc
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Weather emoji
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          // Precip probability
          SizedBox(
            width: 40,
            child: Row(
              children: [
                Icon(
                  Icons.water_drop,
                  size: 12,
                  color: const Color(0xFF00BCD4).withValues(alpha: 0.7),
                ),
                const SizedBox(width: 2),
                Text(
                  '${day.precipitationProbabilityMax.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: const Color(0xFF00BCD4).withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Temp range
          Row(
            children: [
              Text(
                '${day.temperatureMin.toStringAsFixed(0)}°',
                style: TextStyle(
                  color: const Color(0xFF00BCD4).withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BCD4), Color(0xFFFF6B00)],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${day.temperatureMax.toStringAsFixed(0)}°',
                style: const TextStyle(
                  color: Color(0xFFFF6B00),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
