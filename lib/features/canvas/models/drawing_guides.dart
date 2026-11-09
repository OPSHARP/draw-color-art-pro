import 'package:flutter/material.dart';

/// Supported types of drawing and perspective guides.
enum DrawingGuideType {
  none('None', 'No guide overlay'),
  grid2D('2D Grid', 'Standard cartesian square grid'),
  isometric('Isometric', '30° isometric diamond grid for 3D & game art'),
  perspective1P('1-Point Perspective', 'One central vanishing point with radiating horizon rays'),
  perspective2P('2-Point Perspective', 'Two vanishing points on horizon for architectural drawing'),
  perspective3P('3-Point Perspective', 'Three vanishing points for dramatic aerial/worm-eye views'),
  thumbnailSafeZone('Thumbnail Safe Zone', 'YouTube timestamp badge warning, 5% edge margins & rule of thirds'),
  ruleOfThirds('Rule of Thirds', '3×3 composition grid for thumbnail subject framing');

  const DrawingGuideType(this.label, this.description);
  final String label;
  final String description;
}

/// Configuration for drawing and perspective guide overlays.
class DrawingGuideConfig {
  const DrawingGuideConfig({
    this.type = DrawingGuideType.none,
    this.spacing = 32.0,
    this.opacity = 0.35,
    this.color = const Color(0xFF6C5CE7),
    this.horizonRatio = 0.5,
    this.vp1Ratio = 0.5,
    this.vp2Ratio = 0.85,
    this.vp3Ratio = 0.15,
    this.rayCount = 14,
    this.snapToGuide = false,
  });

  final DrawingGuideType type;
  final double spacing;
  final double opacity;
  final Color color;
  final double horizonRatio; // 0.0 top .. 1.0 bottom
  final double vp1Ratio;     // 0.0 left .. 1.0 right
  final double vp2Ratio;     // 0.0 left .. 1.0 right
  final double vp3Ratio;     // 0.0 top .. 1.0 bottom
  final int rayCount;
  final bool snapToGuide;

  bool get isEnabled => type != DrawingGuideType.none;

  DrawingGuideConfig copyWith({
    DrawingGuideType? type,
    double? spacing,
    double? opacity,
    Color? color,
    double? horizonRatio,
    double? vp1Ratio,
    double? vp2Ratio,
    double? vp3Ratio,
    int? rayCount,
    bool? snapToGuide,
  }) {
    return DrawingGuideConfig(
      type: type ?? this.type,
      spacing: spacing ?? this.spacing,
      opacity: opacity ?? this.opacity,
      color: color ?? this.color,
      horizonRatio: horizonRatio ?? this.horizonRatio,
      vp1Ratio: vp1Ratio ?? this.vp1Ratio,
      vp2Ratio: vp2Ratio ?? this.vp2Ratio,
      vp3Ratio: vp3Ratio ?? this.vp3Ratio,
      rayCount: rayCount ?? this.rayCount,
      snapToGuide: snapToGuide ?? this.snapToGuide,
    );
  }
}
