import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../domain/entities/alert.dart';
import '../../core/utils/date_time_utils.dart';

class AlertBanner extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;

  const AlertBanner({
    super.key,
    required this.alert,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = alert.severity.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space3),
        decoration: BoxDecoration(
          color: severityColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border(
            left: BorderSide(color: severityColor, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Row(
            children: [
              Icon(
                _getIconForAlertType(alert.type),
                color: severityColor,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space2,
                            vertical: AppSpacing.space1,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                          child: Text(
                            alert.severity.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: severityColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateTimeUtils.formatTime(alert.issuedTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      alert.headline,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (alert.location.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        alert.location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForAlertType(String type) {
    switch (type.toLowerCase()) {
      case 'earthquake':
        return Icons.vibration;
      case 'tsunami':
        return Icons.waves;
      case 'volcano':
        return Icons.local_fire_department;
      case 'rain':
      case 'flood':
        return Icons.water_drop;
      case 'wind':
        return Icons.air;
      case 'storm':
        return Icons.thunderstorm;
      case 'j-alert':
        return Icons.campaign;
      default:
        return Icons.warning;
    }
  }
}
