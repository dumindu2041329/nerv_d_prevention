import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/weather_codes.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/weather_alert_deriver.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/entities/weather_data.dart';
import '../../blocs/weather/weather_bloc.dart';
import '../../widgets/nerv/nerv_styles.dart';
import '../../widgets/nerv/deck_header.dart';
import '../../widgets/nerv/posture_gauge.dart';

class WeatherDetailScreen extends StatefulWidget {
  const WeatherDetailScreen({super.key});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
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
        body: SafeArea(
          child: BlocBuilder<WeatherBloc, WeatherState>(
            builder: (context, state) {
              if (state is WeatherLoading) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (state is WeatherError) {
                return Center(
                  child: Text(state.message, style: context.nerv.body),
                );
              }
              if (state is WeatherLoaded) {
                return _buildContent(context, state);
              }
              return Center(
                child: Text('Loading weather...', style: context.nerv.dataLabel),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeatherLoaded state) {
    final data = state.weatherData;
    final alerts = WeatherAlertDeriver.deriveAlerts(
      data,
      districtName: state.location?.name,
    );
    final posture = NervStyles.postureOf(alerts.map((a) => a.severity).toList());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeckHeader(
          title: 'Weather Details',
          eyebrowText: 'SRI LANKA · OBSERVATION',
          subtitle: state.location?.name ?? 'Current Location',
          posture: posture,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentConditions(context, data.current),
                const SizedBox(height: 16),
                PostureGauge(level: posture),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'HOURLY TEMPERATURE'),
                const SizedBox(height: 12),
                _buildHourlyChart(context, data.hourly),
                const SizedBox(height: 24),
                _buildSectionTitle(context, '7-DAY OUTLOOK'),
                const SizedBox(height: 12),
                _buildDailyForecast(context, data.daily),
                if (data.daily.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'SUN · WIND'),
                  const SizedBox(height: 12),
                  _buildSunriseSunsetCard(context, data.daily.first),
                  const SizedBox(height: 10),
                  _buildWindCard(context, data),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Eyebrow(title, color: context.nerv.onSurface.withValues(alpha: 0.6));
  }

  Widget _buildCurrentConditions(BuildContext context, CurrentWeather current) {
    final nerv = context.nerv;
    final onSurface = nerv.onSurface;
    final weatherIcon = WeatherCodeMapping.getIcon(
      current.weatherCode,
      isDay: current.isDay,
    );
    final weatherDesc = WeatherCodeMapping.getDescription(
      current.weatherCode,
      isDay: current.isDay,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: nerv.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: nerv.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow('CURRENT'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(weatherIcon, style: const TextStyle(fontSize: 56)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${current.temperature.toStringAsFixed(1)}°C',
                    style: nerv.numeral(size: 48),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weatherDesc,
                    style: nerv.body.copyWith(fontSize: 14),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'FEELS ${current.apparentTemperature.toStringAsFixed(0)}°C',
                style: nerv.dataLabel.copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: onSurface.withValues(alpha: 0.08)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildConditionItem(context, 'HUMIDITY', '${current.humidity.toStringAsFixed(0)}%'),
              _buildConditionItem(context, 'WIND', '${current.windSpeed.toStringAsFixed(0)} km/h'),
              _buildConditionItem(context, 'PRECIP', '${current.precipitation.toStringAsFixed(1)} mm'),
              _buildConditionItem(context, 'UV', current.uvIndex.toStringAsFixed(0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionItem(BuildContext context, String label, String value) {
    final nerv = context.nerv;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(label, color: nerv.onSurface.withValues(alpha: 0.4)),
        const SizedBox(height: 4),
        Text(value, style: nerv.numeralSmall(size: 13)),
      ],
    );
  }

  Widget _buildHourlyChart(BuildContext context, List<HourlyWeather> hourly) {
    final theme = Theme.of(context);
    final nerv = context.nerv;
    final displayHours = hourly.take(12).toList();
    if (displayHours.isEmpty) return const SizedBox.shrink();

    final minTemp = displayHours.map((h) => h.temperature).reduce((a, b) => a < b ? a : b);
    final maxTemp = displayHours.map((h) => h.temperature).reduce((a, b) => a > b ? a : b);
    final tempRange = (maxTemp - minTemp) * 0.3;
    final chartMinY = (minTemp - tempRange).floorToDouble();
    final chartMaxY = (maxTemp + tempRange).ceilToDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: nerv.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nerv.border, width: 1),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (chartMaxY - chartMinY) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: nerv.hairline,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= displayHours.length) {
                    return const SizedBox.shrink();
                  }
                  final hour = displayHours[idx];
                  final label = DateTimeUtils.formatTime(hour.time);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: nerv.dataLabel.copyWith(
                        fontSize: 10,
                        color: nerv.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}°',
                    style: nerv.dataLabel.copyWith(fontSize: 10),
                  );
                },
                reservedSize: 32,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (displayHours.length - 1).toDouble(),
          minY: chartMinY,
          maxY: chartMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                displayHours.length,
                (i) => FlSpot(i.toDouble(), displayHours[i].temperature),
              ),
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyForecast(BuildContext context, List<DailyWeather> daily) {
    final nerv = context.nerv;
    final onSurface = nerv.onSurface;
    final displayDays = daily.take(7).toList();
    if (displayDays.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: nerv.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nerv.border, width: 1),
      ),
      child: Column(
        children: List.generate(displayDays.length, (index) {
          final day = displayDays[index];
          String dayLabel;
          if (index == 0) {
            dayLabel = 'TODAY';
          } else if (index == 1) {
            dayLabel = 'TOMORROW';
          } else {
            final weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
            dayLabel = weekdays[day.time.weekday % 7];
          }

          final conditionIcon = WeatherCodeMapping.getIcon(
            day.weatherCode,
            isDay: true,
          );

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: index == displayDays.length - 1
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
                  width: 78,
                  child: Text(
                    dayLabel,
                    style: TextStyle(
                      color: index == 0 ? Theme.of(context).colorScheme.primary : onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Text(conditionIcon, style: const TextStyle(fontSize: 18)),
                const Spacer(),
                Text(
                  '${day.temperatureMin.toStringAsFixed(0)}°',
                  style: nerv.dataLabel.copyWith(color: onSurface.withValues(alpha: 0.55)),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 56,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
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
        }),
      ),
    );
  }

  Widget _buildSunriseSunsetCard(BuildContext context, DailyWeather today) {
    final nerv = context.nerv;
    final onSurface = nerv.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: nerv.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nerv.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSunItem(
            context,
            'SUNRISE',
            DateTimeUtils.formatTime(today.sunrise),
          ),
          Container(width: 1, height: 40, color: onSurface.withValues(alpha: 0.12)),
          _buildSunItem(
            context,
            'SUNSET',
            DateTimeUtils.formatTime(today.sunset),
          ),
        ],
      ),
    );
  }

  Widget _buildSunItem(BuildContext context, String label, String time) {
    final nerv = context.nerv;
    return Column(
      children: [
        Eyebrow(label, color: nerv.onSurface.withValues(alpha: 0.45)),
        const SizedBox(height: 6),
        Text(time, style: nerv.numeralSmall(size: 16)),
      ],
    );
  }

  Widget _buildWindCard(BuildContext context, WeatherData data) {
    final nerv = context.nerv;
    final onSurface = nerv.onSurface;
    final current = data.current;
    final windDir = _windDirectionFromDegrees(current.windDirection);
    final gustSpeed = data.daily.isNotEmpty ? data.daily.first.windGustsMax : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: nerv.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: nerv.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildWindItem(context, 'DIRECTION', windDir),
          Container(width: 1, height: 40, color: onSurface.withValues(alpha: 0.12)),
          _buildWindItem(context, 'SPEED', '${current.windSpeed.toStringAsFixed(0)} km/h'),
          Container(width: 1, height: 40, color: onSurface.withValues(alpha: 0.12)),
          _buildWindItem(
            context,
            'GUSTS',
            gustSpeed > 0 ? '${gustSpeed.toStringAsFixed(0)} km/h' : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildWindItem(BuildContext context, String label, String value) {
    final nerv = context.nerv;
    return Column(
      children: [
        Eyebrow(label, color: nerv.onSurface.withValues(alpha: 0.45)),
        const SizedBox(height: 6),
        Text(value, style: nerv.numeralSmall(size: 13)),
      ],
    );
  }

  String _windDirectionFromDegrees(double degrees) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    final index = ((degrees + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }
}
