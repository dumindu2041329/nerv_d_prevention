import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'nerv_styles.dart';

/// The Posture Gauge — the app's signature instrument.
///
/// A six-segment ladder mapping the design system's own severity
/// colours from CALM → CRITICAL, filled up to the current posture with a
/// "now" needle sitting on the active rung. The DMC measures risk in
/// levels, so the whole island's posture is read the same way — as a
/// level on a gauge rather than a card or a gradient.
class PostureGauge extends StatelessWidget {
  final SeverityLevel level;
  final bool compact;

  /// Shows the current posture label to the right of the gauge.
  final bool label;

  const PostureGauge({
    super.key,
    required this.level,
    this.compact = false,
    this.label = true,
  });

  @override
  Widget build(BuildContext context) {
    final nerv = context.nerv;
    final animate = !MediaQuery.disableAnimationsOf(context);
    final ladder = NervStyles.ladder;
    final currentIndex = ladder.indexOf(level).clamp(0, ladder.length - 1);

    final trackHeight = compact ? 6.0 : 10.0;
    final gap = compact ? 2.0 : 4.0;
    final count = ladder.length;

    return Semantics(
      label: 'Risk posture ${level.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label) ...[
            Row(
              children: [
                Expanded(
                  child: Eyebrow('RISK POSTURE', color: nerv.hairline),
                ),
                Text(
                  level.label,
                  style: TextStyle(
                    color: level.color,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 6 : 10),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: trackHeight + (compact ? 0 : 8),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (int i = 0; i < count; i++) ...[
                          if (i > 0) SizedBox(width: gap),
                          Expanded(
                            child: _Segment(
                              height: trackHeight,
                              color: ladder[i].color,
                              reached: i <= currentIndex,
                              animate: animate,
                              key: ValueKey(ladder[i]),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // "now" needle sitting on the active rung.
                    Align(
                      alignment: Alignment(
                        -1.0 + ((currentIndex + 0.5) / count) * 2.0,
                        -1.0,
                      ),
                      child: Container(
                        width: 2,
                        height: compact ? 8 : 12,
                        color: onSurfaceOf(context, level),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color onSurfaceOf(BuildContext context, SeverityLevel level) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F1120);
  }
}

class _Segment extends StatelessWidget {
  final double height;
  final Color color;
  final bool reached;
  final bool animate;

  const _Segment({
    super.key,
    required this.height,
    required this.color,
    required this.reached,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final nerv = context.nerv;
    final fill = reached
        ? color
        : (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFE9ECF5));

    final child = Container(
      height: height,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(height / 2),
        border: reached
            ? null
            : Border.all(color: nerv.border.withValues(alpha: 0.5), width: 1),
      ),
    );

    if (!animate) return child;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      height: height,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(height / 2),
        border: reached
            ? null
            : Border.all(color: nerv.border.withValues(alpha: 0.5), width: 1),
      ),
    );
  }
}
