import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/constants.dart';

class AppTheme {
  static const Color _colorBgPrimaryDark = Color(0xFF0A0C10);
  static const Color _colorBgSurfaceDark = Color(0xFF12151C);
  static const Color _colorBgElevatedDark = Color(0xFF1A1E29);
  static const Color _colorBgOverlayDark = Color(0xFF232836);
  static const Color _colorBorderDefault = Color(0xFF2A2F3E);
  static const Color _colorBorderSubtle = Color(0xFF1E2230);
  static const Color _colorAccentPrimary = Color(0xFFFF6B00);
  static const Color _colorAccentSecondary = Color(0xFFFF9500);
  static const Color _colorTextPrimary = Color(0xFFF0F2F8);
  static const Color _colorTextSecondary = Color(0xFF8B95B0);
  static const Color _colorTextTertiary = Color(0xFF4A5270);

  static const Color _colorBgPrimaryLight = Color(0xFFF4F6FA);
  static const Color _colorBgSurfaceLight = Color(0xFFFFFFFF);
  static const Color _colorBgElevatedLight = Color(0xFFEEF0F6);
  static const Color _colorBorderDefaultLight = Color(0xFFD0D5E8);
  static const Color _colorTextPrimaryLight = Color(0xFF0F1120);
  static const Color _colorTextSecondaryLight = Color(0xFF5A6280);

  static ThemeData darkTheme({
    ColourVisionMode visionMode = ColourVisionMode.normal,
    ContrastMode contrast = ContrastMode.normal,
    TextSizeScale textSizeScale = TextSizeScale.normal,
    FontWeightScale fontWeightScale = FontWeightScale.normal,
  }) {
    final adjustedAccentPrimary = _getAccentColor(visionMode, _colorAccentPrimary);
    final adjustedSeverityColors = _getAdjustedSeverityColors(visionMode);

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: _colorBgPrimaryDark,
      colorScheme: ColorScheme.dark(
        primary: adjustedAccentPrimary,
        secondary: _colorAccentSecondary,
        surface: _colorBgSurfaceDark,
        error: adjustedSeverityColors[SeverityLevel.critical] ?? const Color(0xFFFF1744),
        onPrimary: _colorTextPrimary,
        onSecondary: _colorTextPrimary,
        onSurface: _colorTextPrimary,
        onError: _colorTextPrimary,
      ),
      textTheme: _buildTextTheme(
        textSizeScale,
        fontWeightScale,
        _colorTextPrimary,
        _colorTextSecondary,
        _colorTextTertiary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _colorBgPrimaryDark,
        foregroundColor: _colorTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20 * textSizeScale.multiplier,
          fontWeight: FontWeight.w600,
          color: _colorTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: _colorBgSurfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: _colorBorderDefault),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _colorBgSurfaceDark,
        indicatorColor: adjustedAccentPrimary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12 * textSizeScale.multiplier,
              fontWeight: FontWeight.w500,
              color: adjustedAccentPrimary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12 * textSizeScale.multiplier,
            fontWeight: FontWeight.w500,
            color: _colorTextTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: adjustedAccentPrimary, size: 24);
          }
          return IconThemeData(color: _colorTextTertiary, size: 24);
        }),
      ),
      iconTheme: const IconThemeData(
        color: _colorTextSecondary,
        size: 24,
      ),
      dividerTheme: const DividerThemeData(
        color: _colorBorderSubtle,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _colorBgElevatedDark,
        labelStyle: GoogleFonts.inter(
          fontSize: 11 * textSizeScale.multiplier,
          fontWeight: FontWeight.w500,
          color: _colorTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
      ),
    );
  }

  static ThemeData lightTheme({
    TextSizeScale textSizeScale = TextSizeScale.normal,
    FontWeightScale fontWeightScale = FontWeightScale.normal,
  }) {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: _colorBgPrimaryLight,
      colorScheme: ColorScheme.light(
        primary: _colorAccentPrimary,
        secondary: _colorAccentSecondary,
        surface: _colorBgSurfaceLight,
        error: const Color(0xFFFF1744),
        onPrimary: _colorTextPrimary,
        onSecondary: _colorTextPrimary,
        onSurface: _colorTextPrimaryLight,
        onError: _colorTextPrimary,
      ),
      textTheme: _buildTextTheme(
        textSizeScale,
        fontWeightScale,
        _colorTextPrimaryLight,
        _colorTextSecondaryLight,
        _colorTextSecondaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _colorBgPrimaryLight,
        foregroundColor: _colorTextPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20 * textSizeScale.multiplier,
          fontWeight: FontWeight.w600,
          color: _colorTextPrimaryLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: _colorBgSurfaceLight,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: _colorBorderDefaultLight),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _colorBgSurfaceLight,
        indicatorColor: _colorAccentPrimary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12 * textSizeScale.multiplier,
              fontWeight: FontWeight.w500,
              color: _colorAccentPrimary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12 * textSizeScale.multiplier,
            fontWeight: FontWeight.w500,
            color: _colorTextSecondaryLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: _colorAccentPrimary, size: 24);
          }
          return IconThemeData(color: _colorTextSecondaryLight, size: 24);
        }),
      ),
      iconTheme: const IconThemeData(
        color: _colorTextSecondaryLight,
        size: 24,
      ),
      dividerTheme: const DividerThemeData(
        color: _colorBorderDefaultLight,
        thickness: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme(
    TextSizeScale textSizeScale,
    FontWeightScale fontWeightScale,
    Color primaryColor,
    Color secondaryColor,
    Color tertiaryColor,
  ) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 32 * textSizeScale.multiplier,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 40 / 32,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28 * textSizeScale.multiplier,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 36 / 28,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24 * textSizeScale.multiplier,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 32 / 24,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24 * textSizeScale.multiplier,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 32 / 24,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20 * textSizeScale.multiplier,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 28 / 20,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 17 * textSizeScale.multiplier,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 24 / 17,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16 * textSizeScale.multiplier,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 24 / 16,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14 * textSizeScale.multiplier,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 20 / 14,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 12 * textSizeScale.multiplier,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 18 / 12,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16 * textSizeScale.multiplier,
        fontWeight: fontWeightScale.weight,
        color: primaryColor,
        height: 24 / 16,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14 * textSizeScale.multiplier,
        fontWeight: fontWeightScale.weight,
        color: secondaryColor,
        height: 20 / 14,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12 * textSizeScale.multiplier,
        fontWeight: fontWeightScale.weight,
        color: secondaryColor,
        height: 18 / 12,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14 * textSizeScale.multiplier,
        fontWeight: FontWeight.w500,
        color: primaryColor,
        height: 20 / 14,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12 * textSizeScale.multiplier,
        fontWeight: FontWeight.w500,
        color: primaryColor,
        height: 16 / 12,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11 * textSizeScale.multiplier,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        height: 16 / 11,
      ),
    );
  }

  static Color _getAccentColor(ColourVisionMode mode, Color defaultColor) {
    switch (mode) {
      case ColourVisionMode.protanopiaDeuteranopia:
        return const Color(0xFF0072B2);
      case ColourVisionMode.tritanopia:
        return const Color(0xFF009E73);
      case ColourVisionMode.normal:
        return defaultColor;
    }
  }

  static Map<SeverityLevel, Color> _getAdjustedSeverityColors(ColourVisionMode mode) {
    switch (mode) {
      case ColourVisionMode.protanopiaDeuteranopia:
        return {
          SeverityLevel.critical: const Color(0xFF0072B2),
          SeverityLevel.info: const Color(0xFFE69F00),
        };
      case ColourVisionMode.tritanopia:
        return {
          SeverityLevel.advisory: const Color(0xFFCC79A7),
          SeverityLevel.calm: const Color(0xFF009E73),
        };
      case ColourVisionMode.normal:
        return {};
    }
  }
}
