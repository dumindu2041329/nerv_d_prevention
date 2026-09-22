import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'island_mark.dart';
import 'nerv_styles.dart';

/// Live 24h clock rendered as tabular data. Updates every second.
class LiveClock extends StatefulWidget {
  final TextStyle? style;

  const LiveClock({super.key, this.style});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (animate && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    } else if (!animate && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nerv = context.nerv;
    return Text(
      NervStyles.formatClock(_now),
      style: widget.style ??
          nerv.numeral(size: 13, weight: FontWeight.w400).copyWith(
            color: nerv.onSurface.withValues(alpha: 0.75),
            letterSpacing: 1.5,
          ),
    );
  }
}

/// Top "monitoring deck" header used on non-map screens.
///
/// Structure: a live-status eyebrow row (island mark + mission + clock),
/// an optional headline, and a 2px severity state line tying the whole
/// screen to the current posture colour.
class DeckHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final SeverityLevel posture;

  /// Overrides the default eyebrow text (`SRI LANKA · LIVE`).
  final String? eyebrowText;

  const DeckHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.posture = SeverityLevel.calm,
    this.eyebrowText,
  });

  @override
  Widget build(BuildContext context) {
    final nerv = context.nerv;
    final accent = posture.color;

    return Container(
      decoration: BoxDecoration(
        color: nerv.surface,
        border: Border(bottom: BorderSide(color: nerv.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                IslandMark(color: nerv.onSurface.withValues(alpha: 0.65)),
                const SizedBox(width: 8),
                Expanded(
                  child: Eyebrow(
                    eyebrowText ?? 'SRI LANKA · ${nerv.monsoon.name.toUpperCase()}',
                    color: nerv.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                LiveClock(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: nerv.headline.copyWith(fontSize: 22)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: nerv.dataLabel.copyWith(fontSize: 12)),
                ],
              ],
            ),
          ),
          // State line — full-width severity colour.
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            height: 2,
            color: accent,
          ),
        ],
      ),
    );
  }
}
