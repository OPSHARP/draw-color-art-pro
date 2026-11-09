import 'dart:math';
import 'package:flutter/material.dart';
import '../../canvas/models/canvas_document.dart';
import '../../canvas/models/stroke.dart';
import '../../brushes/default_brushes.dart';

/// Preset vector line-art templates for coloring books.
class ColoringTemplate {
  const ColoringTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.strokeGenerator,
    this.difficulty = 'Medium',
    this.seed = 0,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final List<Stroke> Function(double width, double height) strokeGenerator;
  final String difficulty;
  final int seed;

  /// Creates a ready-to-color CanvasDocument with locked line art and an active coloring layer.
  CanvasDocument createDocument({int width = 2048, int height = 2048}) {
    final strokes = strokeGenerator(width.toDouble(), height.toDouble());

    final coloringLayer = LayerModel(
      name: 'Color Layer',
      type: LayerType.paint,
      opacity: 1.0,
      blendMode: DrawBlendMode.normal,
    );

    final lineArtLayer = LayerModel(
      name: 'Line Art (Locked)',
      type: LayerType.lineArt,
      opacity: 1.0,
      blendMode: DrawBlendMode.multiply,
      isLocked: true,
      strokes: strokes,
    );

    return CanvasDocument(
      name: title,
      width: width,
      height: height,
      backgroundColor: Colors.white,
      layers: [coloringLayer, lineArtLayer],
      activeLayerIndex: 0, // Users immediately start coloring on the color layer!
    );
  }
}

/// Curated library of 100% free coloring templates.
class ColoringTemplates {
  ColoringTemplates._();

  static final BrushPreset _lineBrush = DefaultBrushes.hardBrush.copyWith(
    size: 4.0,
    opacity: 1.0,
    hardness: 1.0,
  );

  static const Color _lineColor = Color(0xFF1E293B);

  /// Helper to convert list of offsets into a Stroke
  static Stroke _makeStroke(List<Offset> points, {double size = 4.0}) {
    final brush = _lineBrush.copyWith(size: size);
    return Stroke(
      points: points
          .map((p) => StrokePoint(x: p.dx, y: p.dy, pressure: 1.0))
          .toList(),
      color: _lineColor,
      brush: brush,
    );
  }

  /// Helper to generate circle stroke
  static Stroke _makeCircle(Offset center, double radius, {double size = 4.0, int segments = 60}) {
    final points = <Offset>[];
    for (int i = 0; i <= segments; i++) {
      final theta = (2 * pi / segments) * i;
      points.add(Offset(
        center.dx + radius * cos(theta),
        center.dy + radius * sin(theta),
      ));
    }
    return _makeStroke(points, size: size);
  }

  /// Helper to generate petal / leaf curve
  static Stroke _makePetal(Offset center, double innerR, double outerR, double startAngle, double widthAngle, {double size = 4.0}) {
    final points = <Offset>[];
    const steps = 16;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = startAngle - widthAngle / 2 + widthAngle * sin(t * pi);
      final r = innerR + (outerR - innerR) * sin(t * pi);
      points.add(Offset(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      ));
    }
    return _makeStroke(points, size: size);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Sacred Lotus Mandala
  // ───────────────────────────────────────────────────────────────────────────
  static final ColoringTemplate sacredMandala = ColoringTemplate(
    id: 'sacred_mandala',
    title: 'Sacred Mandala',
    category: 'Mandala',
    description: 'Intricate concentric geometry and meditation petals.',
    icon: Icons.filter_vintage_rounded,
    gradient: const [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    strokeGenerator: (w, h) {
      final center = Offset(w / 2, h / 2);
      final strokes = <Stroke>[];

      // Rings
      strokes.add(_makeCircle(center, 80, size: 6.0));
      strokes.add(_makeCircle(center, 180, size: 4.0));
      strokes.add(_makeCircle(center, 300, size: 5.0));
      strokes.add(_makeCircle(center, 460, size: 5.0));
      strokes.add(_makeCircle(center, 620, size: 6.0));
      strokes.add(_makeCircle(center, 780, size: 8.0));

      // Inner 8 petals
      const innerPetals = 8;
      for (int i = 0; i < innerPetals; i++) {
        final theta = (2 * pi / innerPetals) * i;
        strokes.add(_makePetal(center, 80, 180, theta, pi / 5, size: 4.0));
      }

      // Middle 16 petals
      const midPetals = 16;
      for (int i = 0; i < midPetals; i++) {
        final theta = (2 * pi / midPetals) * i;
        strokes.add(_makePetal(center, 180, 300, theta, pi / 9, size: 4.5));
        strokes.add(_makePetal(center, 300, 460, theta + pi / 16, pi / 11, size: 4.5));
      }

      // Outer 24 lotus crowns
      const outerPetals = 24;
      for (int i = 0; i < outerPetals; i++) {
        final theta = (2 * pi / outerPetals) * i;
        strokes.add(_makePetal(center, 460, 620, theta, pi / 14, size: 5.0));
        strokes.add(_makePetal(center, 620, 780, theta + pi / 24, pi / 16, size: 5.0));
      }

      return strokes;
    },
  );

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Cosmic Crescent & Stars
  // ───────────────────────────────────────────────────────────────────────────
  static final ColoringTemplate cosmicMoon = ColoringTemplate(
    id: 'cosmic_moon',
    title: 'Cosmic Moon',
    category: 'Fantasy',
    description: 'Enchanted crescent moon surrounded by constellations.',
    icon: Icons.nightlight_round,
    gradient: const [Color(0xFF0984E3), Color(0xFF74B9FF)],
    strokeGenerator: (w, h) {
      final center = Offset(w / 2, h / 2);
      final strokes = <Stroke>[];

      // Crescent outer arc
      final outerArc = <Offset>[];
      const steps = 40;
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        final theta = -pi * 0.75 + t * (pi * 1.5);
        outerArc.add(Offset(
          center.dx + 480 * cos(theta),
          center.dy + 480 * sin(theta),
        ));
      }
      strokes.add(_makeStroke(outerArc, size: 6.0));

      // Crescent inner scoop
      final innerArc = <Offset>[];
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        final theta = -pi * 0.65 + t * (pi * 1.3);
        innerArc.add(Offset(
          center.dx + 160 + 380 * cos(theta),
          center.dy + 380 * sin(theta),
        ));
      }
      strokes.add(_makeStroke(innerArc, size: 6.0));

      // Stars
      final starOffsets = [
        Offset(center.dx - 220, center.dy - 350),
        Offset(center.dx + 300, center.dy - 280),
        Offset(center.dx + 420, center.dy + 80),
        Offset(center.dx - 120, center.dy + 380),
        Offset(center.dx + 280, center.dy + 360),
      ];

      for (final s in starOffsets) {
        // 4-point star
        final starPts = [
          Offset(s.dx, s.dy - 40),
          Offset(s.dx + 12, s.dy - 12),
          Offset(s.dx + 40, s.dy),
          Offset(s.dx + 12, s.dy + 12),
          Offset(s.dx, s.dy + 40),
          Offset(s.dx - 12, s.dy + 12),
          Offset(s.dx - 40, s.dy),
          Offset(s.dx - 12, s.dy - 12),
          Offset(s.dx, s.dy - 40),
        ];
        strokes.add(_makeStroke(starPts, size: 4.5));
      }

      // Swirling celestial cloud
      strokes.add(_makeCircle(Offset(center.dx - 180, center.dy - 120), 45, size: 3.5));
      strokes.add(_makeCircle(Offset(center.dx + 180, center.dy + 180), 35, size: 3.5));

      return strokes;
    },
  );

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Cyber Geometric Cat
  // ───────────────────────────────────────────────────────────────────────────
  static final ColoringTemplate cyberCat = ColoringTemplate(
    id: 'cyber_cat',
    title: 'Cyber Cat',
    category: 'Animals',
    description: 'Polygonal geometric feline with expressive anime eyes.',
    icon: Icons.pets_rounded,
    gradient: const [Color(0xFFFF6B9D), Color(0xFFFF8FB1)],
    strokeGenerator: (w, h) {
      final center = Offset(w / 2, h / 2);
      final strokes = <Stroke>[];

      // Cat Head Contours
      final head = [
        Offset(center.dx, center.dy - 280), // Forehead center
        Offset(center.dx - 220, center.dy - 420), // Left ear tip
        Offset(center.dx - 260, center.dy - 160), // Left ear base
        Offset(center.dx - 320, center.dy + 40), // Left cheek
        Offset(center.dx - 160, center.dy + 260), // Left jaw
        Offset(center.dx, center.dy + 340), // Chin
        Offset(center.dx + 160, center.dy + 260), // Right jaw
        Offset(center.dx + 320, center.dy + 40), // Right cheek
        Offset(center.dx + 260, center.dy - 160), // Right ear base
        Offset(center.dx + 220, center.dy - 420), // Right ear tip
        Offset(center.dx, center.dy - 280), // Close
      ];
      strokes.add(_makeStroke(head, size: 6.0));

      // Inner ears
      strokes.add(_makeStroke([
        Offset(center.dx - 180, center.dy - 260),
        Offset(center.dx - 210, center.dy - 370),
        Offset(center.dx - 240, center.dy - 180),
      ], size: 4.5));

      strokes.add(_makeStroke([
        Offset(center.dx + 180, center.dy - 260),
        Offset(center.dx + 210, center.dy - 370),
        Offset(center.dx + 240, center.dy - 180),
      ], size: 4.5));

      // Eyes
      strokes.add(_makeCircle(Offset(center.dx - 120, center.dy - 40), 55, size: 5.0));
      strokes.add(_makeCircle(Offset(center.dx - 120, center.dy - 40), 22, size: 4.0));

      strokes.add(_makeCircle(Offset(center.dx + 120, center.dy - 40), 55, size: 5.0));
      strokes.add(_makeCircle(Offset(center.dx + 120, center.dy - 40), 22, size: 4.0));

      // Nose & Whiskers
      final nose = [
        Offset(center.dx - 30, center.dy + 80),
        Offset(center.dx + 30, center.dy + 80),
        Offset(center.dx, center.dy + 120),
        Offset(center.dx - 30, center.dy + 80),
      ];
      strokes.add(_makeStroke(nose, size: 4.5));

      // Mouth
      strokes.add(_makeStroke([
        Offset(center.dx, center.dy + 120),
        Offset(center.dx, center.dy + 160),
        Offset(center.dx - 60, center.dy + 180),
      ], size: 4.5));
      strokes.add(_makeStroke([
        Offset(center.dx, center.dy + 160),
        Offset(center.dx + 60, center.dy + 180),
      ], size: 4.5));

      // Whiskers Left
      strokes.add(_makeStroke([
        Offset(center.dx - 140, center.dy + 130),
        Offset(center.dx - 380, center.dy + 110),
      ], size: 4.0));
      strokes.add(_makeStroke([
        Offset(center.dx - 140, center.dy + 160),
        Offset(center.dx - 370, center.dy + 180),
      ], size: 4.0));

      // Whiskers Right
      strokes.add(_makeStroke([
        Offset(center.dx + 140, center.dy + 130),
        Offset(center.dx + 380, center.dy + 110),
      ], size: 4.0));
      strokes.add(_makeStroke([
        Offset(center.dx + 140, center.dy + 160),
        Offset(center.dx + 370, center.dy + 180),
      ], size: 4.0));

      return strokes;
    },
  );

  // ───────────────────────────────────────────────────────────────────────────
  // 4. Enchanted Butterfly
  // ───────────────────────────────────────────────────────────────────────────
  static final ColoringTemplate butterflyDream = ColoringTemplate(
    id: 'butterfly_dream',
    title: 'Butterfly Dream',
    category: 'Nature',
    description: 'Symmetric ornate butterfly with botanical wings.',
    icon: Icons.flutter_dash_rounded,
    gradient: const [Color(0xFF00B894), Color(0xFF55EFC4)],
    strokeGenerator: (w, h) {
      final center = Offset(w / 2, h / 2);
      final strokes = <Stroke>[];

      // Butterfly Body
      strokes.add(_makeStroke([
        Offset(center.dx, center.dy - 180),
        Offset(center.dx - 18, center.dy - 80),
        Offset(center.dx - 14, center.dy + 120),
        Offset(center.dx, center.dy + 220),
        Offset(center.dx + 14, center.dy + 120),
        Offset(center.dx + 18, center.dy - 80),
        Offset(center.dx, center.dy - 180),
      ], size: 5.5));

      // Antennae
      strokes.add(_makeStroke([
        Offset(center.dx - 8, center.dy - 170),
        Offset(center.dx - 40, center.dy - 260),
        Offset(center.dx - 90, center.dy - 300),
      ], size: 4.0));
      strokes.add(_makeCircle(Offset(center.dx - 90, center.dy - 300), 12, size: 4.0));

      strokes.add(_makeStroke([
        Offset(center.dx + 8, center.dy - 170),
        Offset(center.dx + 40, center.dy - 260),
        Offset(center.dx + 90, center.dy - 300),
      ], size: 4.0));
      strokes.add(_makeCircle(Offset(center.dx + 90, center.dy - 300), 12, size: 4.0));

      // Upper Wings Left
      final upperWingL = [
        Offset(center.dx - 20, center.dy - 120),
        Offset(center.dx - 240, center.dy - 340),
        Offset(center.dx - 480, center.dy - 280),
        Offset(center.dx - 520, center.dy - 100),
        Offset(center.dx - 380, center.dy + 40),
        Offset(center.dx - 20, center.dy - 20),
      ];
      strokes.add(_makeStroke(upperWingL, size: 6.0));

      // Upper Wings Right
      final upperWingR = [
        Offset(center.dx + 20, center.dy - 120),
        Offset(center.dx + 240, center.dy - 340),
        Offset(center.dx + 480, center.dy - 280),
        Offset(center.dx + 520, center.dy - 100),
        Offset(center.dx + 380, center.dy + 40),
        Offset(center.dx + 20, center.dy - 20),
      ];
      strokes.add(_makeStroke(upperWingR, size: 6.0));

      // Lower Wings Left
      final lowerWingL = [
        Offset(center.dx - 20, center.dy),
        Offset(center.dx - 360, center.dy + 80),
        Offset(center.dx - 420, center.dy + 260),
        Offset(center.dx - 220, center.dy + 380),
        Offset(center.dx - 100, center.dy + 260),
        Offset(center.dx - 15, center.dy + 140),
      ];
      strokes.add(_makeStroke(lowerWingL, size: 5.5));

      // Lower Wings Right
      final lowerWingR = [
        Offset(center.dx + 20, center.dy),
        Offset(center.dx + 360, center.dy + 80),
        Offset(center.dx + 420, center.dy + 260),
        Offset(center.dx + 220, center.dy + 380),
        Offset(center.dx + 100, center.dy + 260),
        Offset(center.dx + 15, center.dy + 140),
      ];
      strokes.add(_makeStroke(lowerWingR, size: 5.5));

      // Wing Medallions
      strokes.add(_makeCircle(Offset(center.dx - 280, center.dy - 140), 50, size: 4.5));
      strokes.add(_makeCircle(Offset(center.dx + 280, center.dy - 140), 50, size: 4.5));
      strokes.add(_makeCircle(Offset(center.dx - 240, center.dy + 220), 40, size: 4.0));
      strokes.add(_makeCircle(Offset(center.dx + 240, center.dy + 220), 40, size: 4.0));

      return strokes;
    },
  );

  /// All available templates list.
  static final List<ColoringTemplate> all = [
    sacredMandala,
    cosmicMoon,
    cyberCat,
    butterflyDream,
  ];
}
