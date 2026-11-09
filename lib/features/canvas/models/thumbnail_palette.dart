import 'dart:math';
import 'package:flutter/material.dart';

/// A cohesive high-CTR color palette tailored specifically for video thumbnails and social covers.
class ThumbnailColorPalette {
  const ThumbnailColorPalette({
    required this.id,
    required this.name,
    required this.category,
    required this.background1,
    required this.background2,
    required this.headlineColor,
    required this.pillColor,
    required this.accentGlowColor,
    this.isGradient = true,
    required this.ctrScore,
    required this.description,
  });

  final String id;
  final String name;
  final String category;
  final Color background1;
  final Color background2;
  final Color headlineColor;
  final Color pillColor;
  final Color accentGlowColor;
  final bool isGradient;
  final int ctrScore;
  final String description;

  /// The 5 core colors that make up this palette.
  List<Color> get swatches => [
        background1,
        background2,
        headlineColor,
        pillColor,
        accentGlowColor,
      ];

  /// Calculate relative luminance according to WCAG standards.
  static double _calculateLuminance(Color color) {
    double transform(double c) {
      return (c <= 0.03928) ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = transform(color.r);
    final g = transform(color.g);
    final b = transform(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Contrast ratio between the headline color and the primary background.
  double get contrastRatio {
    final lum1 = _calculateLuminance(headlineColor);
    final lum2 = _calculateLuminance(background1);
    final brightest = max(lum1, lum2);
    final darkest = min(lum1, lum2);
    return (brightest + 0.05) / (darkest + 0.05);
  }

  /// User-friendly CTR contrast evaluation label.
  String get contrastRating {
    final ratio = contrastRatio;
    if (ratio >= 12.0) {
      return 'SUPERIOR (${ratio.toStringAsFixed(1)}:1) • High CTR';
    } else if (ratio >= 7.0) {
      return 'HIGH (${ratio.toStringAsFixed(1)}:1) • Great Visibility';
    } else if (ratio >= 4.5) {
      return 'STANDARD (${ratio.toStringAsFixed(1)}:1)';
    } else {
      return 'LOW (${ratio.toStringAsFixed(1)}:1) • Consider Brighter Text';
    }
  }

  ThumbnailColorPalette copyWith({
    String? id,
    String? name,
    String? category,
    Color? background1,
    Color? background2,
    Color? headlineColor,
    Color? pillColor,
    Color? accentGlowColor,
    bool? isGradient,
    int? ctrScore,
    String? description,
  }) {
    return ThumbnailColorPalette(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      background1: background1 ?? this.background1,
      background2: background2 ?? this.background2,
      headlineColor: headlineColor ?? this.headlineColor,
      pillColor: pillColor ?? this.pillColor,
      accentGlowColor: accentGlowColor ?? this.accentGlowColor,
      isGradient: isGradient ?? this.isGradient,
      ctrScore: ctrScore ?? this.ctrScore,
      description: description ?? this.description,
    );
  }

  /// Curated creator color palettes proven to drive high CTR on YouTube, TikTok, and Instagram.
  static const List<ThumbnailColorPalette> curatedPalettes = [
    ThumbnailColorPalette(
      id: 'high_ctr_neon',
      name: 'High-CTR Neon',
      category: 'Viral Trending',
      background1: Color(0xFF0F0C29),
      background2: Color(0xFF24243E),
      headlineColor: Color(0xFFFFE600), // Electric Yellow
      pillColor: Color(0xFFE60023),     // YouTube Brand Red
      accentGlowColor: Color(0xFF00F0FF), // Electric Cyan
      ctrScore: 99,
      description: 'Ultra-high contrast yellow on deep slate with red punchy pill',
    ),
    ThumbnailColorPalette(
      id: 'viral_gaming',
      name: 'Viral Gaming',
      category: 'Gaming & Tech',
      background1: Color(0xFF7B2CBF), // Cyber Purple
      background2: Color(0xFF10002B), // Deep Violet
      headlineColor: Color(0xFF00F5D4), // Neon Mint
      pillColor: Color(0xFFFF007F),     // Hot Pink
      accentGlowColor: Color(0xFF70E000), // Acid Green
      ctrScore: 97,
      description: 'Lethal cyber purple with mint text and hot pink badge',
    ),
    ThumbnailColorPalette(
      id: 'beast_gold',
      name: 'Creator Gold',
      category: 'Top Creators',
      background1: Color(0xFF1E3C72), // Deep Ocean Blue
      background2: Color(0xFF2A5298), // Electric Royal Blue
      headlineColor: Color(0xFFFFD700), // Pure Championship Gold
      pillColor: Color(0xFFFF3366),     // Neon Red/Pink
      accentGlowColor: Color(0xFF00F0FF), // Cyan Aura
      ctrScore: 98,
      description: 'Signature blockbuster creator style: gold headline on dual-blue',
    ),
    ThumbnailColorPalette(
      id: 'cinematic_drama',
      name: 'Cinematic Drama',
      category: 'Action & Story',
      background1: Color(0xFF200122), // Fiery Noir
      background2: Color(0xFF800000), // Crimson Fire
      headlineColor: Color(0xFFFFFFFF), // Crisp White
      pillColor: Color(0xFFD63031),     // Alert Crimson
      accentGlowColor: Color(0xFFFB8500), // Blazing Amber
      ctrScore: 95,
      description: 'Deep crimson noir with crisp white headline and amber glow',
    ),
    ThumbnailColorPalette(
      id: 'clean_creator',
      name: 'Clean Creator',
      category: 'Tech & Lifestyle',
      background1: Color(0xFFFFFFFF), // Pure Snow
      background2: Color(0xFFF1F5F9), // Clean Slate
      headlineColor: Color(0xFF0F172A), // Midnight Carbon
      pillColor: Color(0xFF2563EB),     // Royal Blue
      accentGlowColor: Color(0xFFF43F5E), // Coral
      isGradient: false,
      ctrScore: 92,
      description: 'Minimalist studio look: dark text on crisp background with royal blue pill',
    ),
    ThumbnailColorPalette(
      id: 'toxic_cyberpunk',
      name: 'Toxic Cyberpunk',
      category: 'Cyber & Future',
      background1: Color(0xFF090A0F), // Pitch Black
      background2: Color(0xFF1A102F), // Dark Violet
      headlineColor: Color(0xFF39FF14), // Radioactive Toxic Green
      pillColor: Color(0xFF9D00FF),     // Electric Violet
      accentGlowColor: Color(0xFFFF0055), // Cyber Red
      ctrScore: 96,
      description: 'Pitch black backdrop with radioactive green headline and violet pill',
    ),
    ThumbnailColorPalette(
      id: 'sunset_action',
      name: 'Sunset Horizon',
      category: 'Vlog & Travel',
      background1: Color(0xFFFF416C), // Sunset Rose
      background2: Color(0xFFFF4B2B), // Hot Coral
      headlineColor: Color(0xFFFFFFFF), // Crisp White
      pillColor: Color(0xFF1E272E),     // Charcoal Pill
      accentGlowColor: Color(0xFFFFE600), // Solar Gold
      ctrScore: 94,
      description: 'Warm, intense sunset gradient with crisp white typography',
    ),
    ThumbnailColorPalette(
      id: 'oled_mystery',
      name: 'OLED Mystery',
      category: 'Horror & Mystery',
      background1: Color(0xFF0A0A12), // Deep OLED Void
      background2: Color(0xFF141424), // Midnight Shadow
      headlineColor: Color(0xFF00FF88), // Radioactive Mint
      pillColor: Color(0xFFFF2A6D),     // Neon Warning
      accentGlowColor: Color(0xFF05D9E8), // Cyber Aqua
      ctrScore: 95,
      description: 'Pitch dark mystery with glowing radioactive text and neon warning pill',
    ),
  ];
}
