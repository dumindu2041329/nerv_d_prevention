import 'package:flutter/material.dart';

class StaleDataBanner extends StatelessWidget {
  final DateTime lastUpdated;

  const StaleDataBanner({
    super.key,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.update, size: 14, color: accent),
          const SizedBox(width: 8),
          Text(
            'STALE DATA · ${_formatLastUpdated()}',
            style: TextStyle(
              color: accent,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
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
      return 'JUST NOW';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}M AGO';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}H AGO';
    } else {
      return '${diff.inDays}D AGO';
    }
  }
}
