import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/alert.dart';
import 'nerv/nerv_styles.dart';

/// A prominent, full-bleed banner used to surface SOS-level disaster
/// alerts fetched from the GDACS pipeline. Demands attention: pulsing
/// icon, full saturation, 3px severity bar on the left edge. Use this
/// only for [SeverityLevel.critical] or [SeverityLevel.emergency]
/// alerts.
class SosAlertBanner extends StatefulWidget {
  final Alert alert;
  final VoidCallback? onTap;

  const SosAlertBanner({super.key, required this.alert, this.onTap});

  @override
  State<SosAlertBanner> createState() => _SosAlertBannerState();
}

class _SosAlertBannerState extends State<SosAlertBanner>
    with SingleTickerProviderStateMixin {
  /// Alert ids that have already produced a haptic this session. The banner
  /// is re-mounted on every tab switch / rebuild, so firing heavyImpact()
  /// straight from initState makes the phone buzz each time the user taps
  /// back to Home — a false "new alert!" alarm. Dedup per id so the buzz
  /// tracks genuine arrivals, not widget lifecycle.
  static final Set<String> _hapticFiredFor = <String>{};

  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.alert.severity == SeverityLevel.critical) {
      _pulse.repeat(reverse: true);
      if (_hapticFiredFor.add(widget.alert.id)) {
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nerv = context.nerv;
    final color = widget.alert.severity.color;
    final isCritical = widget.alert.severity == SeverityLevel.critical;
    final iconOpacity =
        isCritical ? _pulseAnim : const AlwaysStoppedAnimation<double>(1.0);
    final onSurface = nerv.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: nerv.border, width: 1),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 3, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FadeTransition(
                                opacity: iconOpacity,
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'SOS',
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.6,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Flexible so the chip ellipsizes
                                        // instead of overflowing in narrow
                                        // columns (responsive layouts).
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              widget.alert.severity.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Flexible(
                                          child: Text(
                                            _formatTime(widget.alert.issuedTime),
                                            textAlign: TextAlign.end,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: nerv.dataLabel.copyWith(
                                              fontSize: 10,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.alert.headline,
                                      style: TextStyle(
                                        color: onSurface,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (widget.alert.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.alert.description,
                              style: nerv.body.copyWith(fontSize: 12),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (widget.alert.location.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 12,
                                  color: onSurface.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.alert.location,
                                    style: nerv.dataLabel.copyWith(
                                      fontSize: 10,
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)} · ${t.day}/${t.month}';
  }
}
