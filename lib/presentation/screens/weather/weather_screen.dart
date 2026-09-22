import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/constants/app_sl_constants.dart';
import '../../../core/constants/weather_codes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/weather_alert_deriver.dart';
import '../../../domain/entities/location.dart';
import '../../blocs/weather/weather_bloc.dart';
import '../../widgets/nerv/nerv_styles.dart';
import '../../widgets/nerv/posture_gauge.dart';

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
            Positioned.fill(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: SLMapConstants.center,
                  initialZoom: SLMapConstants.initialZoom,
                  minZoom: SLMapConstants.minZoom,
                  maxZoom: SLMapConstants.maxZoom,
                  cameraConstraint: CameraConstraint.containLatitude(),
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
                      if (state is WeatherLoading) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                            strokeWidth: 2,
                          ),
                        );
                      }

                      if (state is WeatherError) {
                        return Center(
                          child: Text(
                            state.message,
                            style: context.nerv.body,
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
                          style: context.nerv.dataLabel,
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
    final nerv = context.nerv;
    final data = state.weatherData;
    final current = data.current;
    final hourly = data.hourly;
    final daily = data.daily;
    final locationName = state.location?.name ?? 'Current Location';

    final now = DateTime.now();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = weekdays[now.weekday - 1];

    final alerts = WeatherAlertDeriver.deriveAlerts(
      data,
      districtName: state.location?.name,
    );
    final posture = NervStyles.postureOf(alerts.map((a) => a.severity).toList());

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Eyebrow('FORECAST · ${posture.label}'),
                    ),
                    Text(
                      locationName,
                      style: nerv.dataLabel.copyWith(
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      WeatherCodeMapping.getIcon(
                        current.weatherCode,
                        isDay: current.isDay,
                      ),
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${current.temperature.toStringAsFixed(1)}°C',
                            style: nerv.numeral(size: 56),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            WeatherCodeMapping.getDescription(
                              current.weatherCode,
                              isDay: current.isDay,
                            ),
                            style: nerv.body.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}',
                          style: nerv.dataLabel.copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '($dayName)',
                          style: nerv.dataLabel.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                PostureGauge(level: posture),
                const SizedBox(height: 8),
                Divider(color: onSurface.withValues(alpha: 0.1), height: 1),
              ],
            ),
          ),
        ),

        // ── Conditions grid ──
        SliverToBoxAdapter(
          child: _buildConditionsGrid(context, current),
        ),

        // ── Hourly strip ──
        SliverToBoxAdapter(child: _buildHourlySection(context, hourly)),

        // ── Daily forecast ──
        SliverToBoxAdapter(child: _buildDailySection(context, daily)),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildConditionsGrid(BuildContext context, dynamic current) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'FEELS LIKE',
                  value: '${current.apparentTemperature.toStringAsFixed(1)}°C',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'HUMIDITY',
                  value: '${current.humidity.toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'WIND',
                  value: '${current.windSpeed.toStringAsFixed(1)} km/h',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'PRESSURE',
                  value: '${current.surfacePressure.toStringAsFixed(0)} hPa',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'UV',
                  value: current.uvIndex.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'CLOUD',
                  value: '${current.cloudCover.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final nerv = context.nerv;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: nerv.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: nerv.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label, color: nerv.onSurface.withValues(alpha: 0.45)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: nerv.numeralSmall(size: 14)),
          ),
        ],
      ),
    );
  }

  // ── Hourly forecast strip ──────────────────────────────────────────

  Widget _buildHourlySection(BuildContext context, dynamic hourly) {
    final nerv = context.nerv;
    final onSurface = nerv.onSurface;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Eyebrow('HOURLY · 24H'),
                const Spacer(),
                Text(
                  'NOW',
                  style: nerv.dataLabel.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: hourly.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final hour = hourly[index];
                return _buildHourlyChip(context, hour);
              },
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(height: 1, color: onSurface.withValues(alpha: 0.08)),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChip(BuildContext context, dynamic hour) {
    final nerv = context.nerv;
    final onSurface = nerv.onSurface;
    final accent = Theme.of(context).colorScheme.primary;
    final hourIsDay = hour.time.hour >= 6 && hour.time.hour < 18;
    final emoji = WeatherCodeMapping.getIcon(hour.weatherCode, isDay: hourIsDay);

    return Container(
      width: 66,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: nerv.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: nerv.border, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateTimeUtils.formatTime(hour.time).toUpperCase(),
            style: nerv.dataLabel.copyWith(
              color: onSurface.withValues(alpha: 0.6),
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 20)),
          Text(
            '${hour.temperature.toStringAsFixed(0)}°',
            style: nerv.numeralSmall(size: 16),
          ),
          if (hour.precipitationProbability > 0)
            Text(
              '${hour.precipitationProbability.toStringAsFixed(0)}%',
              style: TextStyle(
                color: accent,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Daily forecast ──────────────────────────────────────────────────

  Widget _buildDailySection(BuildContext context, dynamic daily) {
    if (daily.isEmpty) return const SizedBox.shrink();
    final nerv = context.nerv;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Eyebrow('7-DAY OUTLOOK'),
                const Spacer(),
                Text(
                  'LOW / HIGH',
                  style: nerv.dataLabel.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: nerv.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: nerv.border, width: 1),
            ),
            child: Column(
              children: daily.asMap().entries.map<Widget>((entry) {
                final index = entry.key;
                final day = entry.value;
                return _buildDailyLedgerRow(
                  context,
                  day,
                  index,
                  isLast: index == daily.length - 1,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLedgerRow(
    BuildContext context,
    dynamic day,
    int index, {
    required bool isLast,
  }) {
    final nerv = context.nerv;
    final onSurface = nerv.onSurface;
    final theme = Theme.of(context);
    final emoji = WeatherCodeMapping.getIcon(day.weatherCode, isDay: true);

    String dayLabel;
    if (index == 0) {
      dayLabel = 'TODAY';
    } else if (index == 1) {
      dayLabel = 'TOMORROW';
    } else {
      final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      dayLabel = weekdays[day.time.weekday - 1];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: onSurface.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              dayLabel,
              style: TextStyle(
                color: index == 0 ? theme.colorScheme.primary : onSurface,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Icon(
            Icons.water_drop,
            size: 12,
            color: theme.colorScheme.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 2),
          Text(
            '${day.precipitationProbabilityMax.toStringAsFixed(0)}%',
            style: TextStyle(
              color: theme.colorScheme.primary.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${day.temperatureMin.toStringAsFixed(0)}°',
            style: nerv.dataLabel.copyWith(color: onSurface.withValues(alpha: 0.55)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 64,
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
          Text(
            '${day.temperatureMax.toStringAsFixed(0)}°',
            style: nerv.numeralSmall(size: 13),
          ),
        ],
      ),
    );
  }
}
