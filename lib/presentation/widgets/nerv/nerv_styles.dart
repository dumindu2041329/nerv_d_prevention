
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sl_constants.dart';

/// Shared "operations deck" typographic + structural tokens.
///
/// The whole app is treated as one live monitoring instrument for Sri
/// Lanka. Everything derives from the design system's own palette
/// (severity ladder, cyan accent, pure-black canvas, Inter) but the
/// register is data-first: thin tabular numerals for any number, tiny
/// tracked-uppercase labels for structure, and hairlines for
/// separation.
class NervStyles {
  final BuildContext context;
  NervStyles(this.context);

  ThemeData get _t => Theme.of(context);
  ColorScheme get _c => _t.colorScheme;

  Color get onSurface => _c.onSurface;
  Color get surface => _c.surface;

  /// 1px rule used to separate console bands.
  Color get hairline =>
      _t.dividerTheme.color ?? const Color(0xFF1E1E1E);

  /// 1px card/control border.
  Color get border => const Color(0xFF2A2A2A);

  /// Structural label — tiny, tracked, uppercase.
  TextStyle get eyebrow => TextStyle(
        color: onSurface.withValues(alpha: 0.55),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.8,
        height: 1.2,
      );

  /// Big data numeral (temps, levels, clocks).
  TextStyle numeral({double size = 40, FontWeight weight = FontWeight.w200}) =>
      TextStyle(
        color: onSurface,
        fontSize: size,
        fontWeight: weight,
        height: 1.0,
        letterSpacing: -1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Mid-size data numeral used inside readout tiles.
  TextStyle numeralSmall({double size = 15}) =>
      numeral(size: size, weight: FontWeight.w500);

  /// Mission / band title.
  TextStyle get headline => TextStyle(
        color: onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
      );

  /// Field label inside a readout (not uppercase, sits next to data).
  TextStyle get dataLabel => TextStyle(
        color: onSurface.withValues(alpha: 0.5),
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      );

  /// Secondary supporting text.
  TextStyle get body => TextStyle(
        color: onSurface.withValues(alpha: 0.7),
        fontSize: 13,
        height: 1.45,
      );

  /// Current monsoon season, derived from today's date.
  SLMonsoon get monsoon => SLMonsoon.current(DateTime.now());

  /// Severity ladder ordered from calm → critical (gauge reading order).
  static const List<SeverityLevel> ladder = [
    SeverityLevel.calm,
    SeverityLevel.info,
    SeverityLevel.advisory,
    SeverityLevel.warning,
    SeverityLevel.emergency,
    SeverityLevel.critical,
  ];

  /// Overall posture = highest severity present (most dangerous wins).
  static SeverityLevel postureOf(List<SeverityLevel> severities) {
    var result = SeverityLevel.calm;
    for (final s in severities) {
      if (ladder.indexOf(s) > ladder.indexOf(result)) result = s;
    }
    return result;
  }

  static String two(int n) => n.toString().padLeft(2, '0');

  /// 24h clock, e.g. `21:47:08`. Uses tabular figures.
  static String formatClock(DateTime t) =>
      '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';

  static String formatClockShort(DateTime t) => '${two(t.hour)}:${two(t.minute)}';
}

extension NervStylesX on BuildContext {
  NervStyles get nerv => NervStyles(this);
}

/// Reusable tiny tracked-uppercase label.
class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;

  const Eyebrow(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.nerv.eyebrow.copyWith(color: color),
    );
  }
}
