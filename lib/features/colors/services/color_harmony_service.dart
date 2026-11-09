import 'dart:math';
import 'package:flutter/material.dart';

/// Supported types of color harmony combinations.
enum ColorHarmonyType {
  complementary('Complementary', 'Opposite color on the color wheel (180°)'),
  triadic('Triadic', '3 evenly spaced colors forming a triangle (120°)'),
  analogous('Analogous', 'Adjacent colors on the wheel (±30°)'),
  splitComplementary('Split-Comp', 'Base color + 2 colors adjacent to its complement (150°, 210°)'),
  tetradic('Tetradic', '4 colors arranged into two complementary pairs (90°)');

  const ColorHarmonyType(this.label, this.description);
  final String label;
  final String description;
}

/// Service that computes professional color harmonies from any base color.
class ColorHarmonyService {
  ColorHarmonyService._();

  /// Calculate harmonious colors based on harmonic geometry on the HSV color wheel.
  static List<Color> getHarmonies(Color baseColor, ColorHarmonyType type) {
    final hsv = HSVColor.fromColor(baseColor);
    final hue = hsv.hue;
    final sat = hsv.saturation.clamp(0.15, 1.0);
    final val = hsv.value.clamp(0.2, 1.0);

    switch (type) {
      case ColorHarmonyType.complementary:
        final compHue = (hue + 180.0) % 360.0;
        return [
          baseColor,
          HSVColor.fromAHSV(1.0, compHue, sat, val).toColor(),
          // Tint & shade variations of the complement
          HSVColor.fromAHSV(1.0, compHue, (sat * 0.6).clamp(0.0, 1.0), min(1.0, val * 1.15)).toColor(),
          HSVColor.fromAHSV(1.0, compHue, min(1.0, sat * 1.2), (val * 0.7).clamp(0.0, 1.0)).toColor(),
        ];

      case ColorHarmonyType.triadic:
        final h1 = (hue + 120.0) % 360.0;
        final h2 = (hue + 240.0) % 360.0;
        return [
          baseColor,
          HSVColor.fromAHSV(1.0, h1, sat, val).toColor(),
          HSVColor.fromAHSV(1.0, h2, sat, val).toColor(),
          HSVColor.fromAHSV(1.0, h1, (sat * 0.6).clamp(0.0, 1.0), val).toColor(),
        ];

      case ColorHarmonyType.analogous:
        final hLeft = (hue - 30.0 + 360.0) % 360.0;
        final hFarLeft = (hue - 60.0 + 360.0) % 360.0;
        final hRight = (hue + 30.0) % 360.0;
        final hFarRight = (hue + 60.0) % 360.0;
        return [
          HSVColor.fromAHSV(1.0, hFarLeft, sat, val).toColor(),
          HSVColor.fromAHSV(1.0, hLeft, sat, val).toColor(),
          baseColor,
          HSVColor.fromAHSV(1.0, hRight, sat, val).toColor(),
          HSVColor.fromAHSV(1.0, hFarRight, sat, val).toColor(),
        ];

      case ColorHarmonyType.splitComplementary:
        final h1 = (hue + 150.0) % 360.0;
        final h2 = (hue + 210.0) % 360.0;
        return [
          baseColor,
          HSVColor.fromAHSV(1.0, h1, sat, val).toColor(),
          HSVColor.fromAHSV(1.0, h2, sat, val).toColor(),
          HSVColor.fromAHSV(1.0, (hue + 180.0) % 360.0, sat * 0.5, val).toColor(),
        ];

      case ColorHarmonyType.tetradic:
        final h1 = (hue + 90.0) % 360.0;
        final h2 = (hue + 180.0) % 360.0;
        final h3 = (hue + 270.0) % 360.0;
        return [
          baseColor,
          HSVColor.fromAHSV(1.0, h1, sat, val).toColor(),
          HSVColor.fromAHSV(1.0, h2, sat, val).toColor(),
          HSVColor.fromAHSV(1.0, h3, sat, val).toColor(),
        ];
    }
  }
}
