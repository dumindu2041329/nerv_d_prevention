import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/alert.dart';

/// A prominent, full-bleed banner used to surface SOS-level disaster
/// alerts fetched from the GDACS pipeline. Designed to demand
/// attention: pulsing icon, full saturation, bordered with a 4px
/// severity-coloured stripe. Use this only for [SeverityLevel.critical]
/// or [SeverityLevel.emergency] alerts — the regular [AlertBanner] is
/// fine for everything else.
class SosAlertBanner extends StatefulWidget {
  final Alert alert;
  final VoidCallback? onTap;

  const SosAlertBanner({super.key, required this.alert, this.onTap});

  @override
  State<SosAlertBanner> createState() => _SosAlertBannerState();
}

class _SosAlertBannerState extends State<SosAlertBanner>
    with SingleTickerProviderStateMixin {
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
      // Subtle haptic nudge so a user who hasn't yet looked at the
      // screen is alerted. Cheap to fire once at mount.
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.alert.severity.color;
    final isCritical = widget.alert.severity == SeverityLevel.critical;
    final iconOpacity =
        isCritical ? _pulseAnim : const AlwaysStoppedAnimation<double>(1.0);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: color, width: 4),
                top: BorderSide(
                  color: color.withValues(alpha: 0.4),
                  width: 0.5,
                ),
                right: BorderSide(
                  color: color.withValues(alpha: 0.4),
                  width: 0.5,
                ),
                bottom: BorderSide(
                  color: color.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FadeTransition(
                        opacity: iconOpacity,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: color,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.alert.severity.label,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTime(widget.alert.issuedTime),
                                  style: TextStyle(
                                    color: onSurface.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.alert.headline,
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
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
                          color: onSurface.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.alert.location,
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.7),
                              fontSize: 11,
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
        ),
      ),
    );
  }

  static String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)} ${t.day}/${t.month}';
  }
}
