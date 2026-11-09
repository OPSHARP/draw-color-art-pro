import 'package:flutter/material.dart';

/// Types of classic color wheel harmonies.
enum HarmonyType {
  complementary('Complementary', 'Opposite on the color wheel (180°)'),
  analogous('Analogous', 'Adjacent colors on the wheel (±30°)'),
  triadic('Triadic', 'Three equidistant colors (120°)'),
  splitComplementary('Split-Comp', 'Base and two colors flanking its complement (150°, 210°)'),
  tetradic('Tetradic', 'Rectangle scheme of two complementary pairs (90°, 180°, 270°)'),
  monochromatic('Monochromatic', 'Variations in lightness and saturation of the same hue');

  const HarmonyType(this.label, this.description);
  final String label;
  final String description;
}

/// Helper class to compute artistic color wheel harmonies from an active HSV color.
class ColorHarmonies {
  ColorHarmonies._();

  /// Calculate colors according to the specified harmony type.
  static List<Color> compute(Color baseColor, HarmonyType type) {
    final hsv = HSVColor.fromColor(baseColor);
    final hue = hsv.hue;
    final sat = hsv.saturation.clamp(0.2, 1.0);
    final val = hsv.value.clamp(0.25, 1.0);

    switch (type) {
      case HarmonyType.complementary:
        return [
          baseColor,
          _hsvColor((hue + 180) % 360, sat, val),
        ];

      case HarmonyType.analogous:
        return [
          _hsvColor((hue - 30 + 360) % 360, sat, val),
          baseColor,
          _hsvColor((hue + 30) % 360, sat, val),
        ];

      case HarmonyType.triadic:
        return [
          baseColor,
          _hsvColor((hue + 120) % 360, sat, val),
          _hsvColor((hue + 240) % 360, sat, val),
        ];

      case HarmonyType.splitComplementary:
        return [
          baseColor,
          _hsvColor((hue + 150) % 360, sat, val),
          _hsvColor((hue + 210) % 360, sat, val),
        ];

      case HarmonyType.tetradic:
        return [
          baseColor,
          _hsvColor((hue + 90) % 360, sat, val),
          _hsvColor((hue + 180) % 360, sat, val),
          _hsvColor((hue + 270) % 360, sat, val),
        ];

      case HarmonyType.monochromatic:
        return [
          _hsvColor(hue, (sat * 0.3).clamp(0.05, 1.0), (val * 1.1).clamp(0.0, 1.0)),
          _hsvColor(hue, (sat * 0.6).clamp(0.1, 1.0), val),
          baseColor,
          _hsvColor(hue, sat, (val * 0.7).clamp(0.1, 1.0)),
          _hsvColor(hue, sat, (val * 0.4).clamp(0.05, 1.0)),
        ];
    }
  }

  static Color _hsvColor(double h, double s, double v) {
    return HSVColor.fromAHSV(1.0, h.clamp(0.0, 360.0), s.clamp(0.0, 1.0), v.clamp(0.0, 1.0)).toColor();
  }
}
