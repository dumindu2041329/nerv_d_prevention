import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';

class StaleDataBanner extends StatelessWidget {
  final DateTime lastUpdated;

  const StaleDataBanner({
    super.key,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.update,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.space2),
          Text(
            'Last updated: ${_formatLastUpdated()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated() {
    final now = DateTime.now();
    final diff = now.difference(lastUpdated);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
