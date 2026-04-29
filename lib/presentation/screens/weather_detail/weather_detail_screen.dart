import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/weather_data.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/utils/date_time_utils.dart';

class WeatherDetailScreen extends StatelessWidget {
  const WeatherDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentConditions(context),
            const SizedBox(height: AppSpacing.space6),
            _buildSectionTitle(context, 'Hourly Forecast'),
            const SizedBox(height: AppSpacing.space4),
            _buildHourlyChart(context),
            const SizedBox(height: AppSpacing.space6),
            _buildSectionTitle(context, '7-Day Forecast'),
            const SizedBox(height: AppSpacing.space4),
            _buildDailyForecast(context),
            const SizedBox(height: AppSpacing.space6),
            _buildSectionTitle(context, 'Sunrise & Sunset'),
            const SizedBox(height: AppSpacing.space4),
            _buildSunriseSunsetCard(context),
            const SizedBox(height: AppSpacing.space6),
            _buildSectionTitle(context, 'Wind Details'),
            const SizedBox(height: AppSpacing.space4),
            _buildWindCard(context),
            const SizedBox(height: AppSpacing.space8),
          ],
        ),
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

  Widget _buildCurrentConditions(BuildContext context) {
    final theme = Theme.of(context);
    final weatherIcon = WeatherCodeMapping.getIcon(3);
    final weatherDesc = WeatherCodeMapping.getDescription(3);

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
            '28°C',
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
            'Feels like 32°C',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildConditionItem(Icons.water_drop_outlined, 'Humidity', '72%'),
              _buildConditionItem(Icons.air, 'Wind', '12 km/h'),
              _buildConditionItem(Icons.umbrella_outlined, 'Precip', '0 mm'),
              _buildConditionItem(Icons.wb_sunny_outlined, 'UV Index', '8'),
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
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildHourlyChart(BuildContext context) {
    final theme = Theme.of(context);

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
            horizontalInterval: 10,
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
                getTitlesWidget: (value, meta) {
                  const hours = ['Now', '1h', '2h', '3h', '4h', '5h', '6h'];
                  if (value.toInt() < hours.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        hours[value.toInt()],
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
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
          maxX: 6,
          minY: 20,
          maxY: 40,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 28),
                FlSpot(1, 29),
                FlSpot(2, 30),
                FlSpot(3, 31),
                FlSpot(4, 30),
                FlSpot(5, 29),
                FlSpot(6, 28),
              ],
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

  Widget _buildDailyForecast(BuildContext context) {
    final theme = Theme.of(context);

    final days = ['Today', 'Tomorrow', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final icons = ['28°C', '30°C', '27°C', '32°C', '29°C', '31°C', '26°C'];
    final conditions = ['☀️', '⛅', '🌧️', '⛅', '🌩️', '⛅', '☀️'];
    final lows = ['24°', '23°', '22°', '24°', '23°', '22°', '21°'];

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
        children: List.generate(7, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    days[index],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: index == 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  conditions[index],
                  style: const TextStyle(fontSize: 20),
                ),
                const Spacer(),
                Text(
                  lows[index],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Text(
                  icons[index],
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

  Widget _buildSunriseSunsetCard(BuildContext context) {
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
            '06:02',
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
            '18:23',
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

  Widget _buildWindCard(BuildContext context) {
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
                'SW',
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
                '12 km/h',
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
                '18 km/h',
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
}
