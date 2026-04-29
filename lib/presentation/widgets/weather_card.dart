import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../domain/entities/weather_data.dart';
import '../../core/utils/string_utils.dart';

class WeatherCard extends StatelessWidget {
  final CurrentWeather weather;
  final String locationName;
  final VoidCallback? onTap;

  const WeatherCard({
    super.key,
    required this.weather,
    required this.locationName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weatherCode = weather.weatherCode;
    final weatherIcon = WeatherCodeMapping.getIcon(weatherCode);
    final weatherDesc = WeatherCodeMapping.getDescription(weatherCode);

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: AppSpacing.space1),
                Expanded(
                  child: Text(
                    locationName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weatherIcon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        StringUtils.formatTemperature(weather.temperature, showUnit: false),
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        weatherDesc,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        'Feels like ${StringUtils.formatTemperature(weather.apparentTemperature)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.space4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  context,
                  Icons.water_drop_outlined,
                  'Humidity',
                  StringUtils.formatPercentage(weather.humidity),
                ),
                _buildInfoItem(
                  context,
                  Icons.air,
                  'Wind',
                  StringUtils.formatWindSpeed(weather.windSpeed),
                ),
                _buildInfoItem(
                  context,
                  Icons.umbrella_outlined,
                  'Rain',
                  StringUtils.formatPrecipitation(weather.precipitation),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
