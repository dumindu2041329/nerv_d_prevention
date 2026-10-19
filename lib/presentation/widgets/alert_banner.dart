import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../domain/entities/alert.dart';
import '../../core/utils/date_time_utils.dart';
import 'sos_alert_banner.dart';

/// Splits [alerts] into the correct banner chrome: the pulsing SOS
/// treatment is reserved for Critical/Emergency (its documented
/// contract), everything else renders through the calm AlertBanner.
/// Sorted most-severe-first within each tier.
List<Widget> alertBannerWidgets(List<Alert> alerts) {
  int bySeverity(Alert a, Alert b) => a.severity.index.compareTo(b.severity.index);
  final sos = alerts
      .where(
        (a) =>
            a.severity == SeverityLevel.critical ||
            a.severity == SeverityLevel.emergency,
      )
      .toList()
    ..sort(bySeverity);
  final other = alerts
      .where(
        (a) =>
            a.severity != SeverityLevel.critical &&
            a.severity != SeverityLevel.emergency,
      )
      .toList()
    ..sort(bySeverity);
  return <Widget>[
    ...sos.map((a) => SosAlertBanner(alert: a)),
    ...other.map((a) => AlertBanner(alert: a)),
  ];
}

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
      case 'flood':
        return Icons.water_drop;
      case 'landslide':
        return Icons.terrain;
      case 'cyclone':
        return Icons.storm;
      case 'lightning':
        return Icons.bolt;
      case 'coastalwarning':
      case 'coastal':
        return Icons.waves;
      case 'tsunami':
        return Icons.tsunami;
      case 'earthquake':
        return Icons.vibration;
      default:
        return Icons.warning;
    }
  }
}
