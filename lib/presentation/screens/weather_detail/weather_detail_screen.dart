import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/entities/weather_data.dart';
import '../../blocs/weather/weather_bloc.dart';

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
        appBar: AppBar(
          title: const Text('Weather Details'),
        ),
        body: BlocBuilder<WeatherBloc, WeatherState>(
          builder: (context, state) {
            if (state is WeatherLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is WeatherError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              );
            }
            if (state is WeatherLoaded) {
              return _buildContent(context, state.weatherData);
            }
            return const Center(child: Text('Loading weather...'));
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WeatherData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentConditions(context, data.current),
          const SizedBox(height: AppSpacing.space6),
          _buildSectionTitle(context, 'Hourly Forecast'),
          const SizedBox(height: AppSpacing.space4),
          _buildHourlyChart(context, data.hourly),
          const SizedBox(height: AppSpacing.space6),
          _buildSectionTitle(context, '7-Day Forecast'),
          const SizedBox(height: AppSpacing.space4),
          _buildDailyForecast(context, data.daily),
          if (data.daily.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space6),
            _buildSectionTitle(context, 'Sunrise & Sunset'),
            const SizedBox(height: AppSpacing.space4),
            _buildSunriseSunsetCard(context, data.daily.first),
            const SizedBox(height: AppSpacing.space6),
            _buildSectionTitle(context, 'Wind Details'),
            const SizedBox(height: AppSpacing.space4),
            _buildWindCard(context, data),
          ],
          const SizedBox(height: AppSpacing.space8),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCurrentConditions(BuildContext context, CurrentWeather current) {
    final theme = Theme.of(context);
    final weatherIcon = WeatherCodeMapping.getIcon(current.weatherCode, isDay: current.isDay);
    final weatherDesc = WeatherCodeMapping.getDescription(current.weatherCode, isDay: current.isDay);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.2),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Text(
            weatherIcon,
            style: const TextStyle(fontSize: 72),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '${current.temperature.toStringAsFixed(1)}°C',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            weatherDesc,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Feels like ${current.apparentTemperature.toStringAsFixed(1)}°C',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildConditionItem(
                Icons.water_drop_outlined,
                'Humidity',
                '${current.humidity.toStringAsFixed(0)}%',
              ),
              _buildConditionItem(
                Icons.air,
                'Wind',
                '${current.windSpeed.toStringAsFixed(0)} km/h',
              ),
              _buildConditionItem(
                Icons.umbrella_outlined,
                'Precip',
                '${current.precipitation.toStringAsFixed(1)} mm',
              ),
              _buildConditionItem(
                Icons.wb_sunny_outlined,
                'UV Index',
                current.uvIndex.toStringAsFixed(0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: AppSpacing.space1),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildHourlyChart(BuildContext context, List<HourlyWeather> hourly) {
    final theme = Theme.of(context);
    final displayHours = hourly.take(12).toList();
    if (displayHours.isEmpty) return const SizedBox.shrink();

    final minTemp = displayHours.map((h) => h.temperature).reduce((a, b) => a < b ? a : b);
    final maxTemp = displayHours.map((h) => h.temperature).reduce((a, b) => a > b ? a : b);
    final tempRange = (maxTemp - minTemp) * 0.3;
    final chartMinY = (minTemp - tempRange).floorToDouble();
    final chartMaxY = (maxTemp + tempRange).ceilToDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.grey,
        ),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (chartMaxY - chartMinY) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.dividerTheme.color ?? Colors.grey,
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
                      style: theme.textTheme.bodySmall,
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
                    style: theme.textTheme.bodySmall,
                  );
                },
                reservedSize: 35,
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
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyForecast(BuildContext context, List<DailyWeather> daily) {
    final theme = Theme.of(context);
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final displayDays = daily.take(7).toList();

    if (displayDays.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.grey,
        ),
      ),
      child: Column(
        children: List.generate(displayDays.length, (index) {
          final day = displayDays[index];
          String dayLabel;
          if (index == 0) {
            dayLabel = 'Today';
          } else if (index == 1) {
            dayLabel = 'Tomorrow';
          } else {
            dayLabel = weekdays[day.time.weekday % 7];
          }

          final conditionIcon = WeatherCodeMapping.getIcon(day.weatherCode, isDay: true);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    dayLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: index == 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  conditionIcon,
                  style: const TextStyle(fontSize: 20),
                ),
                const Spacer(),
                Text(
                  '${day.temperatureMin.toStringAsFixed(0)}°',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Text(
                  '${day.temperatureMax.toStringAsFixed(0)}°C',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSunriseSunsetCard(BuildContext context, DailyWeather today) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.grey,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSunItem(
            context,
            Icons.wb_sunny,
            'Sunrise',
            DateTimeUtils.formatTime(today.sunrise),
          ),
          Container(
            width: 1,
            height: 50,
            color: theme.dividerTheme.color,
          ),
          _buildSunItem(
            context,
            Icons.nightlight_round,
            'Sunset',
            DateTimeUtils.formatTime(today.sunset),
          ),
        ],
      ),
    );
  }

  Widget _buildSunItem(
    BuildContext context,
    IconData icon,
    String label,
    String time,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.space2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          time,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWindCard(BuildContext context, WeatherData data) {
    final theme = Theme.of(context);
    final current = data.current;
    final windDir = _windDirectionFromDegrees(current.windDirection);
    final gustSpeed = data.daily.isNotEmpty
        ? data.daily.first.windGustsMax
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.grey,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Icon(Icons.navigation, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Direction',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                windDir,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 50,
            color: theme.dividerTheme.color,
          ),
          Column(
            children: [
              Icon(Icons.air, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Speed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                '${current.windSpeed.toStringAsFixed(0)} km/h',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 50,
            color: theme.dividerTheme.color,
          ),
          Column(
            children: [
              Icon(Icons.storm, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Gusts',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                gustSpeed > 0
                    ? '${gustSpeed.toStringAsFixed(0)} km/h'
                    : 'N/A',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
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
