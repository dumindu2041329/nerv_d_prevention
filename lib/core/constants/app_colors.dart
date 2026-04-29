import 'package:flutter/material.dart';

enum SeverityLevel {
  critical,
  emergency,
  warning,
  advisory,
  info,
  calm;

  Color get color {
    switch (this) {
      case SeverityLevel.critical:
        return const Color(0xFFFF1744);
      case SeverityLevel.emergency:
        return const Color(0xFFFF6D00);
      case SeverityLevel.warning:
        return const Color(0xFFFFC400);
      case SeverityLevel.advisory:
        return const Color(0xFF00E5FF);
      case SeverityLevel.info:
        return const Color(0xFF69F0AE);
      case SeverityLevel.calm:
        return const Color(0xFF42A5F5);
    }
  }

  String get label {
    switch (this) {
      case SeverityLevel.critical:
        return 'CRITICAL';
      case SeverityLevel.emergency:
        return 'EMERGENCY';
      case SeverityLevel.warning:
        return 'WARNING';
      case SeverityLevel.advisory:
        return 'ADVISORY';
      case SeverityLevel.info:
        return 'INFO';
      case SeverityLevel.calm:
        return 'CALM';
    }
  }
}

enum ColourVisionMode {
  normal,
  protanopiaDeuteranopia,
  tritanopia;

  String get label {
    switch (this) {
      case ColourVisionMode.normal:
        return 'Normal';
      case ColourVisionMode.protanopiaDeuteranopia:
        return 'P/D';
      case ColourVisionMode.tritanopia:
        return 'T';
    }
  }
}

enum ContrastMode {
  low,
  normal,
  high;

  String get label {
    switch (this) {
      case ContrastMode.low:
        return 'Low';
      case ContrastMode.normal:
        return 'Normal';
      case ContrastMode.high:
        return 'High';
    }
  }
}

enum TextSizeScale {
  xSmall,
  small,
  normal,
  large,
  xLarge,
  xxLarge;

  double get multiplier {
    switch (this) {
      case TextSizeScale.xSmall:
        return 0.75;
      case TextSizeScale.small:
        return 0.875;
      case TextSizeScale.normal:
        return 1.0;
      case TextSizeScale.large:
        return 1.125;
      case TextSizeScale.xLarge:
        return 1.25;
      case TextSizeScale.xxLarge:
        return 1.5;
    }
  }

  String get label {
    switch (this) {
      case TextSizeScale.xSmall:
        return 'XS';
      case TextSizeScale.small:
        return 'S';
      case TextSizeScale.normal:
        return 'Normal';
      case TextSizeScale.large:
        return 'L';
      case TextSizeScale.xLarge:
        return 'XL';
      case TextSizeScale.xxLarge:
        return 'XXL';
    }
  }
}

enum FontWeightScale {
  normal,
  medium,
  bold;

  FontWeight get weight {
    switch (this) {
      case FontWeightScale.normal:
        return FontWeight.w400;
      case FontWeightScale.medium:
        return FontWeight.w500;
      case FontWeightScale.bold:
        return FontWeight.w700;
    }
  }
}
