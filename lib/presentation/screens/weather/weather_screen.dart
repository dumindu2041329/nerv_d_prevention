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

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        backgroundColor: theme.scaffoldBackgroundColor,
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
            // Draggable bottom sheet with real data
            DraggableScrollableSheet(
              initialChildSize: 0.45,
              minChildSize: 0.15,
              maxChildSize: 0.85,
              controller: _sheetController,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    boxShadow: theme.brightness == Brightness.light
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, -2),
                            ),
                          ]
                        : null,
                  ),
                  child: BlocBuilder<WeatherBloc, WeatherState>(
                    builder: (context, state) {
                      final onSurface = theme.colorScheme.onSurface;
                      if (state is WeatherLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        );
                      }

                      if (state is WeatherError) {
                        return Center(
                          child: Text(
                            state.message,
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.6),
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
                            color: onSurface.withValues(alpha: 0.5),
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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final data = state.weatherData;
    final current = data.current;
    final hourly = data.hourly;
    final daily = data.daily;
    final locationName = state.location?.name ?? 'Current Location';

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
                      color: onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '$locationName Weather',
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ($dayName)',
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                  color: onSurface.withValues(alpha: 0.12),
                  height: 1,
                ),
              ],
            ),
          ),
        ),

        // ── Current Conditions ──
        SliverToBoxAdapter(
          child: _buildCurrentConditionsDetail(context, current, locationName),
        ),

        // ── Hourly forecast strip ──
        SliverToBoxAdapter(child: _buildHourlySection(context, hourly)),

        // ── 5-Day forecast ──
        SliverToBoxAdapter(child: _buildDailySection(context, daily)),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  // ── Current Conditions Detail ──────────────────────────────────────

  Widget _buildCurrentConditionsDetail(
    BuildContext context,
    dynamic current,
    String locationName,
  ) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final weatherDesc = WeatherCodeMapping.getDescription(
      current.weatherCode,
      isDay: current.isDay,
    );
    final weatherEmoji = WeatherCodeMapping.getIcon(
      current.weatherCode,
      isDay: current.isDay,
    );

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
                    style: TextStyle(
                      color: onSurface,
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
                      color: onSurface.withValues(alpha: 0.65),
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
                  context,
                  'Feels Like',
                  '${current.apparentTemperature.toStringAsFixed(1)}°C',
                  Icons.thermostat,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _detailTile(
                  context,
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
                  context,
                  'Wind',
                  '${current.windSpeed.toStringAsFixed(1)} km/h',
                  Icons.air,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _detailTile(
                  context,
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
                  context,
                  'UV Index',
                  current.uvIndex.toStringAsFixed(1),
                  Icons.wb_sunny,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _detailTile(
                  context,
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

  Widget _detailTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final tileColor = theme.brightness == Brightness.dark
        ? const Color(0xFF1A1A1A)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dividerTheme.color ?? onSurface.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.55),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: onSurface,
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

  Widget _buildHourlySection(BuildContext context, dynamic hourly) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final tileColor = theme.brightness == Brightness.dark
        ? const Color(0xFF1A1A1A)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Hourly Forecast',
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '12 hours',
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.5),
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
                return _buildHourlyChip(context, hour, tileColor);
              },
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            color: onSurface.withValues(alpha: 0.1),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChip(
    BuildContext context,
    dynamic hour,
    Color tileColor,
  ) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final hourIsDay = hour.time.hour >= 6 && hour.time.hour < 18;
    final emoji = WeatherCodeMapping.getIcon(hour.weatherCode, isDay: hourIsDay);
    final timeLabel = DateTimeUtils.formatTime(hour.time);

    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dividerTheme.color ?? onSurface.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Text(
            '${hour.temperature.toStringAsFixed(0)}°',
            style: TextStyle(
              color: onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            timeLabel,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
          if (hour.precipitationProbability > 0)
            Text(
              '${hour.precipitationProbability.toStringAsFixed(0)}%',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  // ── Daily Forecast ──────────────────────────────────────────────────

  Widget _buildDailySection(BuildContext context, dynamic daily) {
    if (daily.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '5-Day Forecast',
              style: TextStyle(
                color: onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...daily.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            return _buildDailyCard(
              context,
              day,
              index,
              index == daily.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDailyCard(
    BuildContext context,
    dynamic day,
    int index,
    bool isLast,
  ) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final emoji = WeatherCodeMapping.getIcon(day.weatherCode, isDay: true);
    final desc = WeatherCodeMapping.getDescription(
      day.weatherCode,
      isDay: true,
    );

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
                  color: theme.dividerTheme.color ??
                      onSurface.withValues(alpha: 0.08),
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
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.5),
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 2),
                Text(
                  '${day.precipitationProbabilityMax.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: theme.colorScheme.primary.withValues(alpha: 0.85),
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.9),
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
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      const Color(0xFFFF6B00),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '°',
                style: TextStyle(
                  color: Color(0xFFFF6B00),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${day.temperatureMax.toStringAsFixed(0)}',
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
