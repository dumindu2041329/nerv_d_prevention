import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../domain/entities/weather_data.dart';
import '../../core/utils/string_utils.dart';
import '../../core/utils/date_time_utils.dart';

class ForecastCard extends StatelessWidget {
  final List<DailyWeather> dailyForecast;

  const ForecastCard({
    super.key,
    required this.dailyForecast,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '予報 / Forecast',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          ...dailyForecast.map((day) => _buildDayRow(context, day)),
        ],
      ),
    );
  }

  Widget _buildDayRow(BuildContext context, DailyWeather day) {
    final theme = Theme.of(context);
    final isToday = _isToday(day.time);
    final weatherIcon = WeatherCodeMapping.getIcon(day.weatherCode);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              isToday ? '今日' : DateTimeUtils.formatDayOfWeekShort(day.time),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                color: isToday
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            weatherIcon,
            style: const TextStyle(fontSize: 18),
          ),
          const Spacer(),
          Text(
            '${StringUtils.formatTemperature(day.temperatureMin, showUnit: false)}°',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          _buildTemperatureBar(context, day),
          const SizedBox(width: AppSpacing.space2),
          Text(
            '${StringUtils.formatTemperature(day.temperatureMax, showUnit: false)}°',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureBar(BuildContext context, DailyWeather day) {
    final theme = Theme.of(context);
    const minTemp = 15.0;
    const maxTemp = 40.0;
    const barWidth = 60.0;

    final lowPos = ((day.temperatureMin - minTemp) / (maxTemp - minTemp) * barWidth).clamp(0.0, barWidth);
    final highPos = ((day.temperatureMax - minTemp) / (maxTemp - minTemp) * barWidth).clamp(0.0, barWidth);

    return SizedBox(
      width: barWidth,
      child: Stack(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Positioned(
            left: lowPos,
            child: Container(
              width: (highPos - lowPos).clamp(4.0, barWidth),
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.5),
                    theme.colorScheme.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
