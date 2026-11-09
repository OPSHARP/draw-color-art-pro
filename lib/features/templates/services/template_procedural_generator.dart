import 'dart:math';
import 'package:flutter/material.dart';
import '../../canvas/models/stroke.dart';
import '../../brushes/default_brushes.dart';

/// Categories supported by the procedural template generator.
enum TemplateCategory {
  mandala('Mandala & Sacred', Icons.filter_vintage_rounded, [Color(0xFF6C5CE7), Color(0xFFA29BFE)]),
  nature('Nature & Flora', Icons.local_florist_rounded, [Color(0xFF00B894), Color(0xFF55EFC4)]),
  animals('Animals & Wildlife', Icons.pets_rounded, [Color(0xFFFF7675), Color(0xFFFAB1A0)]),
  characters('Anime & Chibi', Icons.face_rounded, [Color(0xFFFF6B9D), Color(0xFFFFA94D)]),
  space('Space & Cosmos', Icons.rocket_launch_rounded, [Color(0xFF0984E3), Color(0xFF74B9FF)]),
  fantasy('Fantasy & Myth', Icons.auto_awesome_rounded, [Color(0xFF9B59B6), Color(0xFFE056FD)]),
  zentangle('Zentangle Patterns', Icons.grain_rounded, [Color(0xFFE17055), Color(0xFFFDCB6E)]),
  vehicles('Vehicles & Machines', Icons.directions_car_rounded, [Color(0xFF2C3E50), Color(0xFF7F8C8D)]),
  food('Food & Sweets', Icons.icecream_rounded, [Color(0xFFFD79A8), Color(0xFFFFEAA7)]),
  architecture('Architecture', Icons.apartment_rounded, [Color(0xFF16A085), Color(0xFF1ABC9C)]),
  ocean('Ocean & Marine', Icons.water_rounded, [Color(0xFF00CEC9), Color(0xFF81ECEC)]),
  abstractArt('Abstract & Geometric', Icons.category_rounded, [Color(0xFF6C5CE7), Color(0xFFFF7675)]),
  kids('Kids & Cartoon Fun', Icons.child_care_rounded, [Color(0xFFFF70A6), Color(0xFFFFD166)]),
  birds('Birds & Aviary', Icons.flutter_dash_rounded, [Color(0xFF00CEC9), Color(0xFF74B9FF)]),
  flowers('Flowers & Gardens', Icons.yard_rounded, [Color(0xFFFF7675), Color(0xFFFD79A8)]),
  trendingArt('Trending & Pop Art', Icons.whatshot_rounded, [Color(0xFFFF2A6D), Color(0xFF05D9E8)]);

  const TemplateCategory(this.label, this.icon, this.gradient);
  final String label;
  final IconData icon;
  final List<Color> gradient;
}

enum TemplateDifficulty {
  easy('Easy', Color(0xFF00B894)),
  medium('Medium', Color(0xFFFFA94D)),
  detailed('Detailed', Color(0xFF6C5CE7));

  const TemplateDifficulty(this.label, this.color);
  final String label;
  final Color color;
}

/// Algorithmic procedural vector line-art generator for infinite crisp coloring pages.
class TemplateProceduralGenerator {
  TemplateProceduralGenerator._();

  static final BrushPreset _lineBrush = DefaultBrushes.hardBrush.copyWith(
    size: 4.0,
    opacity: 1.0,
    hardness: 1.0,
  );

  static const Color _lineColor = Color(0xFF1E293B);

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

  static Stroke _makeCircle(Offset center, double radius, {double size = 4.0, int segments = 64}) {
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

  static Stroke _makeArc(Offset center, double radius, double startAngle, double sweepAngle, {double size = 4.0, int segments = 24}) {
    final points = <Offset>[];
    for (int i = 0; i <= segments; i++) {
      final theta = startAngle + (sweepAngle / segments) * i;
      points.add(Offset(
        center.dx + radius * cos(theta),
        center.dy + radius * sin(theta),
      ));
    }
    return _makeStroke(points, size: size);
  }

  static Stroke _makePolygon(Offset center, double radius, int sides, {double size = 4.0, double startAngle = -pi / 2}) {
    final points = <Offset>[];
    for (int i = 0; i <= sides; i++) {
      final theta = startAngle + (2 * pi / sides) * i;
      points.add(Offset(
        center.dx + radius * cos(theta),
        center.dy + radius * sin(theta),
      ));
    }
    return _makeStroke(points, size: size);
  }

  static Stroke _makeStar(Offset center, double outerR, double innerR, int points, {double size = 4.0, double startAngle = -pi / 2}) {
    final pts = <Offset>[];
    final totalSteps = points * 2;
    for (int i = 0; i <= totalSteps; i++) {
      final r = i % 2 == 0 ? outerR : innerR;
      final theta = startAngle + (2 * pi / totalSteps) * i;
      pts.add(Offset(center.dx + r * cos(theta), center.dy + r * sin(theta)));
    }
    return _makeStroke(pts, size: size);
  }

  static Stroke _makeEllipse(Offset center, double rx, double ry, {double size = 4.0, double rotation = 0, int segments = 48}) {
    final points = <Offset>[];
    final cosR = cos(rotation);
    final sinR = sin(rotation);
    for (int i = 0; i <= segments; i++) {
      final theta = (2 * pi / segments) * i;
      final dx = rx * cos(theta);
      final dy = ry * sin(theta);
      points.add(Offset(
        center.dx + dx * cosR - dy * sinR,
        center.dy + dx * sinR + dy * cosR,
      ));
    }
    return _makeStroke(points, size: size);
  }

  static Stroke _makeRect(Rect rect, {double size = 4.0}) {
    return _makeStroke([
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
      rect.topLeft,
    ], size: size);
  }

  static Stroke _makePetal(Offset center, double innerR, double outerR, double centerAngle, double spread, {double size = 4.0}) {
    final p0 = Offset(center.dx + innerR * cos(centerAngle), center.dy + innerR * sin(centerAngle));
    final p1 = Offset(center.dx + (innerR + outerR) * 0.5 * cos(centerAngle - spread), center.dy + (innerR + outerR) * 0.5 * sin(centerAngle - spread));
    final pTip = Offset(center.dx + outerR * cos(centerAngle), center.dy + outerR * sin(centerAngle));
    final p2 = Offset(center.dx + (innerR + outerR) * 0.5 * cos(centerAngle + spread), center.dy + (innerR + outerR) * 0.5 * sin(centerAngle + spread));

    final points = <Offset>[];
    const steps = 14;
    // Curve left
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * pTip.dx;
      final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * pTip.dy;
      points.add(Offset(x, y));
    }
    // Curve right back
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = (1 - t) * (1 - t) * pTip.dx + 2 * (1 - t) * t * p2.dx + t * t * p0.dx;
      final y = (1 - t) * (1 - t) * pTip.dy + 2 * (1 - t) * t * p2.dy + t * t * p0.dy;
      points.add(Offset(x, y));
    }
    return _makeStroke(points, size: size);
  }

  /// Generate vector strokes for any template given its seed, category, dimensions, and optional motif index.
  static List<Stroke> generate(int seed, TemplateCategory category, double w, double h, {int? motifIndex}) {
    final rng = Random(seed);
    final strokes = <Stroke>[];
    final center = Offset(w / 2, h / 2);
    final minDim = min(w, h);
    final motif = (motifIndex ?? seed.abs()) % 10;

    // Outer framing double border: clean rectangular frame enclosing artwork nicely
    strokes.add(_makeRect(Rect.fromCenter(center: center, width: minDim * 0.94, height: minDim * 0.94), size: 5.0));
    strokes.add(_makeRect(Rect.fromCenter(center: center, width: minDim * 0.91, height: minDim * 0.91), size: 2.5));

    switch (category) {
      case TemplateCategory.kids:
        _generateKids(strokes, rng, center, minDim, motifIndex ?? (seed.abs() % 28));
        break;
      case TemplateCategory.birds:
        _generateBirds(strokes, rng, center, minDim, motifIndex ?? (seed.abs() % 18));
        break;
      case TemplateCategory.flowers:
        _generateFlowers(strokes, rng, center, minDim, motifIndex ?? (seed.abs() % 18));
        break;
      case TemplateCategory.mandala:
        _generateMandala(strokes, rng, center, minDim, motif);
        break;
      case TemplateCategory.nature:
        _generateNature(strokes, rng, center, minDim, motif);
        break;
      case TemplateCategory.animals:
        _generateAnimals(strokes, rng, center, minDim, motif);
        break;
      case TemplateCategory.characters:
        _generateCharacters(strokes, rng, center, minDim, motifIndex ?? (seed.abs() % 16));
        break;
      case TemplateCategory.space:
        _generateSpace(strokes, rng, center, minDim, motif);
        break;
      case TemplateCategory.fantasy:
        _generateFantasy(strokes, rng, center, minDim, motif);
        break;
      case TemplateCategory.zentangle:
        _generateZentangle(strokes, rng, center, minDim, motif);
        break;
      case TemplateCategory.vehicles:
        _generateVehicles(strokes, rng, center, minDim, motif);
        break;
      case TemplateCategory.food:
        _generateFood(strokes, rng, center, minDim, motif);
        break;
      case TemplateCategory.architecture:
        _generateArchitecture(strokes, rng, center, minDim, motif);
        break;
      case TemplateCategory.ocean:
        _generateOcean(strokes, rng, center, minDim, motif);
        break;
      case TemplateCategory.abstractArt:
        _generateAbstract(strokes, rng, center, minDim, motif);
        break;
      case TemplateCategory.trendingArt:
        _generateTrendingArt(strokes, rng, center, minDim, motifIndex ?? (seed.abs() % 10));
        break;
    }

    return strokes;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. MANDALA & SACRED GEOMETRY (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateMandala(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // Sacred Lotus Mandala
        s.add(_makeCircle(c, m * 0.06, size: 4.5));
        s.add(_makeCircle(c, m * 0.12, size: 3.5));
        for (int i = 0; i < 8; i++) {
          final a = (2 * pi / 8) * i;
          s.add(_makePetal(c, m * 0.12, m * 0.22, a, pi / 10, size: 3.5));
        }
        for (int i = 0; i < 16; i++) {
          final a = (2 * pi / 16) * i + pi / 16;
          s.add(_makePetal(c, m * 0.20, m * 0.33, a, pi / 18, size: 3.5));
        }
        for (int i = 0; i < 24; i++) {
          final a = (2 * pi / 24) * i;
          s.add(_makePetal(c, m * 0.31, m * 0.42, a, pi / 28, size: 3.0));
        }
        s.add(_makeCircle(c, m * 0.43, size: 4.0));
        break;

      case 1: // Cosmic Sunburst Yantra
        s.add(_makeCircle(c, m * 0.15, size: 5.0));
        s.add(_makeStar(c, m * 0.13, m * 0.08, 12, size: 3.5));
        s.add(_makeCircle(c, m * 0.22, size: 3.5));
        for (int i = 0; i < 16; i++) {
          final a = (2 * pi / 16) * i;
          final r1 = m * 0.22;
          final r2 = m * (i % 2 == 0 ? 0.38 : 0.32);
          s.add(_makeStroke([
            Offset(c.dx + r1 * cos(a - 0.1), c.dy + r1 * sin(a - 0.1)),
            Offset(c.dx + r2 * cos(a), c.dy + r2 * sin(a)),
            Offset(c.dx + r1 * cos(a + 0.1), c.dy + r1 * sin(a + 0.1)),
          ], size: 3.5));
        }
        s.add(_makeCircle(c, m * 0.41, size: 4.5));
        for (int i = 0; i < 12; i++) {
          final a = (2 * pi / 12) * i;
          s.add(_makeCircle(Offset(c.dx + m * 0.41 * cos(a), c.dy + m * 0.41 * sin(a)), m * 0.025, size: 3.0));
        }
        break;

      case 2: // Star of Harmony Octagram
        s.add(_makePolygon(c, m * 0.38, 8, size: 4.5));
        s.add(_makePolygon(c, m * 0.38, 8, size: 4.5, startAngle: 0));
        s.add(_makePolygon(c, m * 0.26, 8, size: 3.5));
        s.add(_makePolygon(c, m * 0.26, 8, size: 3.5, startAngle: 0));
        s.add(_makeStar(c, m * 0.18, m * 0.09, 8, size: 4.0));
        s.add(_makeCircle(c, m * 0.06, size: 3.5));
        for (int i = 0; i < 8; i++) {
          final a = (2 * pi / 8) * i;
          s.add(_makeCircle(Offset(c.dx + m * 0.33 * cos(a), c.dy + m * 0.33 * sin(a)), m * 0.035, size: 3.0));
        }
        break;

      case 3: // Zen Spiral Wheel
        s.add(_makeCircle(c, m * 0.42, size: 4.5));
        s.add(_makeCircle(c, m * 0.08, size: 4.0));
        const arms = 12;
        for (int i = 0; i < arms; i++) {
          final baseA = (2 * pi / arms) * i;
          final pts = <Offset>[];
          for (int step = 0; step <= 20; step++) {
            final t = step / 20.0;
            final r = m * (0.08 + t * 0.34);
            final a = baseA + t * 1.5;
            pts.add(Offset(c.dx + r * cos(a), c.dy + r * sin(a)));
          }
          s.add(_makeStroke(pts, size: 3.2));
        }
        s.add(_makeCircle(c, m * 0.25, size: 3.0));
        break;

      case 4: // Gothic Rose Window
        s.add(_makeCircle(c, m * 0.42, size: 5.0));
        s.add(_makeCircle(c, m * 0.38, size: 3.0));
        s.add(_makeCircle(c, m * 0.16, size: 4.0));
        const petals = 12;
        for (int i = 0; i < petals; i++) {
          final a = (2 * pi / petals) * i;
          final centerP = Offset(c.dx + m * 0.27 * cos(a), c.dy + m * 0.27 * sin(a));
          s.add(_makeCircle(centerP, m * 0.09, size: 3.5));
          s.add(_makeCircle(centerP, m * 0.04, size: 2.5));
        }
        for (int i = 0; i < 6; i++) {
          final a = (2 * pi / 6) * i;
          s.add(_makePetal(c, m * 0.04, m * 0.15, a, pi / 8, size: 3.0));
        }
        break;

      case 5: // Sri Yantra Geometry
        s.add(_makeCircle(c, m * 0.42, size: 4.5));
        s.add(_makePolygon(c, m * 0.40, 16, size: 3.0));
        s.add(_makeCircle(c, m * 0.33, size: 3.5));
        for (int i = 0; i < 8; i++) {
          final a = (2 * pi / 8) * i;
          s.add(_makePetal(c, m * 0.33, m * 0.39, a, pi / 10, size: 3.0));
        }
        // Intersecting sacred triangles
        s.add(_makePolygon(Offset(c.dx, c.dy - m * 0.04), m * 0.26, 3, startAngle: -pi / 2, size: 3.5));
        s.add(_makePolygon(Offset(c.dx, c.dy + m * 0.04), m * 0.26, 3, startAngle: pi / 2, size: 3.5));
        s.add(_makePolygon(Offset(c.dx, c.dy - m * 0.02), m * 0.19, 3, startAngle: -pi / 2, size: 3.0));
        s.add(_makePolygon(Offset(c.dx, c.dy + m * 0.02), m * 0.19, 3, startAngle: pi / 2, size: 3.0));
        s.add(_makeCircle(c, m * 0.03, size: 4.0));
        break;

      case 6: // Dreamcatcher Sacred Web
        s.add(_makeCircle(c, m * 0.30, size: 5.0));
        s.add(_makeCircle(c, m * 0.28, size: 3.0));
        // Web rings
        const webPts = 8;
        for (int r = 1; r <= 3; r++) {
          final rad = m * (0.07 + r * 0.07);
          s.add(_makePolygon(c, rad, webPts, startAngle: r * 0.2, size: 3.0));
        }
        s.add(_makeCircle(c, m * 0.035, size: 4.0));
        // Hanging feathers below
        final baseY = c.dy + m * 0.30;
        for (final fx in [-m * 0.15, 0.0, m * 0.15]) {
          s.add(_makeStroke([Offset(c.dx + fx, baseY), Offset(c.dx + fx, baseY + m * 0.12)], size: 3.0));
          s.add(_makePetal(Offset(c.dx + fx, baseY + m * 0.16), 0, m * 0.09, pi / 2, 0.3, size: 3.5));
          s.add(_makeCircle(Offset(c.dx + fx, baseY + m * 0.06), m * 0.015, size: 3.0));
        }
        break;

      case 7: // Chakra Flower of Life
        s.add(_makeCircle(c, m * 0.42, size: 4.5));
        s.add(_makeCircle(c, m * 0.40, size: 3.0));
        final fR = m * 0.13;
        s.add(_makeCircle(c, fR, size: 3.5));
        for (int i = 0; i < 6; i++) {
          final a = (2 * pi / 6) * i;
          final p = Offset(c.dx + fR * cos(a), c.dy + fR * sin(a));
          s.add(_makeCircle(p, fR, size: 3.5));
        }
        for (int i = 0; i < 12; i++) {
          final a = (2 * pi / 12) * i;
          final p = Offset(c.dx + fR * 1.732 * cos(a), c.dy + fR * 1.732 * sin(a));
          s.add(_makeCircle(p, fR, size: 2.5));
        }
        break;

      case 8: // Mayan Solar Glyph
        s.add(_makeCircle(c, m * 0.42, size: 5.0));
        s.add(_makeCircle(c, m * 0.32, size: 3.5));
        s.add(_makeCircle(c, m * 0.18, size: 4.0));
        // Solar face
        s.add(_makeCircle(Offset(c.dx - m * 0.06, c.dy - m * 0.04), m * 0.025, size: 4.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.06, c.dy - m * 0.04), m * 0.025, size: 4.0));
        s.add(_makeArc(Offset(c.dx, c.dy + m * 0.03), m * 0.05, 0.2, pi - 0.4, size: 4.0));
        // Stepped stepped glyphs
        for (int i = 0; i < 8; i++) {
          final a = (2 * pi / 8) * i;
          final p1 = Offset(c.dx + m * 0.32 * cos(a - 0.2), c.dy + m * 0.32 * sin(a - 0.2));
          final p2 = Offset(c.dx + m * 0.42 * cos(a), c.dy + m * 0.42 * sin(a));
          final p3 = Offset(c.dx + m * 0.32 * cos(a + 0.2), c.dy + m * 0.32 * sin(a + 0.2));
          s.add(_makeStroke([p1, p2, p3], size: 3.5));
        }
        break;

      default: // Celtic Knot Rosette
        s.add(_makeCircle(c, m * 0.42, size: 5.0));
        s.add(_makeCircle(c, m * 0.38, size: 3.0));
        for (int i = 0; i < 4; i++) {
          final a = (pi / 2) * i;
          final p = Offset(c.dx + m * 0.18 * cos(a), c.dy + m * 0.18 * sin(a));
          s.add(_makeCircle(p, m * 0.18, size: 3.8));
          s.add(_makeCircle(p, m * 0.14, size: 2.8));
        }
        s.add(_makeCircle(c, m * 0.08, size: 4.0));
        s.add(_makeCircle(c, m * 0.04, size: 2.5));
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. NATURE & FLORA (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateNature(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // Blooming Sunflower
        s.add(_makeCircle(c, m * 0.15, size: 4.5));
        for (int r = 1; r <= 3; r++) {
          s.add(_makeCircle(c, m * (0.04 * r), size: 2.5));
        }
        for (int i = 0; i < 16; i++) {
          final a = (2 * pi / 16) * i;
          s.add(_makePetal(c, m * 0.15, m * 0.36, a, pi / 18, size: 3.8));
        }
        s.add(_makeStroke([Offset(c.dx, c.dy + m * 0.24), Offset(c.dx, c.dy + m * 0.45)], size: 6.0));
        s.add(_makePetal(Offset(c.dx - m * 0.14, c.dy + m * 0.34), 0, m * 0.16, -pi * 0.8, 0.4, size: 3.5));
        s.add(_makePetal(Offset(c.dx + m * 0.14, c.dy + m * 0.38), 0, m * 0.16, -pi * 0.2, 0.4, size: 3.5));
        break;

      case 1: // Cherry Blossom Sakura Branch
        // Arching Branch
        s.add(_makeStroke([
          Offset(c.dx - m * 0.42, c.dy + m * 0.30),
          Offset(c.dx - m * 0.15, c.dy + m * 0.08),
          Offset(c.dx + m * 0.12, c.dy - m * 0.05),
          Offset(c.dx + m * 0.42, c.dy - m * 0.22),
        ], size: 6.0));
        // Sub-branches
        s.add(_makeStroke([Offset(c.dx - m * 0.05, c.dy + m * 0.02), Offset(c.dx - m * 0.18, c.dy - m * 0.16)], size: 4.0));
        s.add(_makeStroke([Offset(c.dx + m * 0.20, c.dy - m * 0.10), Offset(c.dx + m * 0.28, c.dy + m * 0.08)], size: 4.0));
        // 5-petal sakura blossoms
        final blossomCenters = [
          Offset(c.dx - m * 0.18, c.dy - m * 0.16),
          Offset(c.dx + m * 0.05, c.dy - m * 0.12),
          Offset(c.dx + m * 0.28, c.dy + m * 0.08),
          Offset(c.dx - m * 0.22, c.dy + m * 0.12),
          Offset(c.dx + m * 0.38, c.dy - m * 0.25),
        ];
        for (final bc in blossomCenters) {
          s.add(_makeCircle(bc, m * 0.025, size: 3.0));
          for (int p = 0; p < 5; p++) {
            final a = (2 * pi / 5) * p;
            s.add(_makePetal(bc, m * 0.025, m * 0.08, a, 0.35, size: 3.0));
          }
        }
        break;

      case 2: // Tropical Monstera & Palm Jungle
        // Monstera leaf center
        final mC = Offset(c.dx - m * 0.08, c.dy);
        s.add(_makeStroke([Offset(mC.dx, mC.dy - m * 0.32), Offset(mC.dx, mC.dy + m * 0.38)], size: 5.0));
        s.add(_makePetal(mC, 0, m * 0.34, -pi / 2, 0.7, size: 4.5));
        for (int i = 0; i < 4; i++) {
          final y = mC.dy - m * 0.15 + i * (m * 0.1);
          s.add(_makeStroke([Offset(mC.dx - m * 0.05, y), Offset(mC.dx - m * 0.22, y - m * 0.04)], size: 3.0));
          s.add(_makeStroke([Offset(mC.dx + m * 0.05, y), Offset(mC.dx + m * 0.22, y - m * 0.04)], size: 3.0));
        }
        // Palm fan on right
        final pC = Offset(c.dx + m * 0.20, c.dy + m * 0.15);
        for (int i = 0; i < 7; i++) {
          final a = -pi * 0.85 + (pi * 0.7 / 6) * i;
          s.add(_makeStroke([pC, Offset(pC.dx + m * 0.26 * cos(a), pC.dy + m * 0.26 * sin(a))], size: 3.5));
        }
        break;

      case 3: // Bonsai Tree on Rock
        // Pot
        final potY = c.dy + m * 0.24;
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.28, potY, m * 0.56, m * 0.12), size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.22, potY + m * 0.14), m * 0.02, size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.22, potY + m * 0.14), m * 0.02, size: 3.5));
        // Gnarled Trunk
        s.add(_makeStroke([
          Offset(c.dx, potY),
          Offset(c.dx - m * 0.08, c.dy + m * 0.08),
          Offset(c.dx + m * 0.06, c.dy - m * 0.04),
          Offset(c.dx - m * 0.02, c.dy - m * 0.18),
        ], size: 7.0));
        // Foliage Clouds
        final cloudCenters = [
          Offset(c.dx - m * 0.16, c.dy - m * 0.02),
          Offset(c.dx + m * 0.18, c.dy - m * 0.08),
          Offset(c.dx - m * 0.02, c.dy - m * 0.25),
          Offset(c.dx + m * 0.12, c.dy - m * 0.20),
        ];
        for (final cc in cloudCenters) {
          s.add(_makeEllipse(cc, m * 0.14, m * 0.07, size: 3.8));
          s.add(_makeEllipse(cc, m * 0.09, m * 0.04, size: 2.5));
        }
        break;

      case 4: // Forest Mushrooms & Ferns
        // Central Mushroom
        final mY = c.dy + m * 0.08;
        s.add(_makeArc(Offset(c.dx, mY), m * 0.24, -pi * 0.95, pi * 0.9, size: 4.8));
        s.add(_makeStroke([Offset(c.dx - m * 0.24, mY), Offset(c.dx + m * 0.24, mY)], size: 4.0));
        s.add(_makeStroke([
          Offset(c.dx - m * 0.08, mY),
          Offset(c.dx - m * 0.06, mY + m * 0.28),
          Offset(c.dx + m * 0.06, mY + m * 0.28),
          Offset(c.dx + m * 0.08, mY),
        ], size: 4.5));
        // Dots on cap
        s.add(_makeCircle(Offset(c.dx - m * 0.10, mY - m * 0.10), m * 0.035, size: 3.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.10, mY - m * 0.08), m * 0.04, size: 3.0));
        s.add(_makeCircle(Offset(c.dx, mY - m * 0.15), m * 0.03, size: 3.0));
        // Side baby mushroom
        s.add(_makeArc(Offset(c.dx - m * 0.22, mY + m * 0.14), m * 0.12, -pi, pi, size: 3.8));
        s.add(_makeStroke([Offset(c.dx - m * 0.22, mY + m * 0.14), Offset(c.dx - m * 0.22, mY + m * 0.28)], size: 4.0));
        // Fern spiral
        s.add(_makeStroke([
          Offset(c.dx + m * 0.22, mY + m * 0.28),
          Offset(c.dx + m * 0.28, mY + m * 0.05),
          Offset(c.dx + m * 0.25, mY - m * 0.10),
          Offset(c.dx + m * 0.20, mY - m * 0.08),
        ], size: 4.0));
        break;

      case 5: // Mountain Pine Haven
        // Mountains
        s.add(_makePolygon(Offset(c.dx - m * 0.15, c.dy - m * 0.05), m * 0.32, 3, startAngle: -pi / 2, size: 4.5));
        s.add(_makePolygon(Offset(c.dx + m * 0.18, c.dy), m * 0.26, 3, startAngle: -pi / 2, size: 4.5));
        // Mountain snowcaps
        s.add(_makeStroke([
          Offset(c.dx - m * 0.22, c.dy - m * 0.18),
          Offset(c.dx - m * 0.15, c.dy - m * 0.15),
          Offset(c.dx - m * 0.08, c.dy - m * 0.18),
        ], size: 3.5));
        // Pine trees in foreground
        for (final tx in [-m * 0.25, 0.0, m * 0.25]) {
          final tY = c.dy + m * 0.15;
          for (int layer = 0; layer < 3; layer++) {
            final lY = tY - layer * (m * 0.08);
            s.add(_makePolygon(Offset(c.dx + tx, lY), m * (0.12 - layer * 0.03), 3, startAngle: -pi / 2, size: 3.5));
          }
          s.add(_makeStroke([Offset(c.dx + tx, tY), Offset(c.dx + tx, c.dy + m * 0.38)], size: 4.5));
        }
        break;

      case 6: // Desert Cactus & Succulent Terrarium
        // Saguaro Main Stem
        final bY = c.dy + m * 0.34;
        s.add(_makeStroke([
          Offset(c.dx - m * 0.08, bY),
          Offset(c.dx - m * 0.08, c.dy - m * 0.22),
          Offset(c.dx + m * 0.08, c.dy - m * 0.22),
          Offset(c.dx + m * 0.08, bY),
        ], size: 5.0));
        s.add(_makeArc(Offset(c.dx, c.dy - m * 0.22), m * 0.08, -pi, pi, size: 5.0));
        // Left Arm
        s.add(_makeStroke([
          Offset(c.dx - m * 0.08, c.dy - m * 0.02),
          Offset(c.dx - m * 0.24, c.dy - m * 0.02),
          Offset(c.dx - m * 0.24, c.dy - m * 0.15),
        ], size: 4.5));
        s.add(_makeArc(Offset(c.dx - m * 0.24, c.dy - m * 0.15), m * 0.04, -pi, pi, size: 4.0));
        // Right Arm
        s.add(_makeStroke([
          Offset(c.dx + m * 0.08, c.dy + m * 0.06),
          Offset(c.dx + m * 0.22, c.dy + m * 0.06),
          Offset(c.dx + m * 0.22, c.dy - m * 0.08),
        ], size: 4.5));
        s.add(_makeArc(Offset(c.dx + m * 0.22, c.dy - m * 0.08), m * 0.04, -pi, pi, size: 4.0));
        // Desert sand dune
        s.add(_makeArc(Offset(c.dx, bY + m * 0.1), m * 0.42, -pi * 0.8, pi * 0.6, size: 3.5));
        break;

      case 7: // Floating Water Lily & Pad
        final pondY = c.dy + m * 0.08;
        // Lily Pad
        s.add(_makeArc(Offset(c.dx, pondY), m * 0.36, 0.3, 2 * pi - 0.6, size: 4.5));
        s.add(_makeStroke([
          Offset(c.dx, pondY),
          Offset(c.dx + m * 0.36 * cos(0.3), pondY + m * 0.36 * sin(0.3)),
        ], size: 3.5));
        s.add(_makeStroke([
          Offset(c.dx, pondY),
          Offset(c.dx + m * 0.36 * cos(2 * pi - 0.3), pondY + m * 0.36 * sin(2 * pi - 0.3)),
        ], size: 3.5));
        // Lotus Bloom on top
        s.add(_makeCircle(Offset(c.dx - m * 0.04, pondY - m * 0.12), m * 0.05, size: 3.5));
        for (int i = 0; i < 8; i++) {
          final a = -pi * 0.85 + (pi * 0.7 / 7) * i;
          s.add(_makePetal(Offset(c.dx - m * 0.04, pondY - m * 0.12), m * 0.05, m * 0.22, a, 0.25, size: 3.5));
        }
        // Ripples
        s.add(_makeEllipse(Offset(c.dx, pondY), m * 0.42, m * 0.18, size: 2.8));
        break;

      case 8: // Autumn Maple & Oak Leaves
        // Maple leaf center
        s.add(_makeStroke([Offset(c.dx, c.dy - m * 0.32), Offset(c.dx, c.dy + m * 0.38)], size: 5.0));
        for (final sign in [-1.0, 1.0]) {
          s.add(_makeStroke([
            Offset(c.dx, c.dy - m * 0.32),
            Offset(c.dx + sign * m * 0.12, c.dy - m * 0.24),
            Offset(c.dx + sign * m * 0.08, c.dy - m * 0.18),
            Offset(c.dx + sign * m * 0.26, c.dy - m * 0.12),
            Offset(c.dx + sign * m * 0.18, c.dy - m * 0.04),
            Offset(c.dx + sign * m * 0.28, c.dy + m * 0.06),
            Offset(c.dx + sign * m * 0.16, c.dy + m * 0.12),
            Offset(c.dx + sign * m * 0.10, c.dy + m * 0.22),
            Offset(c.dx, c.dy + m * 0.24),
          ], size: 4.5));
          // Veins
          s.add(_makeStroke([Offset(c.dx, c.dy - m * 0.10), Offset(c.dx + sign * m * 0.18, c.dy - m * 0.12)], size: 3.0));
          s.add(_makeStroke([Offset(c.dx, c.dy + m * 0.04), Offset(c.dx + sign * m * 0.20, c.dy + m * 0.06)], size: 3.0));
        }
        break;

      default: // Classic Rose in Full Bloom
        s.add(_makeCircle(c, m * 0.08, size: 4.0));
        // Spiraling curved petals
        for (int i = 1; i <= 4; i++) {
          final r = m * (0.07 + i * 0.06);
          s.add(_makeArc(c, r, i * 0.8, pi * 1.2, size: 4.0));
          s.add(_makeArc(c, r + m * 0.03, i * 0.8 + pi, pi * 1.1, size: 3.5));
        }
        // Thorny stem
        s.add(_makeStroke([Offset(c.dx, c.dy + m * 0.26), Offset(c.dx - m * 0.04, c.dy + m * 0.44)], size: 5.5));
        s.add(_makePolygon(Offset(c.dx - m * 0.02, c.dy + m * 0.34), m * 0.03, 3, startAngle: pi, size: 3.5));
        s.add(_makePetal(Offset(c.dx + m * 0.12, c.dy + m * 0.35), 0, m * 0.14, -pi * 0.2, 0.4, size: 3.5));
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. ANIMALS & WILDLIFE (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateAnimals(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // Majestic Roaring Lion
        // Mane radiating petals
        for (int i = 0; i < 20; i++) {
          final a = (2 * pi / 20) * i;
          s.add(_makePetal(c, m * 0.22, m * 0.42, a, 0.2, size: 4.0));
        }
        // Face Circle
        s.add(_makeCircle(c, m * 0.22, size: 5.0));
        // Ears
        s.add(_makeCircle(Offset(c.dx - m * 0.16, c.dy - m * 0.16), m * 0.06, size: 4.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.16, c.dy - m * 0.16), m * 0.06, size: 4.0));
        // Eyes
        s.add(_makeCircle(Offset(c.dx - m * 0.09, c.dy - m * 0.05), m * 0.035, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.09, c.dy - m * 0.05), m * 0.035, size: 4.5));
        // Nose & Muzzle
        s.add(_makePolygon(Offset(c.dx, c.dy + m * 0.04), m * 0.045, 3, startAngle: pi / 2, size: 4.5));
        s.add(_makeStroke([Offset(c.dx, c.dy + m * 0.06), Offset(c.dx, c.dy + m * 0.11)], size: 4.0));
        s.add(_makeArc(Offset(c.dx - m * 0.05, c.dy + m * 0.11), m * 0.05, 0.2, pi - 0.4, size: 4.0));
        s.add(_makeArc(Offset(c.dx + m * 0.05, c.dy + m * 0.11), m * 0.05, 0.2, pi - 0.4, size: 4.0));
        break;

      case 1: // Royal Timber Wolf
        // Wolf Head in profile
        final wC = Offset(c.dx - m * 0.06, c.dy);
        s.add(_makeStroke([
          Offset(wC.dx - m * 0.10, wC.dy + m * 0.28), // Throat
          Offset(wC.dx - m * 0.16, wC.dy + m * 0.08), // Chin
          Offset(wC.dx - m * 0.28, wC.dy - m * 0.02), // Snout
          Offset(wC.dx - m * 0.26, wC.dy - m * 0.08), // Nose bridge
          Offset(wC.dx - m * 0.12, wC.dy - m * 0.12), // Forehead
          Offset(wC.dx - m * 0.08, wC.dy - m * 0.32), // Ear tip
          Offset(wC.dx + m * 0.02, wC.dy - m * 0.14), // Ear back
          Offset(wC.dx + m * 0.16, wC.dy + m * 0.04), // Neck ruff
          Offset(wC.dx + m * 0.24, wC.dy + m * 0.28), // Shoulder
        ], size: 5.0));
        // Moon disc behind
        s.add(_makeCircle(Offset(c.dx + m * 0.15, c.dy - m * 0.15), m * 0.18, size: 4.0));
        // Wolf eye
        s.add(_makePolygon(Offset(wC.dx - m * 0.10, wC.dy - m * 0.08), m * 0.03, 3, size: 4.0));
        break;

      case 2: // Wise Horned Owl
        // Body Oval
        s.add(_makeEllipse(c, m * 0.20, m * 0.28, size: 5.0));
        // Ear Horns
        s.add(_makePolygon(Offset(c.dx - m * 0.14, c.dy - m * 0.28), m * 0.09, 3, startAngle: -pi * 0.6, size: 4.5));
        s.add(_makePolygon(Offset(c.dx + m * 0.14, c.dy - m * 0.28), m * 0.09, 3, startAngle: -pi * 0.4, size: 4.5));
        // Big Concentric Eyes
        s.add(_makeCircle(Offset(c.dx - m * 0.09, c.dy - m * 0.10), m * 0.075, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.09, c.dy - m * 0.10), m * 0.035, size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.09, c.dy - m * 0.10), m * 0.075, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.09, c.dy - m * 0.10), m * 0.035, size: 3.5));
        // Beak
        s.add(_makePolygon(Offset(c.dx, c.dy - m * 0.02), m * 0.035, 3, startAngle: pi / 2, size: 4.0));
        // Perch Branch
        s.add(_makeStroke([Offset(c.dx - m * 0.38, c.dy + m * 0.28), Offset(c.dx + m * 0.38, c.dy + m * 0.28)], size: 6.0));
        break;

      case 3: // Graceful Forest Stag
        // Deer Head
        s.add(_makeStroke([
          Offset(c.dx, c.dy + m * 0.24), // Muzzle
          Offset(c.dx - m * 0.08, c.dy + m * 0.14),
          Offset(c.dx - m * 0.12, c.dy - m * 0.04), // Cheek
          Offset(c.dx - m * 0.06, c.dy - m * 0.16), // Forehead
          Offset(c.dx + m * 0.06, c.dy - m * 0.16),
          Offset(c.dx + m * 0.12, c.dy - m * 0.04),
          Offset(c.dx + m * 0.08, c.dy + m * 0.14),
          Offset(c.dx, c.dy + m * 0.24),
        ], size: 4.5));
        // Big Ears
        s.add(_makePetal(Offset(c.dx - m * 0.10, c.dy - m * 0.14), 0, m * 0.14, -pi * 0.75, 0.35, size: 4.0));
        s.add(_makePetal(Offset(c.dx + m * 0.10, c.dy - m * 0.14), 0, m * 0.14, -pi * 0.25, 0.35, size: 4.0));
        // Branching Antlers Left & Right
        for (final sign in [-1.0, 1.0]) {
          final aX = c.dx + sign * m * 0.06;
          final aY = c.dy - m * 0.16;
          s.add(_makeStroke([
            Offset(aX, aY),
            Offset(aX + sign * m * 0.12, aY - m * 0.14),
            Offset(aX + sign * m * 0.20, aY - m * 0.26),
          ], size: 5.0));
          s.add(_makeStroke([Offset(aX + sign * m * 0.10, aY - m * 0.10), Offset(aX + sign * m * 0.22, aY - m * 0.12)], size: 4.0));
          s.add(_makeStroke([Offset(aX + sign * m * 0.16, aY - m * 0.20), Offset(aX + sign * m * 0.26, aY - m * 0.24)], size: 4.0));
        }
        break;

      case 4: // Playful Red Fox
        // Fox Head
        s.add(_makePolygon(c, m * 0.18, 3, startAngle: pi / 2, size: 5.0));
        // Giant Pointy Ears
        s.add(_makePolygon(Offset(c.dx - m * 0.14, c.dy - m * 0.16), m * 0.12, 3, startAngle: -pi * 0.6, size: 4.5));
        s.add(_makePolygon(Offset(c.dx + m * 0.14, c.dy - m * 0.16), m * 0.12, 3, startAngle: -pi * 0.4, size: 4.5));
        // Curved Sleeping Body & Tail
        s.add(_makeArc(Offset(c.dx, c.dy + m * 0.15), m * 0.24, -0.2, pi + 0.4, size: 5.0));
        s.add(_makePetal(Offset(c.dx + m * 0.15, c.dy + m * 0.15), 0, m * 0.26, -0.4, 0.5, size: 4.5));
        // Eyes & Nose
        s.add(_makeArc(Offset(c.dx - m * 0.07, c.dy - m * 0.02), m * 0.03, 0.2, pi - 0.4, size: 4.0));
        s.add(_makeArc(Offset(c.dx + m * 0.07, c.dy - m * 0.02), m * 0.03, 0.2, pi - 0.4, size: 4.0));
        s.add(_makeCircle(Offset(c.dx, c.dy + m * 0.08), m * 0.025, size: 4.0));
        break;

      case 5: // Royal Bengal Tiger
        s.add(_makeCircle(c, m * 0.24, size: 5.0));
        // Ears
        s.add(_makeCircle(Offset(c.dx - m * 0.18, c.dy - m * 0.18), m * 0.06, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.18, c.dy - m * 0.18), m * 0.06, size: 4.5));
        // Forehead stripes
        s.add(_makePolygon(Offset(c.dx, c.dy - m * 0.16), m * 0.04, 3, startAngle: pi / 2, size: 4.0));
        s.add(_makeStroke([Offset(c.dx - m * 0.08, c.dy - m * 0.18), Offset(c.dx, c.dy - m * 0.12), Offset(c.dx + m * 0.08, c.dy - m * 0.18)], size: 3.5));
        // Cheek stripes
        s.add(_makeStroke([Offset(c.dx - m * 0.22, c.dy), Offset(c.dx - m * 0.14, c.dy - m * 0.02)], size: 4.0));
        s.add(_makeStroke([Offset(c.dx - m * 0.22, c.dy + m * 0.06), Offset(c.dx - m * 0.14, c.dy + m * 0.04)], size: 4.0));
        s.add(_makeStroke([Offset(c.dx + m * 0.22, c.dy), Offset(c.dx + m * 0.14, c.dy - m * 0.02)], size: 4.0));
        s.add(_makeStroke([Offset(c.dx + m * 0.22, c.dy + m * 0.06), Offset(c.dx + m * 0.14, c.dy + m * 0.04)], size: 4.0));
        // Eyes & Snout
        s.add(_makeCircle(Offset(c.dx - m * 0.09, c.dy - m * 0.04), m * 0.035, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.09, c.dy - m * 0.04), m * 0.035, size: 4.5));
        s.add(_makePolygon(Offset(c.dx, c.dy + m * 0.06), m * 0.045, 3, startAngle: pi / 2, size: 4.5));
        break;

      case 6: // Soaring Imperial Eagle
        // Eagle Head & Body
        s.add(_makeCircle(Offset(c.dx, c.dy - m * 0.10), m * 0.12, size: 4.5));
        // Sharp Hooked Beak
        s.add(_makeStroke([
          Offset(c.dx, c.dy - m * 0.12),
          Offset(c.dx + m * 0.14, c.dy - m * 0.08),
          Offset(c.dx + m * 0.10, c.dy - m * 0.02),
          Offset(c.dx, c.dy - m * 0.04),
        ], size: 4.5));
        // Widespread Wings
        for (final sign in [-1.0, 1.0]) {
          final pts = <Offset>[
            Offset(c.dx + sign * m * 0.08, c.dy - m * 0.04),
            Offset(c.dx + sign * m * 0.42, c.dy - m * 0.24),
            Offset(c.dx + sign * m * 0.44, c.dy - m * 0.08),
            Offset(c.dx + sign * m * 0.36, c.dy + m * 0.04),
            Offset(c.dx + sign * m * 0.24, c.dy + m * 0.12),
            Offset(c.dx + sign * m * 0.08, c.dy + m * 0.18),
          ];
          s.add(_makeStroke(pts, size: 4.5));
        }
        // Tail Fan
        s.add(_makePolygon(Offset(c.dx, c.dy + m * 0.28), m * 0.15, 3, startAngle: pi / 2, size: 4.0));
        break;

      case 7: // Gentle Bohemian Elephant
        // Head & Ears
        s.add(_makeCircle(Offset(c.dx, c.dy - m * 0.08), m * 0.18, size: 5.0));
        // Large Flapping Ears
        s.add(_makePetal(Offset(c.dx - m * 0.14, c.dy - m * 0.08), 0, m * 0.28, -pi * 0.95, 0.45, size: 4.5));
        s.add(_makePetal(Offset(c.dx + m * 0.14, c.dy - m * 0.08), 0, m * 0.28, -pi * 0.05, 0.45, size: 4.5));
        // Curving Trunk
        s.add(_makeStroke([
          Offset(c.dx, c.dy + m * 0.05),
          Offset(c.dx - m * 0.04, c.dy + m * 0.20),
          Offset(c.dx + m * 0.08, c.dy + m * 0.32),
          Offset(c.dx + m * 0.14, c.dy + m * 0.26),
        ], size: 5.5));
        // Tusks
        s.add(_makeArc(Offset(c.dx - m * 0.08, c.dy + m * 0.08), m * 0.08, 0.5, 1.2, size: 4.0));
        s.add(_makeArc(Offset(c.dx + m * 0.08, c.dy + m * 0.08), m * 0.08, pi - 1.7, 1.2, size: 4.0));
        // Bohemian Headpiece
        s.add(_makePolygon(Offset(c.dx, c.dy - m * 0.14), m * 0.06, 3, startAngle: -pi / 2, size: 3.5));
        break;

      case 8: // Cozy Panda with Bamboo
        // Panda Head
        s.add(_makeCircle(Offset(c.dx, c.dy - m * 0.08), m * 0.20, size: 5.0));
        // Round Black Ears
        s.add(_makeCircle(Offset(c.dx - m * 0.16, c.dy - m * 0.24), m * 0.06, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.16, c.dy - m * 0.24), m * 0.06, size: 5.0));
        // Eye Patches
        s.add(_makeEllipse(Offset(c.dx - m * 0.08, c.dy - m * 0.08), m * 0.055, m * 0.04, rotation: -0.4, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.08, c.dy - m * 0.08), m * 0.015, size: 3.5));
        s.add(_makeEllipse(Offset(c.dx + m * 0.08, c.dy - m * 0.08), m * 0.055, m * 0.04, rotation: 0.4, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.08, c.dy - m * 0.08), m * 0.015, size: 3.5));
        // Body & Paws
        s.add(_makeCircle(Offset(c.dx, c.dy + m * 0.18), m * 0.20, size: 5.0));
        // Bamboo Stalk
        s.add(_makeStroke([Offset(c.dx - m * 0.25, c.dy + m * 0.38), Offset(c.dx + m * 0.20, c.dy - m * 0.25)], size: 5.5));
        for (int i = 0; i < 4; i++) {
          final frac = i / 4.0;
          final px = (c.dx - m * 0.25) + (m * 0.45) * frac;
          final py = (c.dy + m * 0.38) - (m * 0.63) * frac;
          s.add(_makePetal(Offset(px, py), 0, m * 0.08, -pi * 0.3, 0.4, size: 3.0));
        }
        break;

      default: // Tropical Chameleon
        // Curled Body
        s.add(_makeEllipse(Offset(c.dx - m * 0.04, c.dy - m * 0.02), m * 0.22, m * 0.15, size: 5.0));
        // Big Turret Eye
        s.add(_makeCircle(Offset(c.dx - m * 0.14, c.dy - m * 0.06), m * 0.05, size: 4.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.14, c.dy - m * 0.06), m * 0.02, size: 3.0));
        // Curled Spiral Tail
        s.add(_makeStroke([
          Offset(c.dx + m * 0.16, c.dy),
          Offset(c.dx + m * 0.26, c.dy + m * 0.12),
          Offset(c.dx + m * 0.20, c.dy + m * 0.24),
          Offset(c.dx + m * 0.12, c.dy + m * 0.18),
          Offset(c.dx + m * 0.15, c.dy + m * 0.12),
        ], size: 5.0));
        // Branch
        s.add(_makeStroke([Offset(c.dx - m * 0.42, c.dy + m * 0.18), Offset(c.dx + m * 0.42, c.dy + m * 0.18)], size: 6.0));
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. CHARACTERS & ANIME (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateCharacters(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // Chibi Magical Star Girl
        final hY = c.dy - m * 0.08;
        s.add(_makeCircle(Offset(c.dx, hY), m * 0.20, size: 4.5));
        // Twintails
        s.add(_makePetal(Offset(c.dx - m * 0.18, hY - m * 0.04), 0, m * 0.32, pi * 0.8, 0.4, size: 4.5));
        s.add(_makePetal(Offset(c.dx + m * 0.18, hY - m * 0.04), 0, m * 0.32, pi * 0.2, 0.4, size: 4.5));
        // Anime sparkle eyes
        for (final sign in [-1.0, 1.0]) {
          final eX = c.dx + sign * m * 0.08;
          s.add(_makeCircle(Offset(eX, hY + m * 0.02), m * 0.045, size: 4.0));
          s.add(_makeCircle(Offset(eX - sign * 3, hY), m * 0.015, size: 2.5));
        }
        s.add(_makeArc(Offset(c.dx, hY + m * 0.08), m * 0.03, 0.2, pi - 0.4, size: 3.5));
        // Star Wand
        s.add(_makeStroke([Offset(c.dx + m * 0.18, c.dy + m * 0.32), Offset(c.dx + m * 0.26, c.dy + m * 0.02)], size: 4.0));
        s.add(_makeStar(Offset(c.dx + m * 0.26, c.dy + m * 0.02), m * 0.07, m * 0.03, 5, size: 3.5));
        break;

      case 1: // Manga Samurai Warrior
        final sY = c.dy - m * 0.06;
        s.add(_makeCircle(Offset(c.dx, sY), m * 0.20, size: 4.5));
        // Topknot Chonmage
        s.add(_makeCircle(Offset(c.dx, sY - m * 0.22), m * 0.06, size: 4.0));
        s.add(_makeStroke([Offset(c.dx, sY - m * 0.16), Offset(c.dx, sY - m * 0.24)], size: 5.0));
        // Determined Eyes & Headband
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.20, sY - m * 0.10, m * 0.40, m * 0.06), size: 3.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.12, sY + m * 0.02), Offset(c.dx - m * 0.04, sY + m * 0.02)], size: 4.0));
        s.add(_makeStroke([Offset(c.dx + m * 0.04, sY + m * 0.02), Offset(c.dx + m * 0.12, sY + m * 0.02)], size: 4.0));
        // Katana Sword
        s.add(_makeStroke([Offset(c.dx - m * 0.28, c.dy + m * 0.34), Offset(c.dx + m * 0.28, c.dy + m * 0.12)], size: 5.0));
        break;

      case 2: // Cyber Hacker Android
        final aY = c.dy - m * 0.06;
        s.add(_makeCircle(Offset(c.dx, aY), m * 0.20, size: 4.5));
        // Holographic Eye Visor
        s.add(_makePolygon(Offset(c.dx, aY), m * 0.15, 4, startAngle: pi / 4, size: 4.0));
        // Headphone earpieces
        s.add(_makeCircle(Offset(c.dx - m * 0.21, aY), m * 0.06, size: 4.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.21, aY), m * 0.06, size: 4.0));
        // Cyber Panel Lines on face
        s.add(_makeStroke([Offset(c.dx - m * 0.12, aY + m * 0.10), Offset(c.dx - m * 0.04, aY + m * 0.16)], size: 2.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.12, aY + m * 0.10), Offset(c.dx + m * 0.04, aY + m * 0.16)], size: 2.5));
        break;

      case 3: // Cute Chibi Catgirl
        final cY = c.dy - m * 0.04;
        s.add(_makeCircle(Offset(c.dx, cY), m * 0.20, size: 4.5));
        // Cat Ears
        s.add(_makePolygon(Offset(c.dx - m * 0.14, cY - m * 0.18), m * 0.10, 3, startAngle: -pi * 0.6, size: 4.5));
        s.add(_makePolygon(Offset(c.dx + m * 0.14, cY - m * 0.18), m * 0.10, 3, startAngle: -pi * 0.4, size: 4.5));
        // Bell Choker
        s.add(_makeStroke([Offset(c.dx - m * 0.12, cY + m * 0.20), Offset(c.dx + m * 0.12, cY + m * 0.20)], size: 4.0));
        s.add(_makeCircle(Offset(c.dx, cY + m * 0.24), m * 0.04, size: 3.5));
        // Cute Wink
        s.add(_makeCircle(Offset(c.dx - m * 0.08, cY + m * 0.02), m * 0.04, size: 4.0));
        s.add(_makeArc(Offset(c.dx + m * 0.08, cY + m * 0.02), m * 0.035, pi * 0.2, pi * 0.6, size: 4.0));
        break;

      case 4: // Celestial Moon Princess
        final mY = c.dy - m * 0.06;
        s.add(_makeCircle(Offset(c.dx, mY), m * 0.18, size: 4.5));
        // Crescent Tiara
        s.add(_makeArc(Offset(c.dx, mY - m * 0.18), m * 0.06, -pi * 0.7, pi * 1.4, size: 4.0));
        // Flowing Hair
        s.add(_makeStroke([
          Offset(c.dx - m * 0.18, mY - m * 0.05),
          Offset(c.dx - m * 0.32, c.dy + m * 0.18),
          Offset(c.dx - m * 0.20, c.dy + m * 0.38),
        ], size: 4.5));
        s.add(_makeStroke([
          Offset(c.dx + m * 0.18, mY - m * 0.05),
          Offset(c.dx + m * 0.32, c.dy + m * 0.18),
          Offset(c.dx + m * 0.20, c.dy + m * 0.38),
        ], size: 4.5));
        break;

      case 5: // Forest Elf Ranger
        final eY = c.dy - m * 0.06;
        s.add(_makeCircle(Offset(c.dx, eY), m * 0.18, size: 4.5));
        // Pointed Elf Ears
        s.add(_makePolygon(Offset(c.dx - m * 0.20, eY - m * 0.02), m * 0.10, 3, startAngle: pi * 0.9, size: 4.0));
        s.add(_makePolygon(Offset(c.dx + m * 0.20, eY - m * 0.02), m * 0.10, 3, startAngle: 0.1, size: 4.0));
        // Hooded Cowl
        s.add(_makeArc(Offset(c.dx, eY - m * 0.08), m * 0.24, -pi * 0.9, pi * 0.8, size: 4.5));
        // Recurve Bow
        s.add(_makeArc(Offset(c.dx + m * 0.28, c.dy + m * 0.08), m * 0.24, -pi * 0.6, pi * 1.2, size: 4.5));
        break;

      case 6: // Retro Chibi Gamer
        final gY = c.dy - m * 0.04;
        s.add(_makeCircle(Offset(c.dx, gY), m * 0.18, size: 4.5));
        // Huge Gaming Headset
        s.add(_makeArc(Offset(c.dx, gY - m * 0.10), m * 0.22, -pi * 0.8, pi * 0.6, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.20, gY), m * 0.06, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.20, gY), m * 0.06, size: 4.5));
        // Handheld Game Console
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.16, c.dy + m * 0.18, m * 0.32, m * 0.16), size: 4.5));
        s.add(_makePolygon(Offset(c.dx - m * 0.08, c.dy + m * 0.26), m * 0.035, 4, size: 3.5)); // D-pad
        s.add(_makeCircle(Offset(c.dx + m * 0.08, c.dy + m * 0.26), m * 0.02, size: 3.5)); // Button
        break;

      case 7: // Steampunk Aviator
        final vY = c.dy - m * 0.06;
        s.add(_makeCircle(Offset(c.dx, vY), m * 0.18, size: 4.5));
        // Brass Goggles on forehead
        s.add(_makeCircle(Offset(c.dx - m * 0.09, vY - m * 0.12), m * 0.055, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.09, vY - m * 0.12), m * 0.055, size: 4.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.04, vY - m * 0.12), Offset(c.dx + m * 0.04, vY - m * 0.12)], size: 4.0));
        // Flight Scarf
        s.add(_makeStroke([
          Offset(c.dx - m * 0.14, vY + m * 0.18),
          Offset(c.dx + m * 0.24, vY + m * 0.24),
          Offset(c.dx + m * 0.34, vY + m * 0.38),
        ], size: 5.0));
        break;

      case 8: // Little Wizard Apprentice
        final wY = c.dy + m * 0.02;
        s.add(_makeCircle(Offset(c.dx, wY), m * 0.16, size: 4.5));
        // Big Crooked Wizard Hat
        s.add(_makeStroke([
          Offset(c.dx - m * 0.32, wY - m * 0.08),
          Offset(c.dx + m * 0.32, wY - m * 0.08),
        ], size: 5.5)); // Brim
        s.add(_makeStroke([
          Offset(c.dx - m * 0.20, wY - m * 0.08),
          Offset(c.dx, wY - m * 0.38),
          Offset(c.dx + m * 0.12, wY - m * 0.32),
          Offset(c.dx + m * 0.20, wY - m * 0.08),
        ], size: 4.5));
        // Round Glasses
        s.add(_makeCircle(Offset(c.dx - m * 0.06, wY + m * 0.02), m * 0.04, size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.06, wY + m * 0.02), m * 0.04, size: 3.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.02, wY + m * 0.02), Offset(c.dx + m * 0.02, wY + m * 0.02)], size: 3.5));
        break;

      case 9: // Chibi Superhero
        final pY = c.dy - m * 0.06;
        s.add(_makeCircle(Offset(c.dx, pY), m * 0.18, size: 4.5));
        // Domino Mask
        s.add(_makeEllipse(Offset(c.dx, pY), m * 0.15, m * 0.05, size: 4.0));
        // Cape fluttering behind
        s.add(_makeStroke([
          Offset(c.dx - m * 0.14, pY + m * 0.16),
          Offset(c.dx - m * 0.34, c.dy + m * 0.34),
          Offset(c.dx + m * 0.34, c.dy + m * 0.34),
          Offset(c.dx + m * 0.14, pY + m * 0.16),
        ], size: 4.5));
        // Chest Emblem
        s.add(_makePolygon(Offset(c.dx, pY + m * 0.24), m * 0.05, 5, size: 3.5));
        break;

      case 10: // 🦊 Kitsune Fox Spirit Maiden
        final kY = c.dy - m * 0.08;
        s.add(_makeCircle(Offset(c.dx, kY), m * 0.19, size: 4.5));
        // Pointed Fox Ears with Inner Ear details
        s.add(_makePolygon(Offset(c.dx - m * 0.14, kY - m * 0.18), m * 0.09, 3, startAngle: -pi * 0.6, size: 4.5));
        s.add(_makePolygon(Offset(c.dx - m * 0.14, kY - m * 0.18), m * 0.05, 3, startAngle: -pi * 0.6, size: 3.0));
        s.add(_makePolygon(Offset(c.dx + m * 0.14, kY - m * 0.18), m * 0.09, 3, startAngle: -pi * 0.4, size: 4.5));
        s.add(_makePolygon(Offset(c.dx + m * 0.14, kY - m * 0.18), m * 0.05, 3, startAngle: -pi * 0.4, size: 3.0));
        // Kitsune Mask on side of head with slit eye & tassel
        s.add(_makeEllipse(Offset(c.dx + m * 0.18, kY - m * 0.08), m * 0.08, m * 0.055, rotation: -0.25, size: 4.0));
        s.add(_makeStroke([Offset(c.dx + m * 0.13, kY - m * 0.08), Offset(c.dx + m * 0.23, kY - m * 0.08)], size: 3.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.24, kY - m * 0.04), Offset(c.dx + m * 0.26, kY + m * 0.12)], size: 3.0));
        // Anime Eyes & Whiskers
        for (final sign in [-1.0, 1.0]) {
          final eX = c.dx + sign * m * 0.08;
          s.add(_makeArc(Offset(eX, kY + m * 0.02), m * 0.04, pi * 0.1, pi * 0.8, size: 4.0));
          s.add(_makeCircle(Offset(eX, kY + m * 0.02), m * 0.025, size: 3.5));
          s.add(_makeStroke([Offset(c.dx + sign * m * 0.14, kY + m * 0.06), Offset(c.dx + sign * m * 0.20, kY + m * 0.05)], size: 2.5));
        }
        // Kimono Collar Wrap
        s.add(_makeStroke([Offset(c.dx - m * 0.16, kY + m * 0.16), Offset(c.dx, kY + m * 0.26), Offset(c.dx + m * 0.16, kY + m * 0.16)], size: 4.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.12, kY + m * 0.18), Offset(c.dx, kY + m * 0.28), Offset(c.dx + m * 0.12, kY + m * 0.18)], size: 3.0));
        // Spirit Fox Tails curving around
        s.add(_makePetal(Offset(c.dx - m * 0.25, c.dy + m * 0.18), 0, m * 0.28, pi * 0.82, 0.42, size: 5.0));
        s.add(_makePetal(Offset(c.dx + m * 0.25, c.dy + m * 0.18), 0, m * 0.28, pi * 0.18, 0.42, size: 5.0));
        break;

      case 11: // 🥷 Cyber Ninja Shinobi
        final nY = c.dy - m * 0.08;
        s.add(_makeCircle(Offset(c.dx, nY), m * 0.19, size: 4.5));
        // Ninja Cowl Hood & High Collar
        s.add(_makeArc(Offset(c.dx, nY - m * 0.06), m * 0.24, -pi * 0.9, pi * 0.8, size: 5.0));
        // High-Tech Cyber Visor Slit
        s.add(_makeRect(Rect.fromCenter(center: Offset(c.dx, nY), width: m * 0.26, height: m * 0.05), size: 4.0));
        s.add(_makeStroke([Offset(c.dx - m * 0.10, nY), Offset(c.dx + m * 0.10, nY)], size: 2.5));
        // Ninja Mouth Guard Plate
        s.add(_makeStroke([Offset(c.dx - m * 0.10, nY + m * 0.08), Offset(c.dx, nY + m * 0.16), Offset(c.dx + m * 0.10, nY + m * 0.08)], size: 4.0));
        // Large 4-Point Shuriken in foreground
        s.add(_makeStar(Offset(c.dx + m * 0.24, c.dy + m * 0.20), m * 0.14, m * 0.05, 4, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.24, c.dy + m * 0.20), m * 0.035, size: 3.5));
        // Flowing Shinobi Scarf Flutter
        s.add(_makeStroke([
          Offset(c.dx - m * 0.10, nY + m * 0.12),
          Offset(c.dx - m * 0.30, c.dy + m * 0.18),
          Offset(c.dx - m * 0.38, c.dy + m * 0.34),
        ], size: 5.0));
        break;

      case 12: // ⚡ Shonen Saiyan Energy Hero
        final fY = c.dy - m * 0.04;
        s.add(_makeCircle(Offset(c.dx, fY), m * 0.18, size: 4.5));
        // Dramatic Spiky Electric Hair
        s.add(_makeStroke([Offset(c.dx - m * 0.20, fY - m * 0.06), Offset(c.dx - m * 0.32, fY - m * 0.20), Offset(c.dx - m * 0.16, fY - m * 0.16)], size: 5.0));
        s.add(_makeStroke([Offset(c.dx - m * 0.16, fY - m * 0.16), Offset(c.dx - m * 0.22, fY - m * 0.34), Offset(c.dx - m * 0.06, fY - m * 0.22)], size: 5.0));
        s.add(_makeStroke([Offset(c.dx - m * 0.06, fY - m * 0.22), Offset(c.dx, fY - m * 0.40), Offset(c.dx + m * 0.06, fY - m * 0.22)], size: 5.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.06, fY - m * 0.22), Offset(c.dx + m * 0.22, fY - m * 0.34), Offset(c.dx + m * 0.16, fY - m * 0.16)], size: 5.0));
        s.add(_makeStroke([Offset(c.dx + m * 0.16, fY - m * 0.16), Offset(c.dx + m * 0.32, fY - m * 0.20), Offset(c.dx + m * 0.20, fY - m * 0.06)], size: 5.0));
        // Fierce Brow & Eyes
        s.add(_makeStroke([Offset(c.dx - m * 0.11, fY - m * 0.05), Offset(c.dx - m * 0.03, fY - m * 0.02)], size: 4.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.11, fY - m * 0.05), Offset(c.dx + m * 0.03, fY - m * 0.02)], size: 4.5));
        s.add(_makePolygon(Offset(c.dx - m * 0.07, fY + m * 0.02), m * 0.03, 3, size: 3.5));
        s.add(_makePolygon(Offset(c.dx + m * 0.07, fY + m * 0.02), m * 0.03, 3, size: 3.5));
        // Ki Aura Flares on sides
        s.add(_makePetal(Offset(c.dx - m * 0.28, c.dy + m * 0.12), 0, m * 0.24, pi * 0.72, 0.4, size: 4.5));
        s.add(_makePetal(Offset(c.dx + m * 0.28, c.dy + m * 0.12), 0, m * 0.24, pi * 0.28, 0.4, size: 4.5));
        // Gi Uniform Collar
        s.add(_makeStroke([Offset(c.dx - m * 0.16, fY + m * 0.16), Offset(c.dx, fY + m * 0.26), Offset(c.dx + m * 0.16, fY + m * 0.16)], size: 4.5));
        break;

      case 13: // 🤖 Mecha Titan Pilot Hero
        final mechaY = c.dy - m * 0.06;
        s.add(_makeCircle(Offset(c.dx, mechaY), m * 0.20, size: 5.0));
        // Aerodynamic Headset Fins
        s.add(_makePolygon(Offset(c.dx - m * 0.22, mechaY - m * 0.14), m * 0.08, 3, startAngle: -pi * 0.75, size: 4.0));
        s.add(_makePolygon(Offset(c.dx + m * 0.22, mechaY - m * 0.14), m * 0.08, 3, startAngle: -pi * 0.25, size: 4.0));
        // Hexagonal HUD Visor with crosshair
        s.add(_makePolygon(Offset(c.dx, mechaY), m * 0.12, 6, size: 4.5));
        s.add(_makeCircle(Offset(c.dx, mechaY), m * 0.04, size: 3.0));
        s.add(_makeStroke([Offset(c.dx - m * 0.10, mechaY), Offset(c.dx + m * 0.10, mechaY)], size: 2.0));
        s.add(_makeStroke([Offset(c.dx, mechaY - m * 0.09), Offset(c.dx, mechaY + m * 0.09)], size: 2.0));
        // Pilot Plugsuit Armor & Core Reactor
        s.add(_makeCircle(Offset(c.dx, c.dy + m * 0.24), m * 0.06, size: 4.5));
        s.add(_makePolygon(Offset(c.dx, c.dy + m * 0.24), m * 0.035, 3, size: 3.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.18, c.dy + m * 0.18), Offset(c.dx + m * 0.18, c.dy + m * 0.18)], size: 4.5));
        break;

      case 14: // 🧋 Kawaii Anime Boba Barista
        final bY = c.dy - m * 0.12;
        s.add(_makeCircle(Offset(c.dx, bY), m * 0.18, size: 4.5));
        // Cute Bear Ears Headband
        s.add(_makeCircle(Offset(c.dx - m * 0.14, bY - m * 0.16), m * 0.06, size: 4.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.14, bY - m * 0.16), m * 0.06, size: 4.0));
        // Big Sparkling Anime Eyes & Blush
        s.add(_makeCircle(Offset(c.dx - m * 0.08, bY + m * 0.02), m * 0.045, size: 4.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.07, bY), m * 0.018, size: 2.5));
        s.add(_makeArc(Offset(c.dx + m * 0.08, bY + m * 0.02), m * 0.04, 0.2, pi - 0.4, size: 4.0));
        s.add(_makeArc(Offset(c.dx, bY + m * 0.08), m * 0.03, 0.2, pi - 0.4, size: 3.5));
        // Giant Boba Cup in hands
        final cupTop = bY + m * 0.18;
        s.add(_makeStroke([
          Offset(c.dx - m * 0.14, cupTop),
          Offset(c.dx - m * 0.10, cupTop + m * 0.32),
          Offset(c.dx + m * 0.10, cupTop + m * 0.32),
          Offset(c.dx + m * 0.14, cupTop),
          Offset(c.dx - m * 0.14, cupTop),
        ], size: 4.5));
        // Dome Lid & Big Boba Straw
        s.add(_makeArc(Offset(c.dx, cupTop), m * 0.14, -pi, pi, size: 4.0));
        s.add(_makeStroke([Offset(c.dx + m * 0.04, cupTop - m * 0.14), Offset(c.dx + m * 0.04, cupTop + m * 0.26)], size: 6.0));
        // Tapioca Pearls inside cup bottom
        s.add(_makeCircle(Offset(c.dx - m * 0.05, cupTop + m * 0.24), m * 0.025, size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.03, cupTop + m * 0.25), m * 0.025, size: 3.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.01, cupTop + m * 0.20), m * 0.025, size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.05, cupTop + m * 0.19), m * 0.025, size: 3.5));
        break;

      case 15: // 🌸 Sakura Blossom Blade Maiden
        final sakY = c.dy - m * 0.08;
        s.add(_makeCircle(Offset(c.dx, sakY), m * 0.18, size: 4.5));
        // 5-Petal Sakura Flower in Hair
        final sP = Offset(c.dx - m * 0.15, sakY - m * 0.14);
        for (int i = 0; i < 5; i++) {
          s.add(_makePetal(sP, 0, m * 0.05, (2 * pi / 5) * i, 0.42, size: 3.5));
        }
        s.add(_makeCircle(sP, m * 0.015, size: 3.0));
        // Flowing Silky Hair Waves
        s.add(_makePetal(Offset(c.dx - m * 0.18, sakY), 0, m * 0.36, pi * 0.8, 0.35, size: 4.5));
        s.add(_makePetal(Offset(c.dx + m * 0.18, sakY), 0, m * 0.36, pi * 0.2, 0.35, size: 4.5));
        // Kimono Collar & Sash
        s.add(_makeStroke([Offset(c.dx - m * 0.14, sakY + m * 0.16), Offset(c.dx, sakY + m * 0.26), Offset(c.dx + m * 0.14, sakY + m * 0.16)], size: 4.5));
        // Sleek Katana Sheath across back
        s.add(_makeStroke([Offset(c.dx - m * 0.32, c.dy + m * 0.32), Offset(c.dx + m * 0.28, c.dy - m * 0.04)], size: 5.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.28, c.dy - m * 0.04), m * 0.035, size: 4.0));
        break;

      default: // Chibi Superhero
        final pY = c.dy - m * 0.06;
        s.add(_makeCircle(Offset(c.dx, pY), m * 0.18, size: 4.5));
        // Domino Mask
        s.add(_makeEllipse(Offset(c.dx, pY), m * 0.15, m * 0.05, size: 4.0));
        // Cape fluttering behind
        s.add(_makeStroke([
          Offset(c.dx - m * 0.14, pY + m * 0.16),
          Offset(c.dx - m * 0.34, c.dy + m * 0.34),
          Offset(c.dx + m * 0.34, c.dy + m * 0.34),
          Offset(c.dx + m * 0.14, pY + m * 0.16),
        ], size: 4.5));
        // Chest Emblem
        s.add(_makePolygon(Offset(c.dx, pY + m * 0.24), m * 0.05, 5, size: 3.5));
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. SPACE & COSMOS (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateSpace(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // Ringed Saturn & Moonlet
        s.add(_makeCircle(c, m * 0.18, size: 5.0));
        s.add(_makeArc(c, m * 0.18, -0.4, 0.8, size: 3.0));
        s.add(_makeArc(c, m * 0.18, pi - 0.4, 0.8, size: 3.0));
        s.add(_makeEllipse(c, m * 0.40, m * 0.14, rotation: 0.4, size: 4.5));
        s.add(_makeEllipse(c, m * 0.44, m * 0.16, rotation: 0.4, size: 2.8));
        s.add(_makeCircle(Offset(c.dx + m * 0.32, c.dy - m * 0.24), m * 0.03, size: 3.5));
        break;

      case 1: // Apollo Lunar Lander
        final landY = c.dy + m * 0.06;
        s.add(_makePolygon(Offset(c.dx, landY), m * 0.16, 4, startAngle: pi / 4, size: 4.5));
        s.add(_makeCircle(Offset(c.dx, landY - m * 0.04), m * 0.05, size: 3.5));
        // 4 Legs
        s.add(_makeStroke([Offset(c.dx - m * 0.12, landY + m * 0.10), Offset(c.dx - m * 0.26, landY + m * 0.28)], size: 4.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.12, landY + m * 0.10), Offset(c.dx + m * 0.26, landY + m * 0.28)], size: 4.5));
        // Moon surface craters
        s.add(_makeArc(Offset(c.dx, c.dy + m * 0.44), m * 0.46, -pi * 0.85, pi * 0.7, size: 4.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.18, c.dy + m * 0.35), m * 0.04, size: 3.0));
        break;

      case 2: // Spacewalking Astronaut
        final aY = c.dy - m * 0.06;
        // Big Bubble Helmet
        s.add(_makeCircle(Offset(c.dx, aY), m * 0.16, size: 5.0));
        s.add(_makeEllipse(Offset(c.dx, aY), m * 0.11, m * 0.07, size: 4.0)); // Visor
        // Spacesuit Body
        s.add(_makeStroke([
          Offset(c.dx - m * 0.14, aY + m * 0.14),
          Offset(c.dx - m * 0.18, c.dy + m * 0.26),
          Offset(c.dx + m * 0.18, c.dy + m * 0.26),
          Offset(c.dx + m * 0.14, aY + m * 0.14),
        ], size: 4.5));
        // Tether line
        s.add(_makeArc(Offset(c.dx - m * 0.20, c.dy), m * 0.25, 0.4, pi * 0.8, size: 3.5));
        break;

      case 3: // Alien Flying Saucer UFO
        final uY = c.dy - m * 0.08;
        // Dome
        s.add(_makeArc(Offset(c.dx, uY), m * 0.16, -pi * 0.95, pi * 0.9, size: 4.5));
        // Disc Saucer Body
        s.add(_makeEllipse(Offset(c.dx, uY + m * 0.05), m * 0.38, m * 0.10, size: 5.0));
        // Rim Thruster lights
        for (int i = -3; i <= 3; i++) {
          s.add(_makeCircle(Offset(c.dx + i * (m * 0.09), uY + m * 0.05), m * 0.02, size: 3.0));
        }
        // Conical Tractor Beam
        s.add(_makeStroke([
          Offset(c.dx - m * 0.16, uY + m * 0.10),
          Offset(c.dx - m * 0.36, c.dy + m * 0.42),
          Offset(c.dx + m * 0.36, c.dy + m * 0.42),
          Offset(c.dx + m * 0.16, uY + m * 0.10),
        ], size: 3.5));
        break;

      case 4: // Cosmic Swirling Galaxy
        s.add(_makeCircle(c, m * 0.08, size: 4.5));
        s.add(_makeCircle(c, m * 0.04, size: 3.0));
        for (int arm = 0; arm < 2; arm++) {
          final startA = arm * pi;
          final pts = <Offset>[];
          for (int step = 0; step <= 30; step++) {
            final t = step / 30.0;
            final r = m * (0.08 + t * 0.34);
            final a = startA + t * 2.8;
            pts.add(Offset(c.dx + r * cos(a), c.dy + r * sin(a)));
          }
          s.add(_makeStroke(pts, size: 4.0));
        }
        for (int i = 0; i < 8; i++) {
          final a = (2 * pi / 8) * i;
          s.add(_makeStar(Offset(c.dx + m * 0.34 * cos(a), c.dy + m * 0.34 * sin(a)), m * 0.035, m * 0.015, 4, size: 2.8));
        }
        break;

      case 5: // Crescent Moon with Hanging Stars
        final mX = c.dx - m * 0.06;
        s.add(_makeArc(Offset(mX, c.dy), m * 0.34, -pi * 0.75, pi * 1.5, size: 5.5));
        s.add(_makeArc(Offset(mX + m * 0.14, c.dy), m * 0.28, -pi * 0.65, pi * 1.3, size: 5.5));
        // Hanging Lantern
        s.add(_makeStroke([Offset(mX + m * 0.22, c.dy - m * 0.15), Offset(mX + m * 0.22, c.dy + m * 0.08)], size: 3.0));
        s.add(_makePolygon(Offset(mX + m * 0.22, c.dy + m * 0.14), m * 0.06, 6, size: 3.5));
        s.add(_makeStar(Offset(c.dx + m * 0.24, c.dy - m * 0.24), m * 0.05, m * 0.02, 5, size: 3.5));
        break;

      case 6: // Rocket Launch Liftoff
        final rY = c.dy - m * 0.05;
        s.add(_makeStroke([
          Offset(c.dx - m * 0.10, rY + m * 0.22),
          Offset(c.dx - m * 0.10, rY - m * 0.10),
          Offset(c.dx, rY - m * 0.34),
          Offset(c.dx + m * 0.10, rY - m * 0.10),
          Offset(c.dx + m * 0.10, rY + m * 0.22),
          Offset(c.dx - m * 0.10, rY + m * 0.22),
        ], size: 5.0));
        s.add(_makeCircle(Offset(c.dx, rY), m * 0.06, size: 4.0));
        // Exhaust Smoke Plumes
        for (final sign in [-1.0, 1.0]) {
          s.add(_makeCircle(Offset(c.dx + sign * m * 0.18, c.dy + m * 0.32), m * 0.10, size: 4.0));
        }
        break;

      case 7: // Solar Eclipse Halo
        s.add(_makeCircle(c, m * 0.20, size: 6.0));
        for (int i = 0; i < 24; i++) {
          final a = (2 * pi / 24) * i;
          final rOut = m * (0.24 + (i % 3 == 0 ? 0.16 : 0.08));
          s.add(_makeStroke([
            Offset(c.dx + m * 0.20 * cos(a), c.dy + m * 0.20 * sin(a)),
            Offset(c.dx + rOut * cos(a), c.dy + rOut * sin(a)),
          ], size: 3.2));
        }
        break;

      case 8: // Orbital Space Station
        s.add(_makeCircle(c, m * 0.09, size: 4.5));
        // Solar Wing Left & Right
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.40, c.dy - m * 0.06, m * 0.24, m * 0.12), size: 4.0));
        s.add(_makeRect(Rect.fromLTWH(c.dx + m * 0.16, c.dy - m * 0.06, m * 0.24, m * 0.12), size: 4.0));
        s.add(_makeStroke([Offset(c.dx, c.dy - m * 0.09), Offset(c.dx, c.dy - m * 0.24)], size: 4.0));
        s.add(_makeArc(Offset(c.dx, c.dy - m * 0.28), m * 0.06, 0.2, pi - 0.4, size: 4.0)); // Dish
        break;

      default: // Blazing Shooting Comet
        final cmX = c.dx - m * 0.18;
        final cmY = c.dy + m * 0.18;
        s.add(_makeCircle(Offset(cmX, cmY), m * 0.08, size: 5.0));
        // Speed trail streaks
        for (int i = -2; i <= 2; i++) {
          s.add(_makeStroke([
            Offset(cmX + i * 10, cmY + i * 10),
            Offset(c.dx + m * 0.38 + i * 15, c.dy - m * 0.35 + i * 15),
          ], size: 3.5));
        }
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. FANTASY & MYTH (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateFantasy(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // Fierce Winged Dragon
        final dY = c.dy - m * 0.06;
        // Dragon Head
        s.add(_makeStroke([
          Offset(c.dx - m * 0.26, dY), // Snout
          Offset(c.dx - m * 0.04, dY - m * 0.12), // Crown
          Offset(c.dx + m * 0.16, dY - m * 0.26), // Horn tip
          Offset(c.dx + m * 0.08, dY - m * 0.06), // Horn base
          Offset(c.dx + m * 0.18, dY + m * 0.12), // Neck
          Offset(c.dx - m * 0.06, dY + m * 0.16), // Jaw
          Offset(c.dx - m * 0.26, dY),
        ], size: 5.0));
        // Eye & Fangs
        s.add(_makeCircle(Offset(c.dx - m * 0.08, dY - m * 0.04), m * 0.03, size: 4.0));
        s.add(_makePolygon(Offset(c.dx - m * 0.16, dY + m * 0.08), m * 0.03, 3, startAngle: pi / 2, size: 3.5));
        // Smoke wisps
        s.add(_makeArc(Offset(c.dx - m * 0.34, dY - m * 0.06), m * 0.08, -pi * 0.8, pi * 0.9, size: 3.5));
        break;

      case 1: // Phoenix Rebirth
        s.add(_makeCircle(Offset(c.dx, c.dy - m * 0.16), m * 0.07, size: 4.5));
        s.add(_makePolygon(Offset(c.dx + m * 0.08, c.dy - m * 0.16), m * 0.035, 3, size: 4.0)); // Beak
        // Flaming Wings
        for (final sign in [-1.0, 1.0]) {
          for (int f = 0; f < 4; f++) {
            final a = -pi * 0.7 + sign * f * 0.25;
            s.add(_makePetal(Offset(c.dx, c.dy - m * 0.08), m * 0.08, m * 0.38, a, 0.18, size: 3.8));
          }
        }
        // Flowing Tail Feathers
        for (final tx in [-m * 0.08, 0.0, m * 0.08]) {
          s.add(_makeStroke([
            Offset(c.dx + tx, c.dy + m * 0.08),
            Offset(c.dx + tx * 1.8, c.dy + m * 0.38),
          ], size: 4.5));
        }
        break;

      case 2: // Enchanted Fairy on Mushroom
        final toadY = c.dy + m * 0.12;
        s.add(_makeArc(Offset(c.dx, toadY), m * 0.26, -pi, pi, size: 4.5));
        s.add(_makeStroke([Offset(c.dx, toadY), Offset(c.dx, c.dy + m * 0.40)], size: 5.5));
        // Seated Fairy Silhouette
        s.add(_makeCircle(Offset(c.dx, toadY - m * 0.20), m * 0.055, size: 4.0));
        // Dragonfly Wings
        s.add(_makePetal(Offset(c.dx - m * 0.04, toadY - m * 0.12), 0, m * 0.26, -pi * 0.85, 0.2, size: 3.5));
        s.add(_makePetal(Offset(c.dx + m * 0.04, toadY - m * 0.12), 0, m * 0.26, -pi * 0.15, 0.2, size: 3.5));
        break;

      case 3: // Mystical Horned Unicorn
        final uY = c.dy - m * 0.02;
        s.add(_makeStroke([
          Offset(c.dx - m * 0.22, uY + m * 0.06), // Muzzle
          Offset(c.dx - m * 0.08, uY - m * 0.10), // Forehead
          Offset(c.dx + m * 0.06, uY - m * 0.14), // Poll
          Offset(c.dx + m * 0.16, uY + m * 0.22), // Neck
          Offset(c.dx - m * 0.02, uY + m * 0.20),
          Offset(c.dx - m * 0.22, uY + m * 0.06),
        ], size: 4.8));
        // Spiral Horn
        s.add(_makeStroke([
          Offset(c.dx - m * 0.06, uY - m * 0.10),
          Offset(c.dx + m * 0.14, uY - m * 0.38),
          Offset(c.dx - m * 0.02, uY - m * 0.12),
        ], size: 4.5));
        // Eye
        s.add(_makeCircle(Offset(c.dx - m * 0.06, uY - m * 0.02), m * 0.025, size: 4.0));
        break;

      case 4: // Flying Pegasus
        s.add(_makeCircle(Offset(c.dx - m * 0.14, c.dy - m * 0.08), m * 0.12, size: 4.5)); // Head
        s.add(_makeEllipse(Offset(c.dx + m * 0.04, c.dy + m * 0.06), m * 0.20, m * 0.12, size: 4.5)); // Body
        // Feathered Wing Outstretched
        s.add(_makePetal(Offset(c.dx, c.dy), 0, m * 0.38, -pi * 0.65, 0.35, size: 5.0));
        for (int i = 1; i <= 3; i++) {
          s.add(_makePetal(Offset(c.dx, c.dy), 0, m * (0.38 - i * 0.06), -pi * 0.65 + i * 0.15, 0.3, size: 3.5));
        }
        break;

      case 5: // Arcane Magic Potion Bottle
        final potY = c.dy + m * 0.06;
        s.add(_makeCircle(Offset(c.dx, potY), m * 0.22, size: 5.0));
        // Neck & Cork
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.06, potY - m * 0.28, m * 0.12, m * 0.12), size: 4.0));
        s.add(_makePolygon(Offset(c.dx, potY - m * 0.32), m * 0.07, 4, startAngle: pi / 4, size: 4.0));
        // Swirling magical liquid inside
        s.add(_makeArc(Offset(c.dx, potY + m * 0.04), m * 0.16, -0.4, pi + 0.8, size: 3.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.06, potY), m * 0.03, size: 2.8));
        s.add(_makeCircle(Offset(c.dx + m * 0.06, potY + m * 0.06), m * 0.02, size: 2.5));
        break;

      case 6: // Crystal Spire Castle
        final cY = c.dy + m * 0.18;
        // Floating Rock base
        s.add(_makePolygon(Offset(c.dx, cY), m * 0.32, 6, size: 4.5));
        // Towers & Spires
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.08, cY - m * 0.36, m * 0.16, m * 0.36), size: 4.0));
        s.add(_makePolygon(Offset(c.dx, cY - m * 0.44), m * 0.12, 3, startAngle: -pi / 2, size: 4.0));
        for (final sign in [-1.0, 1.0]) {
          final sX = c.dx + sign * m * 0.16;
          s.add(_makeRect(Rect.fromLTWH(sX - m * 0.05, cY - m * 0.26, m * 0.10, m * 0.26), size: 3.5));
          s.add(_makePolygon(Offset(sX, cY - m * 0.32), m * 0.08, 3, startAngle: -pi / 2, size: 3.5));
        }
        break;

      case 7: // Gryphon Guardian
        s.add(_makeCircle(Offset(c.dx - m * 0.08, c.dy - m * 0.10), m * 0.12, size: 4.5));
        // Eagle Beak
        s.add(_makeStroke([
          Offset(c.dx - m * 0.08, c.dy - m * 0.10),
          Offset(c.dx - m * 0.25, c.dy - m * 0.04),
          Offset(c.dx - m * 0.16, c.dy + m * 0.02),
        ], size: 4.5));
        // Lion Ears & Crest
        s.add(_makePolygon(Offset(c.dx + m * 0.02, c.dy - m * 0.22), m * 0.08, 3, startAngle: -pi * 0.4, size: 4.0));
        s.add(_makePetal(Offset(c.dx + m * 0.08, c.dy), 0, m * 0.35, -pi * 0.6, 0.35, size: 4.5));
        break;

      case 8: // Witch Hat & Bubbling Cauldron
        final cldY = c.dy + m * 0.16;
        s.add(_makeCircle(Offset(c.dx, cldY), m * 0.20, size: 5.0));
        s.add(_makeStroke([Offset(c.dx - m * 0.20, cldY), Offset(c.dx + m * 0.20, cldY)], size: 4.5));
        // Bubbles
        s.add(_makeCircle(Offset(c.dx - m * 0.08, cldY - m * 0.08), m * 0.04, size: 3.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.06, cldY - m * 0.12), m * 0.05, size: 3.0));
        // Witch Hat
        final hY = c.dy - m * 0.18;
        s.add(_makeEllipse(Offset(c.dx, hY), m * 0.26, m * 0.07, size: 4.5));
        s.add(_makePolygon(Offset(c.dx, hY - m * 0.14), m * 0.18, 3, startAngle: -pi / 2, size: 4.5));
        break;

      default: // Celestial Sun & Moon Talisman
        s.add(_makeCircle(c, m * 0.38, size: 5.0));
        // Half Sun
        for (int i = 0; i < 8; i++) {
          final a = -pi / 2 + (pi / 7) * i;
          s.add(_makePetal(c, m * 0.24, m * 0.38, a, 0.18, size: 3.5));
        }
        // Crescent Moon face
        s.add(_makeArc(c, m * 0.24, -pi / 2, pi, size: 4.5));
        s.add(_makeArc(Offset(c.dx + m * 0.06, c.dy), m * 0.20, -pi * 0.45, pi * 0.9, size: 4.0));
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. ZENTANGLE PATTERNS (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateZentangle(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // Paisley Floral Flourish
        s.add(_makePetal(c, 0, m * 0.38, -0.6, 0.7, size: 5.0));
        s.add(_makePetal(c, 0, m * 0.28, -0.6, 0.5, size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.08, c.dy + m * 0.08), m * 0.08, size: 3.5));
        for (int i = 0; i < 8; i++) {
          final a = (2 * pi / 8) * i;
          s.add(_makeCircle(Offset(c.dx + m * 0.28 * cos(a), c.dy + m * 0.28 * sin(a)), m * 0.03, size: 2.8));
        }
        break;

      case 1: // Sacred Metatron's Cube
        s.add(_makeCircle(c, m * 0.38, size: 4.5));
        const pts = 6;
        final nodes = <Offset>[c];
        for (int i = 0; i < pts; i++) {
          final a = (2 * pi / pts) * i;
          nodes.add(Offset(c.dx + m * 0.22 * cos(a), c.dy + m * 0.22 * sin(a)));
          nodes.add(Offset(c.dx + m * 0.38 * cos(a), c.dy + m * 0.38 * sin(a)));
        }
        for (final n in nodes) {
          s.add(_makeCircle(n, m * 0.04, size: 3.0));
        }
        // Connect nodes
        for (int i = 1; i < nodes.length; i += 2) {
          s.add(_makeStroke([nodes[i], nodes[(i + 2) % nodes.length]], size: 2.5));
        }
        break;

      case 2: // Woven Celtic Ribbon Knot
        for (int i = 0; i < 4; i++) {
          final a = (pi / 2) * i;
          final p = Offset(c.dx + m * 0.16 * cos(a), c.dy + m * 0.16 * sin(a));
          s.add(_makeCircle(p, m * 0.18, size: 4.0));
        }
        s.add(_makeCircle(c, m * 0.36, size: 4.5));
        s.add(_makeCircle(c, m * 0.12, size: 3.5));
        break;

      case 3: // Honeycomb Hexagonal Matrix
        s.add(_makeCircle(c, m * 0.42, size: 5.0));
        const hexR = 40.0;
        for (int q = -2; q <= 2; q++) {
          for (int r = -2; r <= 2; r++) {
            if ((q + r).abs() <= 3) {
              final x = c.dx + hexR * 1.732 * (q + r / 2);
              final y = c.dy + hexR * 1.5 * r;
              if ((Offset(x, y) - c).distance <= m * 0.38) {
                s.add(_makePolygon(Offset(x, y), hexR * 0.85, 6, size: 3.0));
              }
            }
          }
        }
        break;

      case 4: // Optical Illusion Wave Grid
        s.add(_makeCircle(c, m * 0.42, size: 5.0));
        for (int r = 1; r <= 6; r++) {
          final rad = m * (r / 7.0) * 0.42;
          s.add(_makeCircle(c, rad, size: 3.0));
        }
        for (int i = 0; i < 16; i++) {
          final a = (2 * pi / 16) * i;
          final pts = <Offset>[c];
          for (int step = 1; step <= 10; step++) {
            final t = step / 10.0;
            final curR = m * 0.42 * t;
            final rot = sin(t * pi) * 0.35;
            pts.add(Offset(c.dx + curR * cos(a + rot), c.dy + curR * sin(a + rot)));
          }
          s.add(_makeStroke(pts, size: 2.8));
        }
        break;

      case 5: // Flowing Fish Scale Scallops
        s.add(_makeCircle(c, m * 0.42, size: 5.0));
        for (int row = -3; row <= 3; row++) {
          final y = c.dy + row * (m * 0.09);
          for (int col = -4; col <= 4; col++) {
            final x = c.dx + col * (m * 0.12) + (row % 2 == 0 ? 0 : m * 0.06);
            if ((Offset(x, y) - c).distance <= m * 0.36) {
              s.add(_makeArc(Offset(x, y), m * 0.08, -pi * 0.9, pi * 0.8, size: 3.2));
            }
          }
        }
        break;

      case 6: // Baroque Filigree Scroll
        s.add(_makeCircle(c, m * 0.42, size: 5.0));
        for (int i = 0; i < 4; i++) {
          final a = (pi / 2) * i;
          final pts = <Offset>[c];
          for (int step = 0; step <= 16; step++) {
            final t = step / 16.0;
            final rad = m * 0.36 * t;
            final spiralA = a + t * 2.0;
            pts.add(Offset(c.dx + rad * cos(spiralA), c.dy + rad * sin(spiralA)));
          }
          s.add(_makeStroke(pts, size: 3.8));
        }
        s.add(_makePolygon(c, m * 0.12, 4, startAngle: pi / 4, size: 4.0));
        break;

      case 7: // Labyrinth Maze Mandala
        s.add(_makeCircle(c, m * 0.42, size: 5.0));
        for (int r = 1; r <= 5; r++) {
          final rad = m * (0.06 + r * 0.06);
          // Split arc leaving openings
          s.add(_makeArc(c, rad, 0.4, 2 * pi - 0.8, size: 3.5));
        }
        s.add(_makeCircle(c, m * 0.05, size: 4.0));
        break;

      case 8: // Diamond Harlequin Tessellation
        s.add(_makeCircle(c, m * 0.42, size: 5.0));
        for (int i = -3; i <= 3; i++) {
          final d = i * (m * 0.10);
          s.add(_makeStroke([Offset(c.dx + d, c.dy - m * 0.38), Offset(c.dx + d + m * 0.38, c.dy)], size: 2.8));
          s.add(_makeStroke([Offset(c.dx + d, c.dy - m * 0.38), Offset(c.dx + d - m * 0.38, c.dy)], size: 2.8));
          s.add(_makeStroke([Offset(c.dx + d + m * 0.38, c.dy), Offset(c.dx + d, c.dy + m * 0.38)], size: 2.8));
          s.add(_makeStroke([Offset(c.dx + d - m * 0.38, c.dy), Offset(c.dx + d, c.dy + m * 0.38)], size: 2.8));
        }
        break;

      default: // Spiraling Vortex Ribbons
        s.add(_makeCircle(c, m * 0.42, size: 5.0));
        const ribbons = 16;
        for (int i = 0; i < ribbons; i++) {
          final a = (2 * pi / ribbons) * i;
          s.add(_makeStroke([
            c,
            Offset(c.dx + m * 0.42 * cos(a + 0.8), c.dy + m * 0.42 * sin(a + 0.8)),
          ], size: 3.0));
        }
        s.add(_makeCircle(c, m * 0.06, size: 4.5));
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. VEHICLES & MACHINES (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateVehicles(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // Classic 1950s Roadster
        final carY = c.dy + m * 0.04;
        s.add(_makeCircle(Offset(c.dx - m * 0.22, carY + m * 0.12), m * 0.08, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.22, carY + m * 0.12), m * 0.04, size: 3.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.22, carY + m * 0.12), m * 0.08, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.22, carY + m * 0.12), m * 0.04, size: 3.0));
        s.add(_makeStroke([
          Offset(c.dx - m * 0.38, carY + m * 0.08),
          Offset(c.dx - m * 0.38, carY - m * 0.02),
          Offset(c.dx - m * 0.16, carY - m * 0.04),
          Offset(c.dx - m * 0.06, carY - m * 0.14), // Windshield
          Offset(c.dx + m * 0.14, carY - m * 0.14),
          Offset(c.dx + m * 0.24, carY - m * 0.02),
          Offset(c.dx + m * 0.38, carY),
          Offset(c.dx + m * 0.38, carY + m * 0.08),
          Offset(c.dx - m * 0.38, carY + m * 0.08),
        ], size: 5.0));
        break;

      case 1: // High-Speed Steam Locomotive
        final tY = c.dy + m * 0.06;
        // Big Driver Wheels
        for (int w = -1; w <= 1; w++) {
          s.add(_makeCircle(Offset(c.dx + w * (m * 0.16), tY + m * 0.14), m * 0.075, size: 4.5));
        }
        // Boiler Cylinder
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.36, tY - m * 0.10, m * 0.44, m * 0.18), size: 4.5));
        // Engineer Cab
        s.add(_makeRect(Rect.fromLTWH(c.dx + m * 0.08, tY - m * 0.22, m * 0.24, m * 0.30), size: 4.5));
        // Smokestack & Cowcatcher
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.32, tY - m * 0.22, m * 0.08, m * 0.12), size: 4.0));
        s.add(_makePolygon(Offset(c.dx - m * 0.38, tY + m * 0.10), m * 0.08, 3, startAngle: pi, size: 4.0));
        break;

      case 2: // Sleek Formula Racer
        final fY = c.dy + m * 0.06;
        s.add(_makeCircle(Offset(c.dx - m * 0.24, fY + m * 0.10), m * 0.07, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.24, fY + m * 0.10), m * 0.07, size: 4.5));
        s.add(_makeStroke([
          Offset(c.dx - m * 0.40, fY + m * 0.06), // Front Wing
          Offset(c.dx - m * 0.32, fY),
          Offset(c.dx + m * 0.04, fY - m * 0.08), // Cockpit
          Offset(c.dx + m * 0.32, fY - m * 0.16), // Rear Wing Spoiler
          Offset(c.dx + m * 0.38, fY + m * 0.06),
          Offset(c.dx - m * 0.40, fY + m * 0.06),
        ], size: 5.0));
        break;

      case 3: // Twin-Propeller Biplane
        final bY = c.dy;
        // Upper & Lower Wings
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.36, bY - m * 0.18, m * 0.72, m * 0.08), size: 4.5));
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.36, bY + m * 0.04, m * 0.72, m * 0.08), size: 4.5));
        // Fuselage
        s.add(_makeEllipse(Offset(c.dx, bY), m * 0.10, m * 0.22, size: 4.5));
        // Propeller
        s.add(_makeEllipse(Offset(c.dx, bY - m * 0.22), m * 0.18, m * 0.03, size: 4.0));
        break;

      case 4: // Vintage Italian Scooter
        final sY = c.dy + m * 0.08;
        s.add(_makeCircle(Offset(c.dx - m * 0.20, sY + m * 0.10), m * 0.07, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.20, sY + m * 0.10), m * 0.07, size: 4.5));
        // Leg shield & handlebars
        s.add(_makeStroke([
          Offset(c.dx - m * 0.20, sY + m * 0.10),
          Offset(c.dx - m * 0.14, sY - m * 0.20),
          Offset(c.dx - m * 0.18, sY - m * 0.24), // Handlebar
        ], size: 5.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.14, sY - m * 0.20), m * 0.035, size: 4.0)); // Headlamp
        // Seat & Chassis
        s.add(_makeEllipse(Offset(c.dx + m * 0.08, sY - m * 0.04), m * 0.14, m * 0.08, size: 4.5));
        break;

      case 5: // Oceanic Pirate Galleon Ship
        final sY = c.dy + m * 0.14;
        // Hull
        s.add(_makeStroke([
          Offset(c.dx - m * 0.38, sY - m * 0.06),
          Offset(c.dx - m * 0.26, sY + m * 0.16),
          Offset(c.dx + m * 0.26, sY + m * 0.16),
          Offset(c.dx + m * 0.38, sY - m * 0.08),
          Offset(c.dx - m * 0.38, sY - m * 0.06),
        ], size: 5.0));
        // Masts
        for (final mx in [-m * 0.14, m * 0.08]) {
          s.add(_makeStroke([Offset(c.dx + mx, sY), Offset(c.dx + mx, sY - m * 0.42)], size: 4.5));
          // Billowing Sail
          s.add(_makeArc(Offset(c.dx + mx + m * 0.04, sY - m * 0.24), m * 0.14, -pi * 0.8, pi * 0.7, size: 4.0));
        }
        break;

      case 6: // Futuristic Cyberpunk Hoverbike
        final hY = c.dy + m * 0.04;
        // Hover Thruster Rings
        s.add(_makeEllipse(Offset(c.dx - m * 0.22, hY + m * 0.12), m * 0.12, m * 0.05, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx + m * 0.22, hY + m * 0.12), m * 0.12, m * 0.05, size: 4.5));
        // Body chassis
        s.add(_makeStroke([
          Offset(c.dx - m * 0.32, hY),
          Offset(c.dx - m * 0.10, hY - m * 0.14),
          Offset(c.dx + m * 0.22, hY - m * 0.08),
          Offset(c.dx + m * 0.34, hY + m * 0.04),
          Offset(c.dx - m * 0.32, hY),
        ], size: 5.0));
        break;

      case 7: // Deep Sea Exploration Submarine
        s.add(_makeEllipse(c, m * 0.34, m * 0.18, size: 5.5));
        // Portholes
        for (int i = -1; i <= 1; i++) {
          s.add(_makeCircle(Offset(c.dx + i * (m * 0.14), c.dy), m * 0.045, size: 4.0));
        }
        // Conning Tower & Periscope
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.08, c.dy - m * 0.28, m * 0.16, m * 0.12), size: 4.5));
        s.add(_makeStroke([Offset(c.dx, c.dy - m * 0.28), Offset(c.dx, c.dy - m * 0.38), Offset(c.dx + m * 0.06, c.dy - m * 0.38)], size: 3.5));
        break;

      case 8: // Monster Truck 4x4
        final mY = c.dy;
        // Massive Tires
        s.add(_makeCircle(Offset(c.dx - m * 0.24, mY + m * 0.16), m * 0.14, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.24, mY + m * 0.16), m * 0.07, size: 4.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.24, mY + m * 0.16), m * 0.14, size: 5.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.24, mY + m * 0.16), m * 0.07, size: 4.0));
        // Truck Cab
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.28, mY - m * 0.14, m * 0.56, m * 0.18), size: 4.5));
        break;

      default: // Colorful Hot Air Balloon
        final bY = c.dy - m * 0.08;
        s.add(_makeCircle(Offset(c.dx, bY), m * 0.26, size: 5.0));
        // Vertical Gores
        s.add(_makeArc(Offset(c.dx - m * 0.08, bY), m * 0.24, -pi * 0.8, pi * 1.6, size: 3.5));
        s.add(_makeArc(Offset(c.dx + m * 0.08, bY), m * 0.24, -pi * 0.8, pi * 1.6, size: 3.5));
        // Basket & Rigging
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.08, c.dy + m * 0.28, m * 0.16, m * 0.12), size: 4.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.12, bY + m * 0.24), Offset(c.dx - m * 0.06, c.dy + m * 0.28)], size: 3.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.12, bY + m * 0.24), Offset(c.dx + m * 0.06, c.dy + m * 0.28)], size: 3.5));
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. FOOD & SWEETS (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateFood(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // Glazed Sprinkled Doughnut
        s.add(_makeCircle(c, m * 0.32, size: 5.5));
        s.add(_makeCircle(c, m * 0.12, size: 4.5));
        // Wavy Glaze
        s.add(_makeCircle(c, m * 0.26, size: 3.5));
        // Crunchy Sprinkles
        for (int i = 0; i < 14; i++) {
          final a = (2 * pi / 14) * i;
          final r = m * (0.18 + (i % 2) * 0.04);
          final sX = c.dx + r * cos(a);
          final sY = c.dy + r * sin(a);
          s.add(_makeStroke([Offset(sX - 5, sY - 5), Offset(sX + 5, sY + 5)], size: 4.0));
        }
        break;

      case 1: // Multi-Tier Celebration Cake
        final baseCakeY = c.dy + m * 0.24;
        // Pedestal
        s.add(_makeEllipse(Offset(c.dx, baseCakeY + m * 0.12), m * 0.36, m * 0.06, size: 4.5));
        // Bottom Tier
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.30, baseCakeY - m * 0.14, m * 0.60, m * 0.18), size: 4.5));
        // Middle Tier
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.22, baseCakeY - m * 0.28, m * 0.44, m * 0.14), size: 4.5));
        // Top Tier
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.14, baseCakeY - m * 0.40, m * 0.28, m * 0.12), size: 4.5));
        // Candle & Flame
        s.add(_makeStroke([Offset(c.dx, baseCakeY - m * 0.40), Offset(c.dx, baseCakeY - m * 0.48)], size: 4.0));
        s.add(_makePetal(Offset(c.dx, baseCakeY - m * 0.50), 0, m * 0.04, -pi / 2, 0.4, size: 3.5));
        break;

      case 2: // Triple Scoop Sundae
        final cupY = c.dy + m * 0.12;
        // Sundae Glass
        s.add(_makeStroke([
          Offset(c.dx - m * 0.22, cupY),
          Offset(c.dx - m * 0.08, cupY + m * 0.22),
          Offset(c.dx - m * 0.14, cupY + m * 0.26),
          Offset(c.dx + m * 0.14, cupY + m * 0.26),
          Offset(c.dx + m * 0.08, cupY + m * 0.22),
          Offset(c.dx + m * 0.22, cupY),
          Offset(c.dx - m * 0.22, cupY),
        ], size: 4.5));
        // 3 Scoops
        s.add(_makeCircle(Offset(c.dx - m * 0.10, cupY - m * 0.06), m * 0.12, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.10, cupY - m * 0.06), m * 0.12, size: 4.5));
        s.add(_makeCircle(Offset(c.dx, cupY - m * 0.18), m * 0.12, size: 4.5));
        // Cherry
        s.add(_makeCircle(Offset(c.dx, cupY - m * 0.32), m * 0.04, size: 4.0));
        s.add(_makeArc(Offset(c.dx + m * 0.04, cupY - m * 0.36), m * 0.06, -pi * 0.6, pi * 0.6, size: 3.5));
        break;

      case 3: // Crispy Cheesy Pizza Slice
        s.add(_makeStroke([
          Offset(c.dx, c.dy + m * 0.38), // Tip
          Offset(c.dx - m * 0.26, c.dy - m * 0.24),
          Offset(c.dx + m * 0.26, c.dy - m * 0.24),
          Offset(c.dx, c.dy + m * 0.38),
        ], size: 5.0));
        // Bubbly Crust
        s.add(_makeArc(Offset(c.dx, c.dy - m * 0.24), m * 0.28, -pi * 0.85, pi * 0.7, size: 5.0));
        // Pepperonis
        s.add(_makeCircle(Offset(c.dx - m * 0.08, c.dy - m * 0.10), m * 0.055, size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.09, c.dy - m * 0.04), m * 0.05, size: 3.5));
        s.add(_makeCircle(Offset(c.dx, c.dy + m * 0.14), m * 0.045, size: 3.5));
        break;

      case 4: // French Macaron Box
        for (int i = 0; i < 3; i++) {
          final mY = c.dy - m * 0.18 + i * (m * 0.16);
          s.add(_makeEllipse(Offset(c.dx, mY), m * 0.24, m * 0.07, size: 4.5));
          s.add(_makeStroke([Offset(c.dx - m * 0.22, mY + 2), Offset(c.dx + m * 0.22, mY + 2)], size: 3.0));
        }
        break;

      case 5: // Kawaii Boba Bubble Tea
        final teaY = c.dy - m * 0.04;
        // Cup
        s.add(_makeStroke([
          Offset(c.dx - m * 0.18, teaY - m * 0.18),
          Offset(c.dx - m * 0.13, teaY + m * 0.38),
          Offset(c.dx + m * 0.13, teaY + m * 0.38),
          Offset(c.dx + m * 0.18, teaY - m * 0.18),
          Offset(c.dx - m * 0.18, teaY - m * 0.18),
        ], size: 5.0));
        // Domed Lid
        s.add(_makeArc(Offset(c.dx, teaY - m * 0.18), m * 0.19, -pi, pi, size: 4.5));
        // Straw
        s.add(_makeStroke([Offset(c.dx, teaY - m * 0.18), Offset(c.dx + m * 0.08, teaY - m * 0.38)], size: 5.5));
        // Boba Pearls at bottom
        for (int i = -2; i <= 2; i++) {
          s.add(_makeCircle(Offset(c.dx + i * (m * 0.05), teaY + m * 0.32), m * 0.025, size: 3.5));
          s.add(_makeCircle(Offset(c.dx + i * (m * 0.04), teaY + m * 0.25), m * 0.025, size: 3.5));
        }
        break;

      case 6: // Stack of Fluffy Pancakes
        final panY = c.dy + m * 0.20;
        for (int i = 0; i < 4; i++) {
          final pY = panY - i * (m * 0.09);
          s.add(_makeEllipse(Offset(c.dx, pY), m * 0.32 - i * 5, m * 0.08, size: 4.5));
        }
        // Melting Butter Cube
        s.add(_makePolygon(Offset(c.dx, panY - m * 0.34), m * 0.06, 4, startAngle: pi / 4, size: 4.0));
        break;

      case 7: // Japanese Sushi Bento Set
        final bentoY = c.dy;
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.36, bentoY - m * 0.22, m * 0.72, m * 0.44), size: 5.0));
        // Maki Sushi Rolls
        s.add(_makeCircle(Offset(c.dx - m * 0.18, bentoY), m * 0.09, size: 4.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.18, bentoY), m * 0.04, size: 3.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.18, bentoY), m * 0.09, size: 4.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.18, bentoY), m * 0.04, size: 3.0));
        break;

      case 8: // Belgian Waffle with Berries
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.28, c.dy - m * 0.28, m * 0.56, m * 0.56), size: 5.0));
        // Grid pockets
        for (int r = 1; r < 4; r++) {
          final pos = -m * 0.28 + r * (m * 0.14);
          s.add(_makeStroke([Offset(c.dx - m * 0.28, c.dy + pos), Offset(c.dx + m * 0.28, c.dy + pos)], size: 3.5));
          s.add(_makeStroke([Offset(c.dx + pos, c.dy - m * 0.28), Offset(c.dx + pos, c.dy + m * 0.28)], size: 3.5));
        }
        break;

      default: // Sweet Strawberry Cupcake
        final cupY = c.dy + m * 0.06;
        s.add(_makeStroke([
          Offset(c.dx - m * 0.18, cupY),
          Offset(c.dx - m * 0.12, cupY + m * 0.28),
          Offset(c.dx + m * 0.12, cupY + m * 0.28),
          Offset(c.dx + m * 0.18, cupY),
          Offset(c.dx - m * 0.18, cupY),
        ], size: 4.5));
        s.add(_makeArc(Offset(c.dx, cupY), m * 0.20, -pi * 0.9, pi * 0.8, size: 4.5));
        s.add(_makeArc(Offset(c.dx, cupY - m * 0.10), m * 0.15, -pi * 0.85, pi * 0.7, size: 4.0));
        s.add(_makeCircle(Offset(c.dx, cupY - m * 0.26), m * 0.05, size: 4.5));
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 10. ARCHITECTURE & LANDMARKS (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateArchitecture(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // Japanese Pagoda Sanctuary
        final bY = c.dy + m * 0.32;
        for (int tier = 0; tier < 3; tier++) {
          final tY = bY - tier * (m * 0.18);
          final w = m * (0.42 - tier * 0.08);
          // Eaves curved roof
          s.add(_makeStroke([
            Offset(c.dx - w, tY),
            Offset(c.dx, tY - m * 0.08),
            Offset(c.dx + w, tY),
          ], size: 5.0));
          // Pillars
          s.add(_makeRect(Rect.fromLTWH(c.dx - w * 0.5, tY, w, m * 0.10), size: 4.0));
        }
        s.add(_makeStroke([Offset(c.dx, bY - m * 0.54), Offset(c.dx, bY - m * 0.70)], size: 4.5)); // Finial
        break;

      case 1: // Gothic Cathedral Facade
        final cY = c.dy + m * 0.34;
        // Central block & Rose window
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.16, cY - m * 0.40, m * 0.32, m * 0.40), size: 4.5));
        s.add(_makeCircle(Offset(c.dx, cY - m * 0.25), m * 0.09, size: 4.0));
        s.add(_makeArc(Offset(c.dx, cY - m * 0.08), m * 0.07, -pi, pi, size: 4.0));
        // Twin Towers
        for (final sign in [-1.0, 1.0]) {
          final tX = c.dx + sign * m * 0.24;
          s.add(_makeRect(Rect.fromLTWH(tX - m * 0.08, cY - m * 0.50, m * 0.16, m * 0.50), size: 4.0));
          s.add(_makePolygon(Offset(tX, cY - m * 0.58), m * 0.10, 3, startAngle: -pi / 2, size: 4.0));
        }
        break;

      case 2: // Fairy Tale Castle
        final cY = c.dy + m * 0.28;
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.26, cY - m * 0.28, m * 0.52, m * 0.28), size: 4.5));
        // Drawbridge arch
        s.add(_makeArc(Offset(c.dx, cY - m * 0.08), m * 0.08, -pi, pi, size: 4.0));
        // Turrets
        for (final sign in [-1.0, 1.0]) {
          final tX = c.dx + sign * m * 0.28;
          s.add(_makeRect(Rect.fromLTWH(tX - m * 0.07, cY - m * 0.42, m * 0.14, m * 0.42), size: 4.0));
          s.add(_makePolygon(Offset(tX, cY - m * 0.50), m * 0.10, 3, startAngle: -pi / 2, size: 4.0));
        }
        break;

      case 3: // Dutch Windmill in Tulip Field
        final mY = c.dy + m * 0.10;
        // Tower Base
        s.add(_makeStroke([
          Offset(c.dx - m * 0.18, c.dy + m * 0.36),
          Offset(c.dx - m * 0.12, mY - m * 0.10),
          Offset(c.dx + m * 0.12, mY - m * 0.10),
          Offset(c.dx + m * 0.18, c.dy + m * 0.36),
          Offset(c.dx - m * 0.18, c.dy + m * 0.36),
        ], size: 5.0));
        // 4 Sails
        for (int i = 0; i < 4; i++) {
          final a = (pi / 2) * i + pi / 4;
          s.add(_makeStroke([
            Offset(c.dx, mY - m * 0.10),
            Offset(c.dx + m * 0.36 * cos(a), (mY - m * 0.10) + m * 0.36 * sin(a)),
          ], size: 4.5));
        }
        break;

      case 4: // Ancient Greek Parthenon
        final pY = c.dy + m * 0.26;
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.38, pY, m * 0.76, m * 0.08), size: 5.0)); // Base
        s.add(_makePolygon(Offset(c.dx, pY - m * 0.32), m * 0.40, 3, startAngle: -pi / 2, size: 4.5)); // Pediment
        for (int col = -3; col <= 3; col++) {
          final cX = c.dx + col * (m * 0.10);
          s.add(_makeStroke([Offset(cX, pY), Offset(cX, pY - m * 0.26)], size: 4.5));
        }
        break;

      case 5: // Modern Skyline Skyscraper
        final skyY = c.dy + m * 0.36;
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.12, skyY - m * 0.60, m * 0.24, m * 0.60), size: 4.5));
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.32, skyY - m * 0.42, m * 0.18, m * 0.42), size: 4.0));
        s.add(_makeRect(Rect.fromLTWH(c.dx + m * 0.14, skyY - m * 0.48, m * 0.18, m * 0.48), size: 4.0));
        s.add(_makeStroke([Offset(c.dx, skyY - m * 0.60), Offset(c.dx, skyY - m * 0.72)], size: 4.0)); // Antenna
        break;

      case 6: // Cozy Alpine Log Cabin
        final cabY = c.dy + m * 0.28;
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.28, cabY - m * 0.24, m * 0.56, m * 0.24), size: 4.5));
        // A-frame Roof
        s.add(_makePolygon(Offset(c.dx, cabY - m * 0.28), m * 0.35, 3, startAngle: -pi / 2, size: 5.0));
        // Chimney & Smoke
        s.add(_makeRect(Rect.fromLTWH(c.dx + m * 0.12, cabY - m * 0.48, m * 0.08, m * 0.16), size: 4.0));
        s.add(_makeArc(Offset(c.dx + m * 0.16, cabY - m * 0.56), m * 0.06, -0.4, pi, size: 3.5));
        break;

      case 7: // Parisian Eiffel Tower
        final eY = c.dy + m * 0.36;
        s.add(_makeArc(Offset(c.dx, eY), m * 0.20, -pi, pi, size: 5.0)); // Base Arch
        s.add(_makeStroke([
          Offset(c.dx - m * 0.26, eY),
          Offset(c.dx - m * 0.12, eY - m * 0.36),
          Offset(c.dx, eY - m * 0.72),
          Offset(c.dx + m * 0.12, eY - m * 0.36),
          Offset(c.dx + m * 0.26, eY),
        ], size: 5.0));
        break;

      case 8: // Taj Mahal Dome Silhouette
        final tY = c.dy + m * 0.30;
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.28, tY - m * 0.24, m * 0.56, m * 0.24), size: 4.5));
        s.add(_makeArc(Offset(c.dx, tY - m * 0.08), m * 0.09, -pi, pi, size: 4.0));
        // Onion Dome
        s.add(_makeCircle(Offset(c.dx, tY - m * 0.32), m * 0.16, size: 4.5));
        // Outer Minarets
        for (final sign in [-1.0, 1.0]) {
          final mX = c.dx + sign * m * 0.34;
          s.add(_makeStroke([Offset(mX, tY), Offset(mX, tY - m * 0.46)], size: 4.5));
        }
        break;

      default: // Venetian Canal Bridge
        final bY = c.dy + m * 0.18;
        s.add(_makeArc(Offset(c.dx, bY), m * 0.28, -pi, pi, size: 5.0)); // Arch
        s.add(_makeStroke([
          Offset(c.dx - m * 0.40, bY),
          Offset(c.dx - m * 0.28, bY - m * 0.12),
          Offset(c.dx + m * 0.28, bY - m * 0.12),
          Offset(c.dx + m * 0.40, bY),
        ], size: 5.0));
        // Water ripples below
        s.add(_makeStroke([Offset(c.dx - m * 0.24, bY + m * 0.10), Offset(c.dx + m * 0.24, bY + m * 0.10)], size: 3.5));
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 11. OCEAN & MARINE (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateOcean(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // Leaping Ocean Dolphin
        s.add(_makeArc(Offset(c.dx, c.dy), m * 0.32, -pi * 0.8, pi * 1.4, size: 5.5));
        // Snout & Dorsal Fin
        s.add(_makePolygon(Offset(c.dx + m * 0.04, c.dy - m * 0.26), m * 0.08, 3, startAngle: -pi / 2, size: 4.0));
        // Flukes tail
        s.add(_makePolygon(Offset(c.dx + m * 0.26, c.dy + m * 0.18), m * 0.09, 3, startAngle: pi / 4, size: 4.0));
        // Wave below
        s.add(_makeArc(Offset(c.dx, c.dy + m * 0.34), m * 0.38, -pi * 0.8, pi * 0.7, size: 4.5));
        break;

      case 1: // Sea Turtle in Coral Reef
        // Carapace Shell
        s.add(_makeCircle(c, m * 0.22, size: 5.0));
        s.add(_makePolygon(c, m * 0.14, 6, size: 3.5));
        // Head
        s.add(_makeCircle(Offset(c.dx, c.dy - m * 0.28), m * 0.065, size: 4.5));
        // Front Flippers
        s.add(_makePetal(Offset(c.dx - m * 0.16, c.dy - m * 0.14), 0, m * 0.26, -pi * 0.75, 0.4, size: 4.5));
        s.add(_makePetal(Offset(c.dx + m * 0.16, c.dy - m * 0.14), 0, m * 0.26, -pi * 0.25, 0.4, size: 4.5));
        // Rear Flippers
        s.add(_makePetal(Offset(c.dx - m * 0.14, c.dy + m * 0.16), 0, m * 0.16, -pi * 0.9, 0.35, size: 4.0));
        s.add(_makePetal(Offset(c.dx + m * 0.14, c.dy + m * 0.16), 0, m * 0.16, -pi * 0.1, 0.35, size: 4.0));
        break;

      case 2: // Majestic Humpback Whale
        final wY = c.dy - m * 0.04;
        s.add(_makeStroke([
          Offset(c.dx - m * 0.38, wY), // Snout
          Offset(c.dx, wY - m * 0.18), // Back
          Offset(c.dx + m * 0.32, wY + m * 0.02), // Tail stalk
          Offset(c.dx + m * 0.20, wY + m * 0.18), // Belly
          Offset(c.dx - m * 0.15, wY + m * 0.18),
          Offset(c.dx - m * 0.38, wY),
        ], size: 5.5));
        // Long Pectoral Fin
        s.add(_makePetal(Offset(c.dx - m * 0.06, wY + m * 0.14), 0, m * 0.26, pi * 0.4, 0.25, size: 4.5));
        // Tail Fluke
        s.add(_makePolygon(Offset(c.dx + m * 0.36, wY), m * 0.12, 3, startAngle: 0, size: 4.5));
        break;

      case 3: // Graceful Seahorse
        final sC = Offset(c.dx - m * 0.04, c.dy);
        // Coronet Head
        s.add(_makeCircle(Offset(sC.dx, sC.dy - m * 0.20), m * 0.08, size: 4.5));
        s.add(_makeStroke([Offset(sC.dx, sC.dy - m * 0.20), Offset(sC.dx - m * 0.14, sC.dy - m * 0.18)], size: 4.5)); // Snout
        // Segmented Curved Belly & Tail
        s.add(_makeArc(Offset(sC.dx, sC.dy - m * 0.02), m * 0.14, -0.4, pi * 0.9, size: 5.0));
        s.add(_makeStroke([
          Offset(sC.dx, sC.dy + m * 0.12),
          Offset(sC.dx - m * 0.08, sC.dy + m * 0.24),
          Offset(sC.dx, sC.dy + m * 0.30),
          Offset(sC.dx + m * 0.06, sC.dy + m * 0.24),
        ], size: 5.0)); // Spiral tail
        break;

      case 4: // Tropical Clownfish & Anemone
        // Wavy Anemone tentacles around
        for (int i = 0; i < 10; i++) {
          final a = (2 * pi / 10) * i;
          s.add(_makePetal(c, m * 0.18, m * 0.38, a, 0.25, size: 3.5));
        }
        // Clownfish Center
        s.add(_makeEllipse(c, m * 0.16, m * 0.10, size: 4.5));
        // 3 White stripes
        s.add(_makeArc(c, m * 0.10, -pi / 2, pi, size: 4.0));
        s.add(_makeArc(Offset(c.dx - m * 0.08, c.dy), m * 0.08, -pi / 2, pi, size: 4.0));
        break;

      case 5: // Giant Kraken Octopus
        s.add(_makeCircle(Offset(c.dx, c.dy - m * 0.14), m * 0.18, size: 5.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.08, c.dy - m * 0.10), m * 0.035, size: 4.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.08, c.dy - m * 0.10), m * 0.035, size: 4.0));
        // 8 Curling Tentacles
        for (int i = 0; i < 6; i++) {
          final a = pi * 0.15 + (pi * 0.7 / 5) * i;
          final pts = <Offset>[Offset(c.dx, c.dy - m * 0.04)];
          for (int step = 1; step <= 8; step++) {
            final t = step / 8.0;
            final wave = sin(t * pi * 3) * (m * 0.06);
            pts.add(Offset(c.dx + (t * m * 0.36) * cos(a) + wave, (c.dy - m * 0.04) + (t * m * 0.38) * sin(a)));
          }
          s.add(_makeStroke(pts, size: 4.5));
        }
        break;

      case 6: // Manta Ray Glider
        s.add(_makeStroke([
          Offset(c.dx, c.dy - m * 0.26), // Head
          Offset(c.dx - m * 0.40, c.dy), // Left Wingtip
          Offset(c.dx, c.dy + m * 0.22), // Tail base
          Offset(c.dx + m * 0.40, c.dy), // Right Wingtip
          Offset(c.dx, c.dy - m * 0.26),
        ], size: 5.5));
        s.add(_makeStroke([Offset(c.dx, c.dy + m * 0.22), Offset(c.dx, c.dy + m * 0.44)], size: 4.0)); // Whip tail
        break;

      case 7: // Luminescent Jellyfish
        final bY = c.dy - m * 0.12;
        s.add(_makeArc(Offset(c.dx, bY), m * 0.24, -pi * 0.95, pi * 0.9, size: 5.0));
        s.add(_makeStroke([Offset(c.dx - m * 0.24, bY), Offset(c.dx + m * 0.24, bY)], size: 4.0));
        for (int i = -3; i <= 3; i++) {
          final sX = c.dx + i * (m * 0.06);
          final pts = <Offset>[];
          for (int step = 0; step <= 8; step++) {
            final t = step / 8.0;
            final wave = sin(t * pi * 3 + i) * (m * 0.035);
            pts.add(Offset(sX + wave, bY + t * (m * 0.46)));
          }
          s.add(_makeStroke(pts, size: 3.0));
        }
        break;

      case 8: // Scallop Pearl Shell
        final shY = c.dy + m * 0.12;
        s.add(_makeArc(Offset(c.dx, shY), m * 0.32, -pi * 0.9, pi * 0.8, size: 5.0));
        // Radial shell ribs
        for (int i = 0; i < 7; i++) {
          final a = -pi * 0.85 + (pi * 0.7 / 6) * i;
          s.add(_makeStroke([Offset(c.dx, shY), Offset(c.dx + m * 0.32 * cos(a), shY + m * 0.32 * sin(a))], size: 3.5));
        }
        // Glistening Pearl inside
        s.add(_makeCircle(Offset(c.dx, shY - m * 0.10), m * 0.07, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.02, shY - m * 0.12), m * 0.02, size: 3.0));
        break;

      default: // Hammerhead Shark
        s.add(_makeStroke([
          Offset(c.dx - m * 0.24, c.dy - m * 0.22), // T-head left
          Offset(c.dx + m * 0.24, c.dy - m * 0.22), // T-head right
          Offset(c.dx + m * 0.08, c.dy - m * 0.10),
          Offset(c.dx + m * 0.08, c.dy + m * 0.28), // Body
          Offset(c.dx, c.dy + m * 0.40), // Tail
          Offset(c.dx - m * 0.08, c.dy + m * 0.28),
          Offset(c.dx - m * 0.08, c.dy - m * 0.10),
          Offset(c.dx - m * 0.24, c.dy - m * 0.22),
        ], size: 5.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.22, c.dy - m * 0.22), m * 0.02, size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.22, c.dy - m * 0.22), m * 0.02, size: 3.5));
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 12. ABSTRACT & GEOMETRIC (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateAbstract(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // Prismatic Hexagon Crystal
        for (int i = 0; i < 3; i++) {
          final rot = (pi / 3) * i;
          s.add(_makePolygon(c, m * 0.36, 6, startAngle: rot, size: 3.5));
        }
        s.add(_makePolygon(c, m * 0.22, 6, size: 4.0));
        s.add(_makePolygon(c, m * 0.10, 6, size: 4.0));
        break;

      case 1: // Bauhaus Constructivist Balance
        s.add(_makeCircle(Offset(c.dx - m * 0.10, c.dy - m * 0.10), m * 0.22, size: 5.0));
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.34, c.dy - m * 0.04, m * 0.68, m * 0.16), size: 4.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.24, c.dy - m * 0.38), Offset(c.dx - m * 0.24, c.dy + m * 0.38)], size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.16, c.dy + m * 0.16), m * 0.09, size: 4.0));
        break;

      case 2: // Memphis Geometric Pop Art
        s.add(_makePolygon(Offset(c.dx - m * 0.14, c.dy - m * 0.14), m * 0.18, 3, startAngle: -pi / 2, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.16, c.dy - m * 0.12), m * 0.14, size: 4.5));
        // Squiggle
        final sqPts = <Offset>[];
        for (int step = 0; step <= 20; step++) {
          final t = step / 20.0;
          final x = c.dx - m * 0.32 + t * (m * 0.64);
          final y = c.dy + m * 0.18 + sin(t * pi * 4) * (m * 0.08);
          sqPts.add(Offset(x, y));
        }
        s.add(_makeStroke(sqPts, size: 4.5));
        break;

      case 3: // Mid-Century Modern Organic Forms
        s.add(_makeEllipse(Offset(c.dx - m * 0.08, c.dy - m * 0.08), m * 0.22, m * 0.14, rotation: 0.5, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx + m * 0.10, c.dy + m * 0.10), m * 0.20, m * 0.12, rotation: -0.6, size: 4.5));
        s.add(_makeStar(Offset(c.dx + m * 0.22, c.dy - m * 0.22), m * 0.08, m * 0.03, 4, size: 3.5));
        break;

      case 4: // Kinetic Optical Vortex
        s.add(_makeCircle(c, m * 0.42, size: 5.0));
        for (int i = 0; i < 12; i++) {
          final a = (2 * pi / 12) * i;
          s.add(_makeStroke([
            c,
            Offset(c.dx + m * 0.42 * cos(a + 0.6), c.dy + m * 0.42 * sin(a + 0.6)),
          ], size: 3.5));
        }
        s.add(_makeCircle(c, m * 0.24, size: 3.5));
        s.add(_makeCircle(c, m * 0.12, size: 4.0));
        break;

      case 5: // Sacred Golden Ratio Chords
        s.add(_makeCircle(c, m * 0.40, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.10, c.dy), m * 0.28, size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.10, c.dy), m * 0.28, size: 3.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.40, c.dy), Offset(c.dx + m * 0.40, c.dy)], size: 3.5));
        s.add(_makeStroke([Offset(c.dx, c.dy - m * 0.40), Offset(c.dx, c.dy + m * 0.40)], size: 3.5));
        break;

      case 6: // Dynamic Triangle Tessellation
        s.add(_makePolygon(c, m * 0.38, 3, startAngle: -pi / 2, size: 5.0));
        s.add(_makePolygon(c, m * 0.24, 3, startAngle: pi / 2, size: 4.0));
        s.add(_makePolygon(c, m * 0.12, 3, startAngle: -pi / 2, size: 3.5));
        break;

      case 7: // Liquid Waveform Ripple
        for (int r = 1; r <= 5; r++) {
          final pts = <Offset>[];
          final rad = m * (r / 6.0) * 0.42;
          for (int step = 0; step <= 32; step++) {
            final a = (2 * pi / 32) * step;
            final ripple = sin(a * 4) * (m * 0.03);
            pts.add(Offset(c.dx + (rad + ripple) * cos(a), c.dy + (rad + ripple) * sin(a)));
          }
          s.add(_makeStroke(pts, size: 3.2));
        }
        break;

      case 8: // Stained Glass Polygon Mosaic
        s.add(_makePolygon(c, m * 0.40, 8, size: 5.0));
        for (int i = 0; i < 8; i++) {
          final a = (2 * pi / 8) * i;
          s.add(_makeStroke([c, Offset(c.dx + m * 0.40 * cos(a), c.dy + m * 0.40 * sin(a))], size: 3.5));
          s.add(_makePolygon(c, m * 0.20, 8, size: 3.5));
        }
        break;

      default: // Retro Synthwave Horizon Grid
        final horizY = c.dy + m * 0.06;
        s.add(_makeStroke([Offset(c.dx - m * 0.42, horizY), Offset(c.dx + m * 0.42, horizY)], size: 4.5));
        // Sun
        s.add(_makeArc(Offset(c.dx, horizY), m * 0.24, -pi, pi, size: 5.0));
        for (int line = 1; line <= 3; line++) {
          s.add(_makeStroke([Offset(c.dx - m * 0.24, horizY - line * 15), Offset(c.dx + m * 0.24, horizY - line * 15)], size: 3.0));
        }
        // Perspective Grid Lines
        for (int col = -3; col <= 3; col++) {
          s.add(_makeStroke([
            Offset(c.dx + col * (m * 0.04), horizY),
            Offset(c.dx + col * (m * 0.14), c.dy + m * 0.42),
          ], size: 3.5));
        }
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 13. KIDS & CARTOON FUN (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateKids(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // 🧸 Teddy Bear
        s.add(_makeCircle(Offset(c.dx, c.dy - m * 0.08), m * 0.18, size: 5.5));
        s.add(_makeCircle(Offset(c.dx, c.dy + m * 0.18), m * 0.22, size: 5.5));
        s.add(_makeCircle(Offset(c.dx, c.dy + m * 0.18), m * 0.13, size: 4.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.15, c.dy - m * 0.24), m * 0.07, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.15, c.dy - m * 0.24), m * 0.07, size: 5.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.15, c.dy - m * 0.24), m * 0.04, size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.15, c.dy - m * 0.24), m * 0.04, size: 3.5));
        s.add(_makeCircle(Offset(c.dx, c.dy - m * 0.05), m * 0.08, size: 4.5));
        s.add(_makePolygon(Offset(c.dx, c.dy - m * 0.07), m * 0.035, 3, startAngle: pi / 2, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.07, c.dy - m * 0.13), m * 0.025, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.07, c.dy - m * 0.13), m * 0.025, size: 5.0));
        s.add(_makeArc(Offset(c.dx, c.dy - m * 0.03), m * 0.04, 0.2, pi - 0.4, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.22, c.dy + m * 0.14), m * 0.07, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.22, c.dy + m * 0.14), m * 0.07, size: 5.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.12, c.dy + m * 0.35), m * 0.08, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.12, c.dy + m * 0.35), m * 0.08, size: 5.0));
        break;

      case 1: // 🦕 Playful Dinosaur
        s.add(_makeCircle(Offset(c.dx - m * 0.05, c.dy + m * 0.08), m * 0.22, size: 5.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.12, c.dy - m * 0.15), m * 0.14, size: 5.5));
        s.add(_makeArc(Offset(c.dx + m * 0.18, c.dy - m * 0.12), m * 0.06, -pi * 0.2, pi * 0.8, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.14, c.dy - m * 0.18), m * 0.025, size: 5.0));
        s.add(_makeArc(Offset(c.dx + m * 0.16, c.dy - m * 0.1), m * 0.035, 0.3, pi - 0.5, size: 4.5));
        for (int i = 0; i < 5; i++) {
          final theta = -pi * 0.7 + i * 0.35;
          final px = (c.dx - m * 0.05) + m * 0.22 * cos(theta);
          final py = (c.dy + m * 0.08) + m * 0.22 * sin(theta);
          s.add(_makePolygon(Offset(px, py), m * 0.045, 3, startAngle: theta, size: 4.5));
        }
        s.add(_makeStroke([
          Offset(c.dx - m * 0.24, c.dy + m * 0.12),
          Offset(c.dx - m * 0.36, c.dy + m * 0.08),
          Offset(c.dx - m * 0.32, c.dy + m * 0.2),
        ], size: 5.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.14, c.dy + m * 0.32), m * 0.06, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.04, c.dy + m * 0.32), m * 0.06, size: 5.0));
        break;

      case 2: // ☀️ Smiley Sunshine & Clouds
        s.add(_makeCircle(c, m * 0.18, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.06, c.dy - m * 0.04), m * 0.02, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.06, c.dy - m * 0.04), m * 0.02, size: 5.0));
        s.add(_makeArc(Offset(c.dx, c.dy + m * 0.02), m * 0.06, 0.2, pi - 0.4, size: 5.0));
        for (int i = 0; i < 10; i++) {
          final theta = (2 * pi / 10) * i;
          final r1 = m * 0.22;
          final r2 = m * 0.32;
          s.add(_makePolygon(
            Offset(c.dx + (r1 + r2) * 0.5 * cos(theta), c.dy + (r1 + r2) * 0.5 * sin(theta)),
            m * 0.05,
            3,
            startAngle: theta + pi / 2,
            size: 4.0,
          ));
        }
        for (final sign in [-1.0, 1.0]) {
          final cloudX = c.dx + sign * m * 0.26;
          final cloudY = c.dy + m * 0.26;
          s.add(_makeCircle(Offset(cloudX, cloudY), m * 0.08, size: 4.5));
          s.add(_makeCircle(Offset(cloudX - m * 0.06, cloudY + m * 0.02), m * 0.06, size: 4.0));
          s.add(_makeCircle(Offset(cloudX + m * 0.06, cloudY + m * 0.02), m * 0.06, size: 4.0));
        }
        break;

      case 3: // 🚀 Friendly Rocket & Stars
        final rY = c.dy;
        s.add(_makeStroke([
          Offset(c.dx - m * 0.1, rY + m * 0.18),
          Offset(c.dx - m * 0.1, rY - m * 0.08),
          Offset(c.dx, rY - m * 0.28),
          Offset(c.dx + m * 0.1, rY - m * 0.08),
          Offset(c.dx + m * 0.1, rY + m * 0.18),
          Offset(c.dx - m * 0.1, rY + m * 0.18),
        ], size: 5.5));
        s.add(_makeCircle(Offset(c.dx, rY + m * 0.02), m * 0.06, size: 4.5));
        s.add(_makePolygon(Offset(c.dx, rY + m * 0.26), m * 0.08, 3, startAngle: pi / 2, size: 4.5)); // Exhaust
        s.add(_makeStar(Offset(c.dx - m * 0.24, rY - m * 0.18), m * 0.06, m * 0.025, 5, size: 3.5));
        s.add(_makeStar(Offset(c.dx + m * 0.24, rY - m * 0.12), m * 0.06, m * 0.025, 5, size: 3.5));
        break;

      case 4: // 🐱 Sweet Kitty
        s.add(_makeCircle(Offset(c.dx, c.dy - m * 0.06), m * 0.19, size: 5.5));
        s.add(_makePolygon(Offset(c.dx - m * 0.13, c.dy - m * 0.22), m * 0.08, 3, startAngle: -pi * 0.6, size: 5.0));
        s.add(_makePolygon(Offset(c.dx + m * 0.13, c.dy - m * 0.22), m * 0.08, 3, startAngle: -pi * 0.4, size: 5.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.07, c.dy - m * 0.08), m * 0.03, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.07, c.dy - m * 0.08), m * 0.03, size: 5.0));
        s.add(_makePolygon(Offset(c.dx, c.dy - m * 0.02), m * 0.025, 3, startAngle: pi / 2, size: 4.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.08, c.dy - m * 0.02), Offset(c.dx - m * 0.24, c.dy - m * 0.04)], size: 3.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.08, c.dy - m * 0.02), Offset(c.dx + m * 0.24, c.dy - m * 0.04)], size: 3.5));
        s.add(_makeCircle(Offset(c.dx, c.dy + m * 0.2), m * 0.18, size: 5.5));
        break;

      case 5: // 🍦 Ice Cream Sundae Cone
        final coneTop = c.dy + m * 0.02;
        s.add(_makeStroke([
          Offset(c.dx - m * 0.14, coneTop),
          Offset(c.dx, c.dy + m * 0.34),
          Offset(c.dx + m * 0.14, coneTop),
          Offset(c.dx - m * 0.14, coneTop),
        ], size: 5.5));
        s.add(_makeCircle(Offset(c.dx, coneTop - m * 0.06), m * 0.15, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.08, coneTop - m * 0.18), m * 0.12, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.08, coneTop - m * 0.18), m * 0.12, size: 5.0));
        s.add(_makeCircle(Offset(c.dx, coneTop - m * 0.28), m * 0.05, size: 5.0)); // Cherry
        break;

      case 6: // 🚗 Chubby Cartoon Car
        final carY = c.dy;
        s.add(_makeArc(Offset(c.dx, carY - m * 0.04), m * 0.18, -pi * 0.9, pi * 0.8, size: 5.5));
        s.add(_makeStroke([
          Offset(c.dx - m * 0.28, carY + m * 0.12),
          Offset(c.dx - m * 0.28, carY + m * 0.04),
          Offset(c.dx + m * 0.28, carY + m * 0.04),
          Offset(c.dx + m * 0.28, carY + m * 0.12),
          Offset(c.dx - m * 0.28, carY + m * 0.12),
        ], size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.16, carY + m * 0.15), m * 0.09, size: 5.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.16, carY + m * 0.15), m * 0.09, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.02, carY - m * 0.05), m * 0.08, size: 4.5));
        break;

      case 7: // 🤖 Friendly Robot Buddy
        final robY = c.dy - m * 0.05;
        s.add(_makePolygon(Offset(c.dx, robY - m * 0.12), m * 0.16, 4, size: 5.5, startAngle: pi / 4));
        s.add(_makeStroke([Offset(c.dx, robY - m * 0.24), Offset(c.dx, robY - m * 0.32)], size: 4.5));
        s.add(_makeCircle(Offset(c.dx, robY - m * 0.33), m * 0.035, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.06, robY - m * 0.13), m * 0.03, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.06, robY - m * 0.13), m * 0.03, size: 4.5));
        s.add(_makePolygon(Offset(c.dx, robY + m * 0.16), m * 0.2, 4, size: 5.5, startAngle: pi / 4));
        s.add(_makeCircle(Offset(c.dx, robY + m * 0.16), m * 0.08, size: 4.0));
        break;

      case 8: // 🐢 Swimming Baby Turtle
        s.add(_makeCircle(c, m * 0.18, size: 5.5));
        s.add(_makeCircle(Offset(c.dx, c.dy - m * 0.24), m * 0.07, size: 5.0)); // Head
        s.add(_makePetal(Offset(c.dx - m * 0.16, c.dy - m * 0.10), 0, m * 0.20, -pi * 0.75, 0.4, size: 5.0));
        s.add(_makePetal(Offset(c.dx + m * 0.16, c.dy - m * 0.10), 0, m * 0.20, -pi * 0.25, 0.4, size: 5.0));
        s.add(_makePetal(Offset(c.dx - m * 0.14, c.dy + m * 0.14), 0, m * 0.14, -pi * 0.9, 0.35, size: 4.5));
        s.add(_makePetal(Offset(c.dx + m * 0.14, c.dy + m * 0.14), 0, m * 0.14, -pi * 0.1, 0.35, size: 4.5));
        break;

      case 9: // 🦋 Fluttering Butterfly
        s.add(_makeStroke([Offset(c.dx, c.dy - m * 0.18), Offset(c.dx, c.dy + m * 0.18)], size: 6.0));
        s.add(_makeCircle(Offset(c.dx, c.dy - m * 0.22), m * 0.04, size: 4.5));
        for (final sign in [-1.0, 1.0]) {
          s.add(_makePetal(Offset(c.dx + sign * 5, c.dy - m * 0.05), 0, m * 0.36, sign > 0 ? 0.3 : pi - 0.3, 0.5, size: 5.0));
          s.add(_makePetal(Offset(c.dx + sign * 5, c.dy + m * 0.05), 0, m * 0.24, sign > 0 ? 1.0 : pi - 1.0, 0.4, size: 4.5));
        }
        break;

      case 10: // 🐶 Cute Playful Puppy
        final pupHeadY = c.dy - m * 0.08;
        s.add(_makeCircle(Offset(c.dx, pupHeadY), m * 0.16, size: 5.5));
        s.add(_makeEllipse(Offset(c.dx - m * 0.16, pupHeadY - m * 0.02), m * 0.06, m * 0.12, rotation: -0.4, size: 5.0));
        s.add(_makeEllipse(Offset(c.dx + m * 0.16, pupHeadY - m * 0.02), m * 0.06, m * 0.12, rotation: 0.4, size: 5.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.06, pupHeadY - m * 0.02), m * 0.025, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.06, pupHeadY - m * 0.02), m * 0.025, size: 5.0));
        s.add(_makeEllipse(Offset(c.dx, pupHeadY + m * 0.06), m * 0.05, m * 0.035, size: 4.5));
        s.add(_makeCircle(Offset(c.dx, pupHeadY + m * 0.05), m * 0.018, size: 4.5));
        s.add(_makeArc(Offset(c.dx, pupHeadY + m * 0.06), m * 0.04, 0.2, pi - 0.4, size: 4.0));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.16), m * 0.17, m * 0.14, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.09, c.dy + m * 0.27), m * 0.055, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.09, c.dy + m * 0.27), m * 0.055, size: 5.0));
        s.add(_makeArc(Offset(c.dx + m * 0.22, c.dy + m * 0.10), m * 0.12, -pi * 0.6, pi * 0.5, size: 5.0));
        break;

      case 11: // 🐰 Fluffy Bunny in Garden
        final bunHeadY = c.dy - m * 0.05;
        s.add(_makeEllipse(Offset(c.dx - m * 0.07, bunHeadY - m * 0.22), m * 0.045, m * 0.15, rotation: -0.15, size: 5.5));
        s.add(_makeEllipse(Offset(c.dx + m * 0.07, bunHeadY - m * 0.22), m * 0.045, m * 0.15, rotation: 0.15, size: 5.5));
        s.add(_makeEllipse(Offset(c.dx - m * 0.07, bunHeadY - m * 0.22), m * 0.025, m * 0.10, rotation: -0.15, size: 3.5));
        s.add(_makeEllipse(Offset(c.dx + m * 0.07, bunHeadY - m * 0.22), m * 0.025, m * 0.10, rotation: 0.15, size: 3.5));
        s.add(_makeCircle(Offset(c.dx, bunHeadY), m * 0.15, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.05, bunHeadY - m * 0.01), m * 0.022, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.05, bunHeadY - m * 0.01), m * 0.022, size: 5.0));
        s.add(_makePolygon(Offset(c.dx, bunHeadY + m * 0.04), m * 0.025, 3, size: 4.5, startAngle: pi));
        s.add(_makeStroke([Offset(c.dx - m * 0.08, bunHeadY + m * 0.04), Offset(c.dx - m * 0.20, bunHeadY + m * 0.02)], size: 3.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.08, bunHeadY + m * 0.06), Offset(c.dx - m * 0.20, bunHeadY + m * 0.08)], size: 3.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.08, bunHeadY + m * 0.04), Offset(c.dx + m * 0.20, bunHeadY + m * 0.02)], size: 3.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.08, bunHeadY + m * 0.06), Offset(c.dx + m * 0.20, bunHeadY + m * 0.08)], size: 3.5));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.18), m * 0.16, m * 0.13, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.07, c.dy + m * 0.15), m * 0.04, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.07, c.dy + m * 0.15), m * 0.04, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.09, c.dy + m * 0.27), m * 0.05, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.09, c.dy + m * 0.27), m * 0.05, size: 5.0));
        break;

      case 12: // 🐘 Gentle Baby Elephant
        final elHeadY = c.dy - m * 0.08;
        s.add(_makeCircle(Offset(c.dx, elHeadY), m * 0.16, size: 5.5));
        s.add(_makeEllipse(Offset(c.dx - m * 0.22, elHeadY), m * 0.10, m * 0.14, rotation: -0.2, size: 5.0));
        s.add(_makeEllipse(Offset(c.dx + m * 0.22, elHeadY), m * 0.10, m * 0.14, rotation: 0.2, size: 5.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.07, elHeadY - m * 0.02), m * 0.025, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.07, elHeadY - m * 0.02), m * 0.025, size: 5.0));
        final trunkPts = <Offset>[
          Offset(c.dx, elHeadY + m * 0.05),
          Offset(c.dx, elHeadY + m * 0.15),
          Offset(c.dx - m * 0.04, elHeadY + m * 0.22),
          Offset(c.dx - m * 0.10, elHeadY + m * 0.20),
          Offset(c.dx - m * 0.12, elHeadY + m * 0.14),
        ];
        s.add(_makeStroke(trunkPts, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.14, elHeadY + m * 0.06), m * 0.025, size: 4.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.18, elHeadY - m * 0.02), m * 0.035, size: 4.0));
        s.add(_makeEllipse(Offset(c.dx + m * 0.02, c.dy + m * 0.18), m * 0.17, m * 0.12, size: 5.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.10, c.dy + m * 0.20), Offset(c.dx - m * 0.10, c.dy + m * 0.32)], size: 6.0));
        s.add(_makeStroke([Offset(c.dx + m * 0.10, c.dy + m * 0.20), Offset(c.dx + m * 0.10, c.dy + m * 0.32)], size: 6.0));
        break;

      case 13: // 🐱 Little Curious Kitten
        final kitY = c.dy - m * 0.06;
        s.add(_makeCircle(Offset(c.dx, kitY), m * 0.15, size: 5.5));
        s.add(_makePolygon(Offset(c.dx - m * 0.10, kitY - m * 0.14), m * 0.065, 3, size: 5.0, startAngle: -pi / 3));
        s.add(_makePolygon(Offset(c.dx + m * 0.10, kitY - m * 0.14), m * 0.065, 3, size: 5.0, startAngle: -2 * pi / 3));
        s.add(_makeCircle(Offset(c.dx - m * 0.06, kitY - m * 0.01), m * 0.028, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.06, kitY - m * 0.01), m * 0.028, size: 5.0));
        s.add(_makePolygon(Offset(c.dx, kitY + m * 0.04), m * 0.018, 3, size: 4.5, startAngle: pi));
        s.add(_makeArc(Offset(c.dx - m * 0.02, kitY + m * 0.06), m * 0.02, 0, pi, size: 3.5));
        s.add(_makeArc(Offset(c.dx + m * 0.02, kitY + m * 0.06), m * 0.02, 0, pi, size: 3.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.07, kitY + m * 0.04), Offset(c.dx - m * 0.20, kitY + m * 0.03)], size: 3.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.07, kitY + m * 0.06), Offset(c.dx - m * 0.19, kitY + m * 0.08)], size: 3.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.07, kitY + m * 0.04), Offset(c.dx + m * 0.20, kitY + m * 0.03)], size: 3.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.07, kitY + m * 0.06), Offset(c.dx + m * 0.19, kitY + m * 0.08)], size: 3.5));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.16), m * 0.14, m * 0.12, size: 5.5));
        s.add(_makeArc(Offset(c.dx + m * 0.16, c.dy + m * 0.16), m * 0.14, -pi * 0.3, pi * 0.8, size: 5.0));
        s.add(_makeArc(Offset(c.dx, kitY + m * 0.13), m * 0.08, 0.2, pi - 0.4, size: 4.5));
        s.add(_makeCircle(Offset(c.dx, kitY + m * 0.16), m * 0.025, size: 4.5));
        break;

      case 14: // 🦒 Smiling Baby Giraffe
        final girHead = Offset(c.dx, c.dy - m * 0.16);
        s.add(_makeEllipse(girHead, m * 0.10, m * 0.08, size: 5.5));
        s.add(_makeStroke([Offset(girHead.dx - m * 0.04, girHead.dy - m * 0.06), Offset(girHead.dx - m * 0.05, girHead.dy - m * 0.13)], size: 4.5));
        s.add(_makeCircle(Offset(girHead.dx - m * 0.05, girHead.dy - m * 0.14), m * 0.02, size: 4.5));
        s.add(_makeStroke([Offset(girHead.dx + m * 0.04, girHead.dy - m * 0.06), Offset(girHead.dx + m * 0.05, girHead.dy - m * 0.13)], size: 4.5));
        s.add(_makeCircle(Offset(girHead.dx + m * 0.05, girHead.dy - m * 0.14), m * 0.02, size: 4.5));
        s.add(_makeCircle(Offset(girHead.dx - m * 0.04, girHead.dy - m * 0.01), m * 0.02, size: 5.0));
        s.add(_makeCircle(Offset(girHead.dx + m * 0.04, girHead.dy - m * 0.01), m * 0.02, size: 5.0));
        s.add(_makeEllipse(Offset(girHead.dx, girHead.dy + m * 0.04), m * 0.05, m * 0.03, size: 4.5));
        s.add(_makeStroke([Offset(girHead.dx - m * 0.06, girHead.dy + m * 0.07), Offset(c.dx - m * 0.10, c.dy + m * 0.14)], size: 5.0));
        s.add(_makeStroke([Offset(girHead.dx + m * 0.06, girHead.dy + m * 0.07), Offset(c.dx + m * 0.08, c.dy + m * 0.14)], size: 5.0));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.20), m * 0.18, m * 0.10, size: 5.5));
        s.add(_makePolygon(Offset(c.dx - m * 0.02, c.dy - m * 0.04), m * 0.035, 5, size: 3.5));
        s.add(_makePolygon(Offset(c.dx + m * 0.01, c.dy + m * 0.05), m * 0.04, 5, size: 3.5));
        s.add(_makePolygon(Offset(c.dx - m * 0.08, c.dy + m * 0.20), m * 0.04, 5, size: 3.5));
        s.add(_makePolygon(Offset(c.dx + m * 0.06, c.dy + m * 0.19), m * 0.038, 5, size: 3.5));
        break;

      case 15: // 🐨 Sweet Koala on Branch
        s.add(_makeStroke([Offset(c.dx - m * 0.35, c.dy + m * 0.25), Offset(c.dx + m * 0.35, c.dy - m * 0.15)], size: 9.0));
        s.add(_makePetal(Offset(c.dx + m * 0.25, c.dy - m * 0.18), 0, m * 0.14, -pi * 0.4, 0.4, size: 4.5));
        s.add(_makePetal(Offset(c.dx + m * 0.18, c.dy - m * 0.22), 0, m * 0.12, -pi * 0.2, 0.4, size: 4.5));
        final koaHead = Offset(c.dx - m * 0.05, c.dy - m * 0.08);
        s.add(_makeCircle(koaHead, m * 0.14, size: 5.5));
        s.add(_makeCircle(Offset(koaHead.dx - m * 0.14, koaHead.dy - m * 0.08), m * 0.08, size: 5.0));
        s.add(_makeCircle(Offset(koaHead.dx + m * 0.14, koaHead.dy - m * 0.08), m * 0.08, size: 5.0));
        s.add(_makeEllipse(Offset(koaHead.dx, koaHead.dy + m * 0.02), m * 0.04, m * 0.06, size: 5.5));
        s.add(_makeCircle(Offset(koaHead.dx - m * 0.06, koaHead.dy - m * 0.03), m * 0.02, size: 4.5));
        s.add(_makeCircle(Offset(koaHead.dx + m * 0.06, koaHead.dy - m * 0.03), m * 0.02, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.12), m * 0.13, m * 0.11, size: 5.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.08, c.dy + m * 0.08), m * 0.045, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.08, c.dy + m * 0.02), m * 0.045, size: 4.5));
        break;

      case 16: // 🐵 Cheeky Little Monkey
        final mnkHead = Offset(c.dx, c.dy - m * 0.08);
        s.add(_makeCircle(mnkHead, m * 0.14, size: 5.5));
        s.add(_makeCircle(Offset(mnkHead.dx - m * 0.14, mnkHead.dy), m * 0.06, size: 5.0));
        s.add(_makeCircle(Offset(mnkHead.dx + m * 0.14, mnkHead.dy), m * 0.06, size: 5.0));
        s.add(_makeCircle(Offset(mnkHead.dx - m * 0.04, mnkHead.dy - m * 0.02), m * 0.06, size: 4.0));
        s.add(_makeCircle(Offset(mnkHead.dx + m * 0.04, mnkHead.dy - m * 0.02), m * 0.06, size: 4.0));
        s.add(_makeCircle(Offset(mnkHead.dx - m * 0.04, mnkHead.dy - m * 0.02), m * 0.02, size: 4.5));
        s.add(_makeCircle(Offset(mnkHead.dx + m * 0.04, mnkHead.dy - m * 0.02), m * 0.02, size: 4.5));
        s.add(_makeArc(Offset(mnkHead.dx, mnkHead.dy + m * 0.05), m * 0.035, 0.2, pi - 0.4, size: 4.0));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.14), m * 0.13, m * 0.11, size: 5.5));
        s.add(_makeArc(Offset(c.dx - m * 0.16, c.dy + m * 0.16), m * 0.12, -pi * 0.2, pi * 1.3, size: 5.0));
        s.add(_makeArc(Offset(c.dx + m * 0.06, c.dy + m * 0.14), m * 0.09, -pi * 0.6, pi * 0.5, size: 5.5));
        break;

      case 17: // 🦁 Brave Lion Cub
        final lionHead = Offset(c.dx, c.dy - m * 0.05);
        for (int i = 0; i < 12; i++) {
          final angle = (2 * pi / 12) * i;
          s.add(_makePetal(lionHead, m * 0.14, m * 0.24, angle, 0.28, size: 4.5));
        }
        s.add(_makeCircle(lionHead, m * 0.15, size: 5.5));
        s.add(_makeCircle(Offset(lionHead.dx - m * 0.11, lionHead.dy - m * 0.11), m * 0.05, size: 5.0));
        s.add(_makeCircle(Offset(lionHead.dx + m * 0.11, lionHead.dy - m * 0.11), m * 0.05, size: 5.0));
        s.add(_makeCircle(Offset(lionHead.dx - m * 0.05, lionHead.dy - m * 0.01), m * 0.022, size: 5.0));
        s.add(_makeCircle(Offset(lionHead.dx + m * 0.05, lionHead.dy - m * 0.01), m * 0.022, size: 5.0));
        s.add(_makePolygon(Offset(lionHead.dx, lionHead.dy + m * 0.04), m * 0.025, 3, size: 4.5, startAngle: pi));
        s.add(_makeStroke([Offset(lionHead.dx - m * 0.06, lionHead.dy + m * 0.04), Offset(lionHead.dx - m * 0.14, lionHead.dy + m * 0.03)], size: 3.5));
        s.add(_makeStroke([Offset(lionHead.dx + m * 0.06, lionHead.dy + m * 0.04), Offset(lionHead.dx + m * 0.14, lionHead.dy + m * 0.03)], size: 3.5));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.18), m * 0.14, m * 0.11, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.07, c.dy + m * 0.25), m * 0.045, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.07, c.dy + m * 0.25), m * 0.045, size: 5.0));
        break;

      case 18: // 🦔 Happy Spiky Hedgehog
        final hedgY = c.dy;
        for (int i = 0; i < 9; i++) {
          final angle = -pi * 0.9 + (pi * 0.8 / 8) * i;
          final tip = Offset(c.dx + m * 0.25 * cos(angle), hedgY + m * 0.22 * sin(angle));
          s.add(_makePolygon(tip, m * 0.055, 3, size: 4.5, startAngle: angle + pi / 2));
        }
        s.add(_makeEllipse(Offset(c.dx, hedgY + m * 0.05), m * 0.20, m * 0.15, size: 5.5));
        s.add(_makePolygon(Offset(c.dx + m * 0.22, hedgY + m * 0.06), m * 0.06, 3, size: 5.0, startAngle: 0));
        s.add(_makeCircle(Offset(c.dx + m * 0.26, hedgY + m * 0.06), m * 0.02, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.12, hedgY + m * 0.02), m * 0.022, size: 5.0));
        s.add(_makeArc(Offset(c.dx + m * 0.16, hedgY + m * 0.09), m * 0.02, 0, pi, size: 3.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.10, hedgY + m * 0.20), m * 0.035, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.08, hedgY + m * 0.20), m * 0.035, size: 4.5));
        break;

      case 19: // 🦘 Hopping Joey Kangaroo
        final kangHead = Offset(c.dx - m * 0.08, c.dy - m * 0.16);
        s.add(_makeEllipse(kangHead, m * 0.09, m * 0.07, rotation: -0.3, size: 5.5));
        s.add(_makeEllipse(Offset(kangHead.dx - m * 0.04, kangHead.dy - m * 0.09), m * 0.03, m * 0.08, rotation: -0.2, size: 4.5));
        s.add(_makeEllipse(Offset(kangHead.dx + m * 0.02, kangHead.dy - m * 0.09), m * 0.03, m * 0.08, rotation: 0.1, size: 4.5));
        s.add(_makeCircle(Offset(kangHead.dx - m * 0.03, kangHead.dy - m * 0.01), m * 0.018, size: 4.5));
        s.add(_makeStroke([
          Offset(kangHead.dx, kangHead.dy + m * 0.06),
          Offset(c.dx - m * 0.02, c.dy),
          Offset(c.dx - m * 0.04, c.dy + m * 0.18),
        ], size: 5.5));
        s.add(_makeArc(Offset(c.dx + m * 0.04, c.dy + m * 0.08), m * 0.08, -pi * 0.2, pi * 0.7, size: 4.5));
        final joeyHead = Offset(c.dx + m * 0.04, c.dy + m * 0.02);
        s.add(_makeCircle(joeyHead, m * 0.06, size: 4.5));
        s.add(_makeEllipse(Offset(joeyHead.dx - m * 0.02, joeyHead.dy - m * 0.05), m * 0.015, m * 0.04, rotation: -0.2, size: 3.5));
        s.add(_makeEllipse(Offset(joeyHead.dx + m * 0.02, joeyHead.dy - m * 0.05), m * 0.015, m * 0.04, rotation: 0.2, size: 3.5));
        s.add(_makeCircle(Offset(joeyHead.dx, joeyHead.dy), m * 0.012, size: 4.0));
        s.add(_makeArc(Offset(c.dx - m * 0.20, c.dy + m * 0.20), m * 0.16, pi * 0.5, pi * 0.6, size: 6.5));
        s.add(_makeEllipse(Offset(c.dx + m * 0.04, c.dy + m * 0.25), m * 0.12, m * 0.04, size: 5.5));
        break;

      case 20: // 🐑 Gentle Woolly Lamb
        final lambY = c.dy;
        for (int i = 0; i < 8; i++) {
          final a = (2 * pi / 8) * i;
          s.add(_makeCircle(Offset(c.dx + m * 0.14 * cos(a), lambY + m * 0.10 * sin(a)), m * 0.09, size: 4.5));
        }
        s.add(_makeEllipse(Offset(c.dx - m * 0.10, lambY - m * 0.08), m * 0.09, m * 0.08, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.10, lambY - m * 0.16), m * 0.045, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.06, lambY - m * 0.15), m * 0.04, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx - m * 0.19, lambY - m * 0.07), m * 0.05, m * 0.025, rotation: -0.3, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx - m * 0.01, lambY - m * 0.07), m * 0.05, m * 0.025, rotation: 0.3, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.12, lambY - m * 0.08), m * 0.018, size: 4.5));
        s.add(_makeArc(Offset(c.dx - m * 0.14, lambY - m * 0.03), m * 0.02, 0, pi, size: 3.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.08, lambY + m * 0.12), Offset(c.dx - m * 0.08, lambY + m * 0.26)], size: 5.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.08, lambY + m * 0.12), Offset(c.dx + m * 0.08, lambY + m * 0.26)], size: 5.5));
        break;

      case 21: // 🦦 Playful River Otter
        final otterY = c.dy;
        s.add(_makeArc(Offset(c.dx, otterY + m * 0.20), m * 0.30, 0.2, pi - 0.4, size: 4.5));
        s.add(_makeArc(Offset(c.dx, otterY + m * 0.26), m * 0.25, 0.3, pi - 0.6, size: 4.0));
        s.add(_makeEllipse(Offset(c.dx, otterY + m * 0.04), m * 0.20, m * 0.12, rotation: -0.15, size: 5.5));
        final ottHead = Offset(c.dx - m * 0.16, otterY - m * 0.06);
        s.add(_makeCircle(ottHead, m * 0.09, size: 5.5));
        s.add(_makeCircle(Offset(ottHead.dx - m * 0.07, ottHead.dy - m * 0.06), m * 0.025, size: 4.5));
        s.add(_makeCircle(Offset(ottHead.dx + m * 0.04, ottHead.dy - m * 0.07), m * 0.025, size: 4.5));
        s.add(_makeCircle(Offset(ottHead.dx - m * 0.03, ottHead.dy - m * 0.01), m * 0.018, size: 4.5));
        s.add(_makeCircle(Offset(ottHead.dx + m * 0.03, ottHead.dy - m * 0.01), m * 0.018, size: 4.5));
        s.add(_makePolygon(Offset(ottHead.dx, ottHead.dy + m * 0.03), m * 0.018, 3, size: 4.0, startAngle: pi));
        s.add(_makeCircle(Offset(c.dx + m * 0.02, otterY + m * 0.02), m * 0.045, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.03, otterY + m * 0.03), m * 0.03, size: 4.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.07, otterY + m * 0.03), m * 0.03, size: 4.0));
        break;

      case 22: // 🦛 Splashy Baby Hippo
        final hipY = c.dy;
        s.add(_makeCircle(Offset(c.dx, hipY - m * 0.10), m * 0.15, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.12, hipY - m * 0.20), m * 0.035, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.12, hipY - m * 0.20), m * 0.035, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx, hipY + m * 0.02), m * 0.16, m * 0.10, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.05, hipY + m * 0.01), m * 0.022, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.05, hipY + m * 0.01), m * 0.022, size: 4.5));
        s.add(_makeArc(Offset(c.dx, hipY + m * 0.03), m * 0.09, 0.2, pi - 0.4, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.06, hipY - m * 0.11), m * 0.02, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.06, hipY - m * 0.11), m * 0.02, size: 5.0));
        s.add(_makeArc(Offset(c.dx, hipY + m * 0.16), m * 0.24, 0.2, pi - 0.4, size: 5.0));
        s.add(_makeArc(Offset(c.dx, hipY + m * 0.23), m * 0.20, 0.3, pi - 0.6, size: 4.0));
        break;

      case 23: // 🦓 Striped Little Zebra
        final zebHead = Offset(c.dx - m * 0.06, c.dy - m * 0.10);
        s.add(_makeEllipse(zebHead, m * 0.12, m * 0.09, rotation: -0.3, size: 5.5));
        s.add(_makePolygon(Offset(zebHead.dx - m * 0.04, zebHead.dy - m * 0.12), m * 0.05, 3, size: 4.5, startAngle: -pi / 2));
        s.add(_makePolygon(Offset(zebHead.dx + m * 0.04, zebHead.dy - m * 0.12), m * 0.05, 3, size: 4.5, startAngle: -pi / 2));
        for (int i = 0; i < 5; i++) {
          s.add(_makeStroke([Offset(zebHead.dx + m * 0.03 + i * 8, zebHead.dy - m * 0.08 + i * 10), Offset(zebHead.dx + m * 0.07 + i * 8, zebHead.dy - m * 0.14 + i * 10)], size: 4.0));
        }
        s.add(_makeStroke([Offset(zebHead.dx - m * 0.06, zebHead.dy - m * 0.03), Offset(zebHead.dx - m * 0.01, zebHead.dy - m * 0.01)], size: 4.5));
        s.add(_makeStroke([Offset(zebHead.dx - m * 0.08, zebHead.dy + m * 0.02), Offset(zebHead.dx - m * 0.02, zebHead.dy + m * 0.04)], size: 4.5));
        s.add(_makeCircle(Offset(zebHead.dx - m * 0.01, zebHead.dy - m * 0.02), m * 0.018, size: 4.5));
        s.add(_makeEllipse(Offset(zebHead.dx - m * 0.09, zebHead.dy + m * 0.05), m * 0.04, m * 0.03, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx + m * 0.04, c.dy + m * 0.12), m * 0.16, m * 0.11, size: 5.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.04, c.dy + m * 0.05), Offset(c.dx - m * 0.04, c.dy + m * 0.18)], size: 4.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.03, c.dy + m * 0.05), Offset(c.dx + m * 0.03, c.dy + m * 0.18)], size: 4.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.10, c.dy + m * 0.05), Offset(c.dx + m * 0.10, c.dy + m * 0.17)], size: 4.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.06, c.dy + m * 0.18), Offset(c.dx - m * 0.06, c.dy + m * 0.28)], size: 5.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.10, c.dy + m * 0.18), Offset(c.dx + m * 0.10, c.dy + m * 0.28)], size: 5.5));
        break;

      case 24: // 🦌 Forest Baby Fawn
        final fawnHead = Offset(c.dx, c.dy - m * 0.10);
        s.add(_makeEllipse(fawnHead, m * 0.11, m * 0.09, size: 5.5));
        s.add(_makeEllipse(Offset(fawnHead.dx - m * 0.13, fawnHead.dy - m * 0.06), m * 0.08, m * 0.04, rotation: -0.5, size: 4.5));
        s.add(_makeEllipse(Offset(fawnHead.dx + m * 0.13, fawnHead.dy - m * 0.06), m * 0.08, m * 0.04, rotation: 0.5, size: 4.5));
        s.add(_makeCircle(Offset(fawnHead.dx - m * 0.045, fawnHead.dy - m * 0.01), m * 0.025, size: 5.0));
        s.add(_makeCircle(Offset(fawnHead.dx + m * 0.045, fawnHead.dy - m * 0.01), m * 0.025, size: 5.0));
        s.add(_makeCircle(Offset(fawnHead.dx, fawnHead.dy + m * 0.05), m * 0.018, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.14), m * 0.18, m * 0.10, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.08, c.dy + m * 0.10), m * 0.018, size: 3.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.02, c.dy + m * 0.08), m * 0.018, size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.05, c.dy + m * 0.10), m * 0.018, size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.11, c.dy + m * 0.11), m * 0.018, size: 3.5));
        s.add(_makeArc(Offset(c.dx - m * 0.06, c.dy + m * 0.22), m * 0.06, 0.2, pi - 0.4, size: 4.5));
        break;

      case 25: // 🐹 Nibbling Tiny Hamster
        final hamY = c.dy;
        s.add(_makeCircle(Offset(c.dx, hamY), m * 0.20, size: 5.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.12, hamY - m * 0.16), m * 0.045, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.12, hamY - m * 0.16), m * 0.045, size: 5.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.10, hamY + m * 0.02), m * 0.06, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.10, hamY + m * 0.02), m * 0.06, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.05, hamY - m * 0.04), m * 0.02, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.05, hamY - m * 0.04), m * 0.02, size: 5.0));
        s.add(_makePolygon(Offset(c.dx, hamY + m * 0.01), m * 0.015, 3, size: 4.0, startAngle: pi));
        s.add(_makeEllipse(Offset(c.dx, hamY + m * 0.10), m * 0.04, m * 0.065, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.04, hamY + m * 0.09), m * 0.025, size: 4.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.04, hamY + m * 0.09), m * 0.025, size: 4.0));
        s.add(_makeEllipse(Offset(c.dx - m * 0.09, hamY + m * 0.20), m * 0.04, m * 0.025, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx + m * 0.09, hamY + m * 0.20), m * 0.04, m * 0.025, size: 4.5));
        break;

      case 26: // 🐷 Muddy Happy Piglet
        final pigY = c.dy - m * 0.05;
        s.add(_makeCircle(Offset(c.dx, pigY), m * 0.16, size: 5.5));
        s.add(_makePolygon(Offset(c.dx - m * 0.12, pigY - m * 0.12), m * 0.06, 3, size: 4.5, startAngle: -pi * 0.7));
        s.add(_makePolygon(Offset(c.dx + m * 0.12, pigY - m * 0.12), m * 0.06, 3, size: 4.5, startAngle: -pi * 0.3));
        s.add(_makeEllipse(Offset(c.dx, pigY + m * 0.04), m * 0.07, m * 0.05, size: 5.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.025, pigY + m * 0.04), m * 0.015, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.025, pigY + m * 0.04), m * 0.015, size: 4.5));
        s.add(_makeArc(Offset(c.dx - m * 0.06, pigY - m * 0.03), m * 0.03, -pi * 0.8, pi * 0.6, size: 4.5));
        s.add(_makeArc(Offset(c.dx + m * 0.06, pigY - m * 0.03), m * 0.03, -pi * 0.8, pi * 0.6, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.16), m * 0.16, m * 0.12, size: 5.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.18, c.dy + m * 0.14), m * 0.035, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.07, c.dy + m * 0.26), m * 0.04, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.07, c.dy + m * 0.26), m * 0.04, size: 5.0));
        break;

      case 27: // 🦥 Cozy Sloth on Branch
      default:
        s.add(_makeStroke([Offset(c.dx - m * 0.35, c.dy - m * 0.12), Offset(c.dx + m * 0.35, c.dy - m * 0.10)], size: 9.0));
        s.add(_makeStroke([Offset(c.dx - m * 0.15, c.dy - m * 0.10), Offset(c.dx - m * 0.12, c.dy + m * 0.02)], size: 6.0));
        s.add(_makeStroke([Offset(c.dx + m * 0.15, c.dy - m * 0.10), Offset(c.dx + m * 0.12, c.dy + m * 0.02)], size: 6.0));
        s.add(_makeArc(Offset(c.dx - m * 0.15, c.dy - m * 0.12), m * 0.025, pi, pi, size: 4.5));
        s.add(_makeArc(Offset(c.dx + m * 0.15, c.dy - m * 0.12), m * 0.025, pi, pi, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.06), m * 0.18, m * 0.12, size: 5.5));
        final slothHead = Offset(c.dx - m * 0.10, c.dy + m * 0.04);
        s.add(_makeCircle(slothHead, m * 0.10, size: 5.0));
        s.add(_makeEllipse(Offset(slothHead.dx - m * 0.03, slothHead.dy), m * 0.035, m * 0.02, rotation: 0.2, size: 4.0));
        s.add(_makeEllipse(Offset(slothHead.dx + m * 0.03, slothHead.dy), m * 0.035, m * 0.02, rotation: -0.2, size: 4.0));
        s.add(_makeArc(Offset(slothHead.dx - m * 0.03, slothHead.dy), m * 0.015, 0, pi, size: 3.5));
        s.add(_makeArc(Offset(slothHead.dx + m * 0.03, slothHead.dy), m * 0.015, 0, pi, size: 3.5));
        s.add(_makeArc(Offset(slothHead.dx, slothHead.dy + m * 0.04), m * 0.025, 0.2, pi - 0.4, size: 3.5));
        break;
    }
  }

  /// Birds & Aviary - 18 distinct handcrafted vector motifs
  static void _generateBirds(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif % 18) {
      case 0: // 🦜 Tropical Macaw Parrot
        s.add(_makeStroke([Offset(c.dx - m * 0.35, c.dy + m * 0.22), Offset(c.dx + m * 0.35, c.dy + m * 0.16)], size: 8.0));
        final parHead = Offset(c.dx - m * 0.06, c.dy - m * 0.16);
        s.add(_makeCircle(parHead, m * 0.12, size: 5.5));
        s.add(_makeArc(Offset(parHead.dx - m * 0.08, parHead.dy + m * 0.02), m * 0.08, -pi * 0.4, pi * 0.7, size: 6.0));
        s.add(_makeCircle(Offset(parHead.dx - m * 0.02, parHead.dy - m * 0.02), m * 0.02, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx + m * 0.02, c.dy + m * 0.04), m * 0.14, m * 0.18, rotation: 0.25, size: 5.5));
        s.add(_makePetal(Offset(c.dx + m * 0.02, c.dy + m * 0.02), 0, m * 0.22, pi * 0.4, 0.35, size: 5.0));
        s.add(_makePetal(Offset(c.dx + m * 0.08, c.dy + m * 0.16), 0, m * 0.32, pi * 0.42, 0.25, size: 5.5));
        s.add(_makePetal(Offset(c.dx + m * 0.12, c.dy + m * 0.16), 0, m * 0.38, pi * 0.46, 0.22, size: 5.0));
        break;

      case 1: // 🦩 Elegant Pink Flamingo
        final flamHead = Offset(c.dx + m * 0.10, c.dy - m * 0.20);
        s.add(_makeCircle(flamHead, m * 0.08, size: 5.5));
        s.add(_makeStroke([
          Offset(flamHead.dx - m * 0.06, flamHead.dy + m * 0.02),
          Offset(flamHead.dx - m * 0.14, flamHead.dy + m * 0.05),
          Offset(flamHead.dx - m * 0.15, flamHead.dy + m * 0.11),
        ], size: 5.5));
        s.add(_makeCircle(Offset(flamHead.dx, flamHead.dy - m * 0.01), m * 0.018, size: 4.5));
        final sNeck = <Offset>[
          Offset(flamHead.dx + m * 0.02, flamHead.dy + m * 0.07),
          Offset(c.dx + m * 0.18, c.dy - m * 0.08),
          Offset(c.dx + m * 0.04, c.dy - m * 0.02),
          Offset(c.dx - m * 0.06, c.dy + m * 0.04),
        ];
        s.add(_makeStroke(sNeck, size: 6.0));
        s.add(_makeEllipse(Offset(c.dx - m * 0.08, c.dy + m * 0.08), m * 0.17, m * 0.12, rotation: -0.15, size: 5.5));
        s.add(_makePetal(Offset(c.dx - m * 0.08, c.dy + m * 0.06), 0, m * 0.15, -pi * 0.85, 0.4, size: 4.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.08, c.dy + m * 0.19), Offset(c.dx - m * 0.08, c.dy + m * 0.38)], size: 5.0));
        s.add(_makeStroke([
          Offset(c.dx - m * 0.04, c.dy + m * 0.19),
          Offset(c.dx + m * 0.06, c.dy + m * 0.28),
          Offset(c.dx - m * 0.06, c.dy + m * 0.28),
        ], size: 5.0));
        s.add(_makeArc(Offset(c.dx, c.dy + m * 0.38), m * 0.22, 0.2, pi - 0.4, size: 4.0));
        break;

      case 2: // 🦉 Wise Little Barn Owl
        s.add(_makeStroke([Offset(c.dx - m * 0.35, c.dy + m * 0.22), Offset(c.dx + m * 0.35, c.dy + m * 0.22)], size: 7.0));
        s.add(_makeArc(Offset(c.dx + m * 0.28, c.dy - m * 0.28), m * 0.10, -pi * 0.6, pi * 1.2, size: 4.5));
        final owlCenter = Offset(c.dx, c.dy - m * 0.04);
        s.add(_makeCircle(Offset(owlCenter.dx, owlCenter.dy - m * 0.08), m * 0.16, size: 5.5));
        s.add(_makeEllipse(Offset(owlCenter.dx - m * 0.06, owlCenter.dy - m * 0.08), m * 0.065, m * 0.08, rotation: 0.1, size: 4.0));
        s.add(_makeEllipse(Offset(owlCenter.dx + m * 0.06, owlCenter.dy - m * 0.08), m * 0.065, m * 0.08, rotation: -0.1, size: 4.0));
        s.add(_makeCircle(Offset(owlCenter.dx - m * 0.06, owlCenter.dy - m * 0.08), m * 0.035, size: 4.5));
        s.add(_makeCircle(Offset(owlCenter.dx + m * 0.06, owlCenter.dy - m * 0.08), m * 0.035, size: 4.5));
        s.add(_makeCircle(Offset(owlCenter.dx - m * 0.06, owlCenter.dy - m * 0.08), m * 0.015, size: 4.5));
        s.add(_makeCircle(Offset(owlCenter.dx + m * 0.06, owlCenter.dy - m * 0.08), m * 0.015, size: 4.5));
        s.add(_makePolygon(Offset(owlCenter.dx, owlCenter.dy - m * 0.02), m * 0.022, 3, size: 4.5, startAngle: pi));
        s.add(_makeEllipse(Offset(owlCenter.dx, owlCenter.dy + m * 0.14), m * 0.16, m * 0.13, size: 5.5));
        for (int i = 0; i < 3; i++) {
          s.add(_makeArc(Offset(owlCenter.dx, owlCenter.dy + m * (0.08 + i * 0.05)), m * 0.07, 0.2, pi - 0.4, size: 3.5));
        }
        s.add(_makeCircle(Offset(owlCenter.dx - m * 0.06, c.dy + m * 0.22), m * 0.03, size: 4.5));
        s.add(_makeCircle(Offset(owlCenter.dx + m * 0.06, c.dy + m * 0.22), m * 0.03, size: 4.5));
        break;

      case 3: // 🐧 Chubby Arctic Penguin
        s.add(_makeArc(Offset(c.dx, c.dy + m * 0.32), m * 0.32, 0.1, pi - 0.2, size: 5.5));
        s.add(_makeEllipse(c, m * 0.18, m * 0.25, size: 6.0));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.04), m * 0.13, m * 0.18, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.06, c.dy - m * 0.14), m * 0.025, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.06, c.dy - m * 0.14), m * 0.025, size: 4.5));
        s.add(_makePolygon(Offset(c.dx, c.dy - m * 0.09), m * 0.03, 3, size: 4.5, startAngle: pi));
        s.add(_makeEllipse(Offset(c.dx - m * 0.19, c.dy + m * 0.02), m * 0.05, m * 0.14, rotation: -0.25, size: 5.0));
        s.add(_makeEllipse(Offset(c.dx + m * 0.19, c.dy + m * 0.02), m * 0.05, m * 0.14, rotation: 0.25, size: 5.0));
        s.add(_makeEllipse(Offset(c.dx - m * 0.08, c.dy + m * 0.26), m * 0.06, m * 0.035, size: 5.0));
        s.add(_makeEllipse(Offset(c.dx + m * 0.08, c.dy + m * 0.26), m * 0.06, m * 0.035, size: 5.0));
        break;

      case 4: // 🦜 Rainbow Toucan
        s.add(_makeStroke([Offset(c.dx - m * 0.35, c.dy + m * 0.20), Offset(c.dx + m * 0.35, c.dy + m * 0.15)], size: 8.0));
        final tcHead = Offset(c.dx - m * 0.05, c.dy - m * 0.10);
        s.add(_makeCircle(tcHead, m * 0.13, size: 5.5));
        final beakPts = <Offset>[
          Offset(tcHead.dx + m * 0.06, tcHead.dy - m * 0.12),
          Offset(tcHead.dx + m * 0.28, tcHead.dy - m * 0.04),
          Offset(tcHead.dx + m * 0.30, tcHead.dy + m * 0.06),
          Offset(tcHead.dx + m * 0.06, tcHead.dy + m * 0.08),
          Offset(tcHead.dx + m * 0.06, tcHead.dy - m * 0.12),
        ];
        s.add(_makeStroke(beakPts, size: 5.5));
        s.add(_makeStroke([Offset(tcHead.dx + m * 0.14, tcHead.dy - m * 0.08), Offset(tcHead.dx + m * 0.14, tcHead.dy + m * 0.07)], size: 4.5));
        s.add(_makeStroke([Offset(tcHead.dx + m * 0.22, tcHead.dy - m * 0.06), Offset(tcHead.dx + m * 0.22, tcHead.dy + m * 0.06)], size: 4.5));
        s.add(_makeCircle(Offset(tcHead.dx - m * 0.03, tcHead.dy - m * 0.02), m * 0.035, size: 4.5));
        s.add(_makeCircle(Offset(tcHead.dx - m * 0.03, tcHead.dy - m * 0.02), m * 0.015, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx - m * 0.08, c.dy + m * 0.08), m * 0.14, m * 0.16, size: 5.5));
        s.add(_makePetal(Offset(c.dx - m * 0.12, c.dy + m * 0.18), 0, m * 0.26, pi * 0.65, 0.25, size: 5.5));
        s.add(_makePetal(Offset(c.dx - m * 0.22, c.dy - m * 0.20), 0, m * 0.16, -pi * 0.3, 0.5, size: 4.5));
        break;

      case 5: // 🌸 Darting Hummingbird
        final humHead = Offset(c.dx - m * 0.05, c.dy - m * 0.05);
        s.add(_makeCircle(humHead, m * 0.07, size: 5.0));
        s.add(_makeStroke([Offset(humHead.dx + m * 0.06, humHead.dy - m * 0.01), Offset(c.dx + m * 0.28, c.dy - m * 0.08)], size: 4.5));
        s.add(_makeCircle(Offset(humHead.dx - m * 0.01, humHead.dy - m * 0.01), m * 0.015, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx - m * 0.12, c.dy + m * 0.04), m * 0.12, m * 0.08, rotation: -0.4, size: 5.5));
        s.add(_makePetal(Offset(c.dx - m * 0.10, c.dy - m * 0.02), 0, m * 0.28, -pi * 0.65, 0.35, size: 5.0));
        s.add(_makePetal(Offset(c.dx - m * 0.06, c.dy - m * 0.04), 0, m * 0.26, -pi * 0.5, 0.35, size: 4.5));
        s.add(_makePetal(Offset(c.dx - m * 0.20, c.dy + m * 0.12), 0, m * 0.22, pi * 0.75, 0.25, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.30, c.dy - m * 0.08), m * 0.05, size: 4.5));
        for (int i = 0; i < 5; i++) {
          s.add(_makePetal(Offset(c.dx + m * 0.30, c.dy - m * 0.08), m * 0.04, m * 0.12, (2 * pi / 5) * i, 0.35, size: 4.0));
        }
        break;

      case 6: // 🦚 Majestic Crown Peacock
        final pcCenter = Offset(c.dx, c.dy + m * 0.14);
        for (int i = 0; i < 7; i++) {
          final a = -pi * 0.85 + (pi * 0.7 / 6) * i;
          s.add(_makePetal(pcCenter, m * 0.12, m * 0.42, a, 0.26, size: 4.5));
          final eyePt = Offset(pcCenter.dx + m * 0.34 * cos(a), pcCenter.dy + m * 0.34 * sin(a));
          s.add(_makeCircle(eyePt, m * 0.04, size: 4.0));
          s.add(_makeCircle(eyePt, m * 0.02, size: 4.0));
        }
        s.add(_makeEllipse(pcCenter, m * 0.11, m * 0.16, size: 5.5));
        final pcHead = Offset(c.dx, c.dy - m * 0.06);
        s.add(_makeCircle(pcHead, m * 0.07, size: 5.5));
        s.add(_makePolygon(Offset(pcHead.dx, pcHead.dy - m * 0.04), m * 0.02, 3, size: 4.5, startAngle: 0));
        s.add(_makeCircle(Offset(pcHead.dx - m * 0.015, pcHead.dy - m * 0.01), m * 0.012, size: 4.5));
        for (final angle in [-0.3, 0.0, 0.3]) {
          s.add(_makeStroke([Offset(pcHead.dx, pcHead.dy - m * 0.07), Offset(pcHead.dx + m * 0.05 * sin(angle), pcHead.dy - m * 0.13)], size: 3.5));
          s.add(_makeCircle(Offset(pcHead.dx + m * 0.05 * sin(angle), pcHead.dy - m * 0.14), m * 0.012, size: 4.0));
        }
        break;

      case 7: // 🐥 Puddle Duckling
        s.add(_makeArc(Offset(c.dx, c.dy + m * 0.22), m * 0.30, 0.2, pi - 0.4, size: 4.5));
        s.add(_makeArc(Offset(c.dx, c.dy + m * 0.28), m * 0.24, 0.3, pi - 0.6, size: 4.0));
        final dHead = Offset(c.dx - m * 0.06, c.dy - m * 0.10);
        s.add(_makeCircle(dHead, m * 0.13, size: 5.5));
        s.add(_makeEllipse(Offset(dHead.dx - m * 0.15, dHead.dy + m * 0.02), m * 0.07, m * 0.04, rotation: -0.15, size: 5.0));
        s.add(_makeCircle(Offset(dHead.dx - m * 0.02, dHead.dy - m * 0.02), m * 0.022, size: 5.0));
        s.add(_makeEllipse(Offset(c.dx + m * 0.04, c.dy + m * 0.08), m * 0.18, m * 0.14, rotation: -0.15, size: 5.5));
        s.add(_makePetal(Offset(c.dx + m * 0.02, c.dy + m * 0.08), 0, m * 0.16, -pi * 0.9, 0.4, size: 4.5));
        s.add(_makePetal(Offset(c.dx + m * 0.20, c.dy + m * 0.02), 0, m * 0.10, -pi * 0.2, 0.3, size: 4.5));
        break;

      case 8: // 🦢 Graceful Lake Swan
        s.add(_makeArc(Offset(c.dx, c.dy + m * 0.22), m * 0.32, 0.2, pi - 0.4, size: 4.5));
        s.add(_makeArc(Offset(c.dx, c.dy + m * 0.28), m * 0.26, 0.3, pi - 0.6, size: 4.0));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.10), m * 0.22, m * 0.12, rotation: -0.1, size: 5.5));
        s.add(_makePetal(Offset(c.dx + m * 0.02, c.dy + m * 0.04), 0, m * 0.20, -pi * 0.7, 0.35, size: 5.0));
        s.add(_makePetal(Offset(c.dx + m * 0.06, c.dy + m * 0.04), 0, m * 0.18, -pi * 0.55, 0.35, size: 4.5));
        final swHead = Offset(c.dx - m * 0.08, c.dy - m * 0.18);
        s.add(_makeCircle(swHead, m * 0.07, size: 5.5));
        s.add(_makePolygon(Offset(swHead.dx - m * 0.07, swHead.dy + m * 0.01), m * 0.025, 3, size: 4.5, startAngle: pi));
        s.add(_makeCircle(Offset(swHead.dx - m * 0.02, swHead.dy - m * 0.01), m * 0.015, size: 4.5));
        final swanNeck = <Offset>[
          Offset(swHead.dx + m * 0.04, swHead.dy + m * 0.05),
          Offset(swHead.dx + m * 0.12, swHead.dy + m * 0.12),
          Offset(swHead.dx + m * 0.06, swHead.dy + m * 0.20),
          Offset(c.dx - m * 0.12, c.dy + m * 0.08),
        ];
        s.add(_makeStroke(swanNeck, size: 6.0));
        break;

      case 9: // 🐓 Morning Rooster
        s.add(_makeCircle(Offset(c.dx + m * 0.25, c.dy - m * 0.22), m * 0.10, size: 4.5));
        for (int i = 0; i < 8; i++) {
          final a = (2 * pi / 8) * i;
          s.add(_makeStroke([
            Offset(c.dx + m * 0.25 + m * 0.12 * cos(a), c.dy - m * 0.22 + m * 0.12 * sin(a)),
            Offset(c.dx + m * 0.25 + m * 0.18 * cos(a), c.dy - m * 0.22 + m * 0.18 * sin(a)),
          ], size: 4.0));
        }
        final rooHead = Offset(c.dx - m * 0.08, c.dy - m * 0.12);
        s.add(_makeCircle(rooHead, m * 0.10, size: 5.5));
        for (int i = 0; i < 3; i++) {
          s.add(_makeCircle(Offset(rooHead.dx - m * 0.03 + i * 14, rooHead.dy - m * 0.10), m * 0.035, size: 4.5));
        }
        s.add(_makeCircle(Offset(rooHead.dx - m * 0.06, rooHead.dy + m * 0.08), m * 0.03, size: 4.5));
        s.add(_makePolygon(Offset(rooHead.dx - m * 0.10, rooHead.dy), m * 0.03, 3, size: 4.5, startAngle: pi));
        s.add(_makeCircle(Offset(rooHead.dx - m * 0.02, rooHead.dy - m * 0.02), m * 0.018, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.06), m * 0.16, m * 0.14, size: 5.5));
        s.add(_makePetal(Offset(c.dx + m * 0.12, c.dy + m * 0.02), 0, m * 0.30, -pi * 0.7, 0.25, size: 5.5));
        s.add(_makePetal(Offset(c.dx + m * 0.14, c.dy + m * 0.04), 0, m * 0.35, -pi * 0.55, 0.22, size: 5.0));
        s.add(_makePetal(Offset(c.dx + m * 0.16, c.dy + m * 0.06), 0, m * 0.32, -pi * 0.4, 0.25, size: 5.0));
        s.add(_makeStroke([Offset(c.dx - m * 0.04, c.dy + m * 0.18), Offset(c.dx - m * 0.04, c.dy + m * 0.30)], size: 5.0));
        s.add(_makeStroke([Offset(c.dx + m * 0.04, c.dy + m * 0.18), Offset(c.dx + m * 0.04, c.dy + m * 0.30)], size: 5.0));
        break;

      case 10: // 🌊 Coastal Flying Seagull
        s.add(_makeArc(Offset(c.dx - m * 0.20, c.dy + m * 0.24), m * 0.18, 0.2, pi - 0.4, size: 4.5));
        s.add(_makeArc(Offset(c.dx + m * 0.15, c.dy + m * 0.24), m * 0.18, 0.2, pi - 0.4, size: 4.5));
        s.add(_makeArc(Offset(c.dx, c.dy + m * 0.32), m * 0.25, 0.2, pi - 0.4, size: 4.0));
        final sgHead = Offset(c.dx, c.dy - m * 0.08);
        s.add(_makeCircle(sgHead, m * 0.07, size: 5.5));
        s.add(_makePolygon(Offset(sgHead.dx, sgHead.dy - m * 0.07), m * 0.025, 3, size: 4.5, startAngle: -pi / 2));
        s.add(_makeCircle(Offset(sgHead.dx - m * 0.02, sgHead.dy - m * 0.02), m * 0.015, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.02), m * 0.09, m * 0.15, size: 5.5));
        final leftWing = <Offset>[
          Offset(c.dx - m * 0.06, c.dy - m * 0.02),
          Offset(c.dx - m * 0.22, c.dy - m * 0.18),
          Offset(c.dx - m * 0.38, c.dy - m * 0.10),
          Offset(c.dx - m * 0.18, c.dy - m * 0.04),
          Offset(c.dx - m * 0.06, c.dy - m * 0.02),
        ];
        s.add(_makeStroke(leftWing, size: 5.5));
        final rightWing = <Offset>[
          Offset(c.dx + m * 0.06, c.dy - m * 0.02),
          Offset(c.dx + m * 0.22, c.dy - m * 0.18),
          Offset(c.dx + m * 0.38, c.dy - m * 0.10),
          Offset(c.dx + m * 0.18, c.dy - m * 0.04),
          Offset(c.dx + m * 0.06, c.dy - m * 0.02),
        ];
        s.add(_makeStroke(rightWing, size: 5.5));
        break;

      case 11: // 🌲 Blue Crested Jay
        s.add(_makeStroke([Offset(c.dx - m * 0.35, c.dy + m * 0.20), Offset(c.dx + m * 0.35, c.dy + m * 0.16)], size: 7.5));
        s.add(_makePolygon(Offset(c.dx + m * 0.22, c.dy + m * 0.24), m * 0.06, 5, size: 4.0));
        final bjHead = Offset(c.dx - m * 0.08, c.dy - m * 0.10);
        s.add(_makeCircle(bjHead, m * 0.11, size: 5.5));
        s.add(_makePolygon(Offset(bjHead.dx + m * 0.04, bjHead.dy - m * 0.12), m * 0.065, 3, size: 5.0, startAngle: -pi * 0.6));
        s.add(_makePolygon(Offset(bjHead.dx - m * 0.11, bjHead.dy), m * 0.025, 3, size: 4.5, startAngle: pi));
        s.add(_makeCircle(Offset(bjHead.dx - m * 0.02, bjHead.dy - m * 0.02), m * 0.018, size: 4.5));
        s.add(_makeArc(Offset(bjHead.dx + m * 0.02, bjHead.dy + m * 0.08), m * 0.06, 0.2, pi - 0.4, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx + m * 0.02, c.dy + m * 0.06), m * 0.15, m * 0.13, size: 5.5));
        s.add(_makePetal(Offset(c.dx + m * 0.04, c.dy + m * 0.06), 0, m * 0.18, pi * 0.35, 0.35, size: 5.0));
        s.add(_makePetal(Offset(c.dx + m * 0.14, c.dy + m * 0.12), 0, m * 0.26, pi * 0.42, 0.22, size: 5.0));
        break;

      case 12: // 🎵 Spring Song Robin
        s.add(_makeStroke([Offset(c.dx - m * 0.35, c.dy + m * 0.18), Offset(c.dx + m * 0.35, c.dy + m * 0.14)], size: 7.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.22, c.dy - m * 0.20), m * 0.03, size: 4.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.19, c.dy - m * 0.20), Offset(c.dx - m * 0.19, c.dy - m * 0.28)], size: 4.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.12, c.dy - m * 0.22), m * 0.03, size: 4.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.09, c.dy - m * 0.22), Offset(c.dx - m * 0.09, c.dy - m * 0.30)], size: 4.0));
        s.add(_makeStroke([Offset(c.dx - m * 0.19, c.dy - m * 0.28), Offset(c.dx - m * 0.09, c.dy - m * 0.30)], size: 4.5));
        final robHead = Offset(c.dx - m * 0.04, c.dy - m * 0.08);
        s.add(_makeCircle(robHead, m * 0.12, size: 5.5));
        s.add(_makePolygon(Offset(robHead.dx - m * 0.12, robHead.dy - m * 0.02), m * 0.028, 3, size: 4.5, startAngle: pi));
        s.add(_makeCircle(Offset(robHead.dx - m * 0.02, robHead.dy - m * 0.02), m * 0.02, size: 5.0));
        s.add(_makeEllipse(Offset(c.dx + m * 0.04, c.dy + m * 0.06), m * 0.16, m * 0.14, size: 5.5));
        s.add(_makeArc(Offset(c.dx - m * 0.04, c.dy + m * 0.04), m * 0.11, -pi * 0.2, pi * 0.8, size: 4.5));
        s.add(_makePetal(Offset(c.dx + m * 0.08, c.dy + m * 0.06), 0, m * 0.18, pi * 0.3, 0.35, size: 4.5));
        break;

      case 13: // 🐣 Tiny Spring Chick
        final egY = c.dy + m * 0.10;
        final shellPts = <Offset>[
          Offset(c.dx - m * 0.18, egY),
          Offset(c.dx - m * 0.12, egY - m * 0.06),
          Offset(c.dx - m * 0.06, egY),
          Offset(c.dx, egY - m * 0.06),
          Offset(c.dx + m * 0.06, egY),
          Offset(c.dx + m * 0.12, egY - m * 0.06),
          Offset(c.dx + m * 0.18, egY),
          Offset(c.dx + m * 0.14, egY + m * 0.18),
          Offset(c.dx, egY + m * 0.22),
          Offset(c.dx - m * 0.14, egY + m * 0.18),
          Offset(c.dx - m * 0.18, egY),
        ];
        s.add(_makeStroke(shellPts, size: 5.5));
        final chHead = Offset(c.dx, egY - m * 0.12);
        s.add(_makeCircle(chHead, m * 0.13, size: 5.5));
        s.add(_makeCircle(Offset(chHead.dx - m * 0.04, chHead.dy - m * 0.01), m * 0.02, size: 5.0));
        s.add(_makeCircle(Offset(chHead.dx + m * 0.04, chHead.dy - m * 0.01), m * 0.02, size: 5.0));
        s.add(_makePolygon(Offset(chHead.dx, chHead.dy + m * 0.03), m * 0.02, 3, size: 4.5, startAngle: pi));
        s.add(_makeStroke([Offset(chHead.dx, chHead.dy - m * 0.13), Offset(chHead.dx - m * 0.02, chHead.dy - m * 0.20)], size: 4.0));
        s.add(_makeStroke([Offset(chHead.dx, chHead.dy - m * 0.13), Offset(chHead.dx + m * 0.02, chHead.dy - m * 0.20)], size: 4.0));
        s.add(_makeEllipse(Offset(chHead.dx - m * 0.12, chHead.dy + m * 0.06), m * 0.04, m * 0.06, rotation: -0.3, size: 4.5));
        s.add(_makeEllipse(Offset(chHead.dx + m * 0.12, chHead.dy + m * 0.06), m * 0.04, m * 0.06, rotation: 0.3, size: 4.5));
        break;

      case 14: // 🦜 Crested Cockatoo
        s.add(_makeStroke([Offset(c.dx - m * 0.35, c.dy + m * 0.22), Offset(c.dx + m * 0.35, c.dy + m * 0.18)], size: 7.5));
        final cktHead = Offset(c.dx - m * 0.04, c.dy - m * 0.06);
        s.add(_makeCircle(cktHead, m * 0.13, size: 5.5));
        for (int i = 0; i < 5; i++) {
          final a = -pi * 0.75 + (pi * 0.4 / 4) * i;
          s.add(_makePetal(cktHead, m * 0.11, m * 0.30, a, 0.22, size: 5.0));
        }
        s.add(_makeArc(Offset(cktHead.dx - m * 0.10, cktHead.dy + m * 0.03), m * 0.07, -pi * 0.4, pi * 0.7, size: 6.0));
        s.add(_makeCircle(Offset(cktHead.dx, cktHead.dy - m * 0.01), m * 0.02, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx + m * 0.04, c.dy + m * 0.10), m * 0.16, m * 0.14, size: 5.5));
        s.add(_makePetal(Offset(c.dx + m * 0.06, c.dy + m * 0.10), 0, m * 0.20, pi * 0.4, 0.35, size: 5.0));
        break;

      case 15: // 🌳 Forest Woodpecker
        s.add(_makeStroke([Offset(c.dx + m * 0.18, c.dy - m * 0.35), Offset(c.dx + m * 0.18, c.dy + m * 0.35)], size: 10.0));
        s.add(_makeStroke([Offset(c.dx + m * 0.28, c.dy - m * 0.35), Offset(c.dx + m * 0.28, c.dy + m * 0.35)], size: 6.0));
        final wpHead = Offset(c.dx - m * 0.02, c.dy - m * 0.12);
        s.add(_makeCircle(wpHead, m * 0.09, size: 5.5));
        s.add(_makeStroke([Offset(wpHead.dx + m * 0.08, wpHead.dy), Offset(c.dx + m * 0.18, wpHead.dy)], size: 5.5));
        s.add(_makePolygon(Offset(wpHead.dx - m * 0.04, wpHead.dy - m * 0.08), m * 0.05, 3, size: 4.5, startAngle: -pi * 0.7));
        s.add(_makeCircle(Offset(wpHead.dx + m * 0.02, wpHead.dy - m * 0.02), m * 0.018, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx - m * 0.04, c.dy + m * 0.04), m * 0.10, m * 0.16, rotation: 0.15, size: 5.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.02, c.dy + m * 0.18), Offset(c.dx + m * 0.12, c.dy + m * 0.28)], size: 6.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.14, c.dy + m * 0.08), m * 0.03, size: 4.5));
        break;

      case 16: // 🕊️ Peaceful White Dove
        final dvHead = Offset(c.dx - m * 0.08, c.dy - m * 0.10);
        s.add(_makeCircle(dvHead, m * 0.08, size: 5.5));
        s.add(_makePolygon(Offset(dvHead.dx - m * 0.07, dvHead.dy), m * 0.022, 3, size: 4.5, startAngle: pi));
        s.add(_makeCircle(Offset(dvHead.dx - m * 0.02, dvHead.dy - m * 0.01), m * 0.015, size: 4.5));
        s.add(_makeStroke([Offset(dvHead.dx - m * 0.08, dvHead.dy), Offset(dvHead.dx - m * 0.22, dvHead.dy - m * 0.04)], size: 4.0));
        s.add(_makePetal(Offset(dvHead.dx - m * 0.15, dvHead.dy - m * 0.02), 0, m * 0.05, -pi * 0.5, 0.35, size: 3.5));
        s.add(_makePetal(Offset(dvHead.dx - m * 0.20, dvHead.dy - m * 0.04), 0, m * 0.05, -pi * 0.7, 0.35, size: 3.5));
        s.add(_makeEllipse(Offset(c.dx, c.dy + m * 0.02), m * 0.13, m * 0.11, size: 5.5));
        s.add(_makePetal(Offset(c.dx, c.dy - m * 0.04), 0, m * 0.32, -pi * 0.65, 0.35, size: 5.5));
        s.add(_makePetal(Offset(c.dx + m * 0.06, c.dy - m * 0.02), 0, m * 0.28, -pi * 0.45, 0.35, size: 5.0));
        s.add(_makePetal(Offset(c.dx + m * 0.14, c.dy + m * 0.06), 0, m * 0.22, pi * 0.15, 0.3, size: 5.0));
        break;

      case 17: // 🌾 Garden Song Sparrow
      default:
        s.add(_makeStroke([Offset(c.dx - m * 0.35, c.dy + m * 0.16), Offset(c.dx + m * 0.35, c.dy + m * 0.12)], size: 7.0));
        final spHead = Offset(c.dx - m * 0.08, c.dy - m * 0.08);
        s.add(_makeCircle(spHead, m * 0.11, size: 5.5));
        s.add(_makePolygon(Offset(spHead.dx - m * 0.10, spHead.dy), m * 0.025, 3, size: 4.5, startAngle: pi));
        s.add(_makeCircle(Offset(spHead.dx - m * 0.02, spHead.dy - m * 0.02), m * 0.018, size: 4.5));
        s.add(_makeEllipse(Offset(c.dx + m * 0.02, c.dy + m * 0.06), m * 0.16, m * 0.13, size: 5.5));
        s.add(_makePetal(Offset(c.dx + m * 0.04, c.dy + m * 0.06), 0, m * 0.18, pi * 0.3, 0.35, size: 4.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.02, c.dy + m * 0.02), Offset(c.dx + m * 0.12, c.dy + m * 0.06)], size: 3.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.04, c.dy + m * 0.06), Offset(c.dx + m * 0.14, c.dy + m * 0.10)], size: 3.5));
        s.add(_makePetal(Offset(c.dx + m * 0.16, c.dy + m * 0.10), 0, m * 0.20, pi * 0.38, 0.2, size: 5.0));
        break;
    }
  }

  /// Flowers & Gardens - 18 distinct handcrafted vector motifs
  static void _generateFlowers(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif % 18) {
      case 0: // 🌻 Giant Golden Sunflower
        final flCenter = Offset(c.dx, c.dy - m * 0.08);
        for (int i = 0; i < 16; i++) {
          final a = (2 * pi / 16) * i;
          s.add(_makePetal(flCenter, m * 0.14, m * 0.32, a, 0.24, size: 4.5));
        }
        s.add(_makeCircle(flCenter, m * 0.14, size: 5.5));
        s.add(_makeCircle(flCenter, m * 0.08, size: 3.5));
        s.add(_makeStroke([Offset(c.dx, flCenter.dy + m * 0.14), Offset(c.dx, c.dy + m * 0.35)], size: 7.0));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.18), 0, m * 0.18, -pi * 0.8, 0.45, size: 4.5));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.24), 0, m * 0.18, -pi * 0.2, 0.45, size: 4.5));
        break;

      case 1: // 🌷 Spring Dutch Tulips
        for (final offset in [-m * 0.14, 0.0, m * 0.14]) {
          final tulX = c.dx + offset;
          final tulY = c.dy - (offset == 0 ? m * 0.12 : m * 0.04);
          s.add(_makeStroke([Offset(tulX, tulY + m * 0.10), Offset(tulX, c.dy + m * 0.35)], size: 5.5));
          s.add(_makeEllipse(Offset(tulX, tulY), m * 0.08, m * 0.11, size: 5.5));
          s.add(_makePetal(Offset(tulX - m * 0.04, tulY), 0, m * 0.10, -pi * 0.6, 0.3, size: 4.0));
          s.add(_makePetal(Offset(tulX + m * 0.04, tulY), 0, m * 0.10, -pi * 0.4, 0.3, size: 4.0));
          s.add(_makePetal(Offset(tulX, c.dy + m * 0.20), 0, m * 0.22, offset < 0 ? -pi * 0.75 : -pi * 0.25, 0.25, size: 4.5));
        }
        break;

      case 2: // 🌼 Field Daisy Meadow
        final dzyCenter = Offset(c.dx, c.dy - m * 0.06);
        for (int i = 0; i < 14; i++) {
          final a = (2 * pi / 14) * i;
          s.add(_makePetal(dzyCenter, m * 0.08, m * 0.28, a, 0.25, size: 4.5));
        }
        s.add(_makeCircle(dzyCenter, m * 0.08, size: 5.5));
        s.add(_makeStroke([Offset(c.dx, dzyCenter.dy + m * 0.08), Offset(c.dx, c.dy + m * 0.35)], size: 6.0));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.18), 0, m * 0.16, -pi * 0.8, 0.35, size: 4.5));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.24), 0, m * 0.16, -pi * 0.2, 0.35, size: 4.5));
        break;

      case 3: // 🌸 Cherry Blossom Branch
        s.add(_makeStroke([
          Offset(c.dx - m * 0.35, c.dy + m * 0.18),
          Offset(c.dx - m * 0.10, c.dy + m * 0.04),
          Offset(c.dx + m * 0.15, c.dy - m * 0.06),
          Offset(c.dx + m * 0.35, c.dy - m * 0.20),
        ], size: 7.5));
        for (final blossomCenter in [
          Offset(c.dx - m * 0.12, c.dy - m * 0.04),
          Offset(c.dx + m * 0.08, c.dy - m * 0.14),
          Offset(c.dx + m * 0.20, c.dy + m * 0.06),
        ]) {
          for (int i = 0; i < 5; i++) {
            final a = (2 * pi / 5) * i;
            s.add(_makePetal(blossomCenter, m * 0.03, m * 0.11, a, 0.38, size: 4.0));
          }
          s.add(_makeCircle(blossomCenter, m * 0.03, size: 4.0));
        }
        s.add(_makePetal(Offset(c.dx - m * 0.24, c.dy + m * 0.02), 0, m * 0.06, pi * 0.3, 0.4, size: 3.5));
        s.add(_makePetal(Offset(c.dx + m * 0.25, c.dy + m * 0.20), 0, m * 0.06, pi * 0.7, 0.4, size: 3.5));
        break;

      case 4: // 🌹 Classic Blooming Rose
        final roseCenter = Offset(c.dx, c.dy - m * 0.06);
        for (int i = 1; i <= 4; i++) {
          s.add(_makeArc(roseCenter, m * (0.04 + i * 0.05), i * 0.8, pi * 1.2, size: 5.0));
        }
        for (int i = 0; i < 8; i++) {
          final a = (2 * pi / 8) * i;
          s.add(_makePetal(roseCenter, m * 0.15, m * 0.28, a, 0.45, size: 4.5));
        }
        s.add(_makeStroke([Offset(c.dx, roseCenter.dy + m * 0.22), Offset(c.dx, c.dy + m * 0.35)], size: 6.0));
        s.add(_makePolygon(Offset(c.dx - m * 0.01, c.dy + m * 0.22), m * 0.02, 3, size: 4.0, startAngle: pi));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.22), 0, m * 0.16, -pi * 0.25, 0.35, size: 4.5));
        break;

      case 5: // 🪷 Serene Sacred Lotus
        final ltCenter = Offset(c.dx, c.dy + m * 0.04);
        s.add(_makeEllipse(Offset(c.dx, ltCenter.dy + m * 0.12), m * 0.32, m * 0.09, size: 5.5));
        s.add(_makePetal(ltCenter, 0, m * 0.28, -pi / 2, 0.35, size: 5.5));
        s.add(_makePetal(ltCenter, 0, m * 0.24, -pi * 0.65, 0.35, size: 5.0));
        s.add(_makePetal(ltCenter, 0, m * 0.24, -pi * 0.35, 0.35, size: 5.0));
        s.add(_makePetal(ltCenter, 0, m * 0.18, -pi * 0.8, 0.35, size: 4.5));
        s.add(_makePetal(ltCenter, 0, m * 0.18, -pi * 0.2, 0.35, size: 4.5));
        s.add(_makeArc(Offset(c.dx, c.dy + m * 0.26), m * 0.35, 0.2, pi - 0.4, size: 4.0));
        break;

      case 6: // 🌺 Tropical Hibiscus Bloom
        final hibCenter = c;
        for (int i = 0; i < 5; i++) {
          final a = -pi / 2 + (2 * pi / 5) * i;
          s.add(_makePetal(hibCenter, m * 0.06, m * 0.34, a, 0.48, size: 5.0));
        }
        s.add(_makeStroke([
          hibCenter,
          Offset(c.dx + m * 0.10, c.dy - m * 0.12),
          Offset(c.dx + m * 0.22, c.dy - m * 0.22),
        ], size: 5.5));
        for (int i = 0; i < 5; i++) {
          final pAngle = (2 * pi / 5) * i;
          s.add(_makeCircle(Offset(c.dx + m * 0.22 + m * 0.03 * cos(pAngle), c.dy - m * 0.22 + m * 0.03 * sin(pAngle)), m * 0.015, size: 4.0));
        }
        s.add(_makePetal(Offset(c.dx - m * 0.18, c.dy + m * 0.18), 0, m * 0.18, pi * 0.75, 0.35, size: 4.5));
        break;

      case 7: // 🏵️ Radiant Aztec Marigold
        final mgCenter = Offset(c.dx, c.dy - m * 0.04);
        for (int ring = 1; ring <= 4; ring++) {
          final count = 6 + ring * 4;
          final rOut = m * (0.07 + ring * 0.06);
          final rIn = m * (0.04 + ring * 0.05);
          for (int i = 0; i < count; i++) {
            final a = (2 * pi / count) * i;
            s.add(_makePetal(mgCenter, rIn, rOut, a, 0.3, size: 4.0));
          }
        }
        s.add(_makeCircle(mgCenter, m * 0.06, size: 5.0));
        s.add(_makeStroke([Offset(c.dx, mgCenter.dy + m * 0.26), Offset(c.dx, c.dy + m * 0.36)], size: 6.5));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.24), 0, m * 0.18, -pi * 0.8, 0.3, size: 4.5));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.28), 0, m * 0.18, -pi * 0.2, 0.3, size: 4.5));
        break;

      case 8: // 🌼 Golden Spring Daffodil
        final dafCenter = Offset(c.dx, c.dy - m * 0.06);
        for (int i = 0; i < 6; i++) {
          final a = (2 * pi / 6) * i;
          s.add(_makePetal(dafCenter, m * 0.08, m * 0.32, a, 0.38, size: 5.0));
        }
        s.add(_makeCircle(dafCenter, m * 0.11, size: 5.5));
        for (int i = 0; i < 8; i++) {
          final a = (2 * pi / 8) * i;
          s.add(_makeArc(Offset(dafCenter.dx + m * 0.11 * cos(a), dafCenter.dy + m * 0.11 * sin(a)), m * 0.025, a, pi, size: 3.5));
        }
        s.add(_makeCircle(dafCenter, m * 0.04, size: 4.0));
        s.add(_makeStroke([Offset(c.dx, dafCenter.dy + m * 0.11), Offset(c.dx, c.dy + m * 0.35)], size: 6.0));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.20), 0, m * 0.22, -pi * 0.75, 0.2, size: 4.5));
        break;

      case 9: // 🌿 Exotic Regal Orchid
        s.add(_makeStroke([
          Offset(c.dx - m * 0.18, c.dy + m * 0.35),
          Offset(c.dx - m * 0.10, c.dy + m * 0.05),
          Offset(c.dx + m * 0.08, c.dy - m * 0.15),
          Offset(c.dx + m * 0.24, c.dy - m * 0.24),
        ], size: 6.0));
        for (final orcCenter in [
          Offset(c.dx - m * 0.06, c.dy + m * 0.04),
          Offset(c.dx + m * 0.12, c.dy - m * 0.12),
        ]) {
          s.add(_makePetal(orcCenter, 0, m * 0.13, -pi / 2, 0.35, size: 4.5));
          s.add(_makePetal(orcCenter, 0, m * 0.12, -pi * 0.1, 0.35, size: 4.5));
          s.add(_makePetal(orcCenter, 0, m * 0.12, -pi * 0.9, 0.35, size: 4.5));
          s.add(_makeEllipse(Offset(orcCenter.dx, orcCenter.dy + m * 0.05), m * 0.06, m * 0.08, size: 5.0));
        }
        break;

      case 10: // 🔔 Woodland Wild Bluebells
        s.add(_makeStroke([
          Offset(c.dx - m * 0.12, c.dy + m * 0.35),
          Offset(c.dx - m * 0.05, c.dy + m * 0.05),
          Offset(c.dx + m * 0.08, c.dy - m * 0.15),
          Offset(c.dx + m * 0.20, c.dy - m * 0.25),
        ], size: 5.5));
        for (int i = 0; i < 4; i++) {
          final bellX = c.dx - m * 0.02 + i * 18;
          final bellY = c.dy - m * 0.16 + i * 28;
          s.add(_makeArc(Offset(bellX, bellY), m * 0.05, 0.2, pi - 0.4, size: 4.5));
          s.add(_makeStroke([Offset(bellX - m * 0.05, bellY), Offset(bellX - m * 0.03, bellY - m * 0.06)], size: 4.0));
          s.add(_makeStroke([Offset(bellX + m * 0.05, bellY), Offset(bellX + m * 0.03, bellY - m * 0.06)], size: 4.0));
        }
        break;

      case 11: // 🌸 Ruffled Carnation
        final crnCenter = Offset(c.dx, c.dy - m * 0.06);
        for (int ring = 1; ring <= 3; ring++) {
          final count = 8 + ring * 2;
          for (int i = 0; i < count; i++) {
            final a = (2 * pi / count) * i;
            s.add(_makePetal(crnCenter, m * (0.05 + ring * 0.04), m * (0.12 + ring * 0.06), a, 0.38, size: 4.0));
          }
        }
        final calyxPts = <Offset>[
          Offset(crnCenter.dx - m * 0.08, crnCenter.dy + m * 0.18),
          Offset(crnCenter.dx + m * 0.08, crnCenter.dy + m * 0.18),
          Offset(crnCenter.dx + m * 0.04, crnCenter.dy + m * 0.26),
          Offset(crnCenter.dx - m * 0.04, crnCenter.dy + m * 0.26),
          Offset(crnCenter.dx - m * 0.08, crnCenter.dy + m * 0.18),
        ];
        s.add(_makeStroke(calyxPts, size: 4.5));
        s.add(_makeStroke([Offset(c.dx, crnCenter.dy + m * 0.26), Offset(c.dx, c.dy + m * 0.36)], size: 6.0));
        break;

      case 12: // 🌺 Wild Scarlet Poppy
        final popCenter = Offset(c.dx, c.dy - m * 0.06);
        for (int i = 0; i < 4; i++) {
          final a = -pi / 4 + (pi / 2) * i;
          s.add(_makePetal(popCenter, m * 0.08, m * 0.34, a, 0.65, size: 5.5));
        }
        s.add(_makeCircle(popCenter, m * 0.07, size: 5.0));
        for (int i = 0; i < 8; i++) {
          final a = (2 * pi / 8) * i;
          s.add(_makeStroke([popCenter, Offset(popCenter.dx + m * 0.07 * cos(a), popCenter.dy + m * 0.07 * sin(a))], size: 3.5));
        }
        s.add(_makeStroke([Offset(c.dx, popCenter.dy + m * 0.18), Offset(c.dx, c.dy + m * 0.35)], size: 6.0));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.22), 0, m * 0.16, -pi * 0.8, 0.3, size: 4.5));
        break;

      case 13: // 🤍 Graceful Calla Lily
        final lilyCenter = Offset(c.dx, c.dy - m * 0.08);
        final spathePts = <Offset>[
          Offset(lilyCenter.dx, lilyCenter.dy - m * 0.24),
          Offset(lilyCenter.dx + m * 0.14, lilyCenter.dy - m * 0.12),
          Offset(lilyCenter.dx + m * 0.12, lilyCenter.dy + m * 0.10),
          Offset(lilyCenter.dx, lilyCenter.dy + m * 0.18),
          Offset(lilyCenter.dx - m * 0.12, lilyCenter.dy + m * 0.10),
          Offset(lilyCenter.dx - m * 0.14, lilyCenter.dy - m * 0.12),
          Offset(lilyCenter.dx, lilyCenter.dy - m * 0.24),
        ];
        s.add(_makeStroke(spathePts, size: 5.5));
        s.add(_makeStroke([Offset(lilyCenter.dx, lilyCenter.dy + m * 0.10), Offset(lilyCenter.dx, lilyCenter.dy - m * 0.08)], size: 6.0));
        s.add(_makeStroke([Offset(c.dx, lilyCenter.dy + m * 0.18), Offset(c.dx, c.dy + m * 0.35)], size: 6.5));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.22), 0, m * 0.20, -pi * 0.8, 0.4, size: 5.0));
        break;

      case 14: // 💜 Fragrant Lavender Sprigs
        for (int sprig = -1; sprig <= 1; sprig++) {
          final spX = c.dx + sprig * 22;
          final spTop = c.dy - m * 0.24 + sprig.abs() * 14;
          s.add(_makeStroke([Offset(spX, spTop), Offset(c.dx + sprig * 8, c.dy + m * 0.30)], size: 5.0));
          for (int i = 0; i < 7; i++) {
            final yF = spTop + i * 16;
            s.add(_makeCircle(Offset(spX - m * 0.03, yF), m * 0.025, size: 4.0));
            s.add(_makeCircle(Offset(spX + m * 0.03, yF), m * 0.025, size: 4.0));
          }
        }
        s.add(_makeCircle(Offset(c.dx, c.dy + m * 0.18), m * 0.035, size: 4.5));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.18), 0, m * 0.08, -pi * 0.8, 0.4, size: 4.5));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.18), 0, m * 0.08, -pi * 0.2, 0.4, size: 4.5));
        break;

      case 15: // 🌵 Desert Echeveria Succulent
        final sucCenter = Offset(c.dx, c.dy - m * 0.02);
        for (int ring = 1; ring <= 3; ring++) {
          final count = 6 + ring * 2;
          for (int i = 0; i < count; i++) {
            final a = (2 * pi / count) * i;
            s.add(_makePetal(sucCenter, m * (0.05 + ring * 0.05), m * (0.12 + ring * 0.08), a, 0.4, size: 4.5));
          }
        }
        s.add(_makeCircle(sucCenter, m * 0.05, size: 4.5));
        final potPts = <Offset>[
          Offset(c.dx - m * 0.22, c.dy + m * 0.18),
          Offset(c.dx + m * 0.22, c.dy + m * 0.18),
          Offset(c.dx + m * 0.16, c.dy + m * 0.36),
          Offset(c.dx - m * 0.16, c.dy + m * 0.36),
          Offset(c.dx - m * 0.22, c.dy + m * 0.18),
        ];
        s.add(_makeStroke(potPts, size: 5.5));
        break;

      case 16: // 🌾 Wished Dandelion Bloom
        final dndCenter = Offset(c.dx - m * 0.12, c.dy - m * 0.08);
        s.add(_makeCircle(dndCenter, m * 0.04, size: 5.0));
        for (int i = 0; i < 16; i++) {
          final a = (2 * pi / 16) * i;
          s.add(_makeStroke([dndCenter, Offset(dndCenter.dx + m * 0.16 * cos(a), dndCenter.dy + m * 0.16 * sin(a))], size: 3.5));
          s.add(_makeCircle(Offset(dndCenter.dx + m * 0.16 * cos(a), dndCenter.dy + m * 0.16 * sin(a)), m * 0.015, size: 3.5));
        }
        s.add(_makeStroke([Offset(dndCenter.dx, dndCenter.dy + m * 0.04), Offset(c.dx - m * 0.06, c.dy + m * 0.35)], size: 5.5));
        for (final seedPt in [
          Offset(c.dx + m * 0.14, c.dy - m * 0.20),
          Offset(c.dx + m * 0.24, c.dy - m * 0.14),
          Offset(c.dx + m * 0.20, c.dy - m * 0.04),
        ]) {
          s.add(_makeStroke([seedPt, Offset(seedPt.dx + m * 0.04, seedPt.dy - m * 0.04)], size: 3.0));
          s.add(_makeStar(Offset(seedPt.dx + m * 0.04, seedPt.dy - m * 0.04), m * 0.025, m * 0.012, 5, size: 3.0));
        }
        break;

      case 17: // 🌺 Lush Spring Peony
      default:
        final pnyCenter = Offset(c.dx, c.dy - m * 0.06);
        for (int ring = 1; ring <= 4; ring++) {
          final count = 6 + ring * 3;
          for (int i = 0; i < count; i++) {
            final a = (2 * pi / count) * i;
            s.add(_makePetal(pnyCenter, m * (0.04 + ring * 0.04), m * (0.10 + ring * 0.06), a, 0.42, size: 4.5));
          }
        }
        s.add(_makeCircle(pnyCenter, m * 0.05, size: 4.5));
        s.add(_makeStroke([Offset(c.dx, pnyCenter.dy + m * 0.24), Offset(c.dx, c.dy + m * 0.35)], size: 6.5));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.22), 0, m * 0.18, -pi * 0.75, 0.4, size: 5.0));
        s.add(_makePetal(Offset(c.dx, c.dy + m * 0.26), 0, m * 0.18, -pi * 0.25, 0.4, size: 5.0));
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 16. TRENDING & POP ART (10 Distinct Motifs)
  // ═══════════════════════════════════════════════════════════════════════════
  static void _generateTrendingArt(List<Stroke> s, Random rng, Offset c, double m, int motif) {
    switch (motif) {
      case 0: // 🌅 Synthwave 80s Sunset Grid Highway
        // Giant Retro Horizon Sun
        s.add(_makeArc(Offset(c.dx, c.dy - m * 0.04), m * 0.26, -pi, pi, size: 5.0));
        // Horizontal Neon Sun Slats
        for (int i = 1; i <= 5; i++) {
          final dy = c.dy - m * 0.04 + i * m * 0.038;
          final dx = sqrt(max(0.0, pow(m * 0.26, 2) - pow(dy - (c.dy - m * 0.04), 2)));
          s.add(_makeStroke([Offset(c.dx - dx, dy), Offset(c.dx + dx, dy)], size: 3.5));
        }
        // Horizon Baseline
        final horizY = c.dy + m * 0.16;
        s.add(_makeStroke([Offset(c.dx - m * 0.42, horizY), Offset(c.dx + m * 0.42, horizY)], size: 5.0));
        // Vanishing Perspective Highway Grid
        for (int k = -4; k <= 4; k++) {
          s.add(_makeStroke([Offset(c.dx, horizY), Offset(c.dx + k * m * 0.11, c.dy + m * 0.42)], size: 3.5));
        }
        // Perspective Horizontal Grid Lines
        for (int h = 1; h <= 4; h++) {
          final lineY = horizY + (h * h) * m * 0.016;
          s.add(_makeStroke([Offset(c.dx - m * 0.40, lineY), Offset(c.dx + m * 0.40, lineY)], size: 3.0));
        }
        // Retro Palm Tree Silhouette on Left
        s.add(_makeStroke([
          Offset(c.dx - m * 0.32, horizY + m * 0.15),
          Offset(c.dx - m * 0.28, horizY),
          Offset(c.dx - m * 0.24, horizY - m * 0.18),
        ], size: 5.5));
        // Palm Fronds
        final pHead = Offset(c.dx - m * 0.24, horizY - m * 0.18);
        for (final angle in [-0.4, -0.8, -1.2, -1.8, -2.4]) {
          s.add(_makePetal(pHead, 0, m * 0.14, angle, 0.35, size: 4.0));
        }
        break;

      case 1: // 🏙️ Cyberpunk Neon Skyline
        // Background Moon / Digital Circle
        s.add(_makeCircle(Offset(c.dx, c.dy - m * 0.14), m * 0.22, size: 4.5));
        // Skyscraper 1 (Left Angled Tower)
        s.add(_makePolygon(Offset(c.dx - m * 0.24, c.dy + m * 0.10), m * 0.18, 4, startAngle: pi / 4, size: 4.5));
        s.add(_makeStroke([Offset(c.dx - m * 0.24, c.dy - m * 0.05), Offset(c.dx - m * 0.24, c.dy - m * 0.24)], size: 4.0));
        // Skyscraper 2 (Center Mega Tower)
        s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.12, c.dy - m * 0.18, m * 0.24, m * 0.58), size: 4.5));
        s.add(_makeStroke([Offset(c.dx, c.dy - m * 0.18), Offset(c.dx, c.dy - m * 0.38)], size: 4.5));
        s.add(_makeCircle(Offset(c.dx, c.dy - m * 0.38), m * 0.02, size: 3.5));
        // High-Tech Windows Grid on Mega Tower
        for (int row = 0; row < 5; row++) {
          final wY = c.dy - m * 0.10 + row * m * 0.07;
          s.add(_makeRect(Rect.fromLTWH(c.dx - m * 0.08, wY, m * 0.06, m * 0.04), size: 2.5));
          s.add(_makeRect(Rect.fromLTWH(c.dx + m * 0.02, wY, m * 0.06, m * 0.04), size: 2.5));
        }
        // Skyscraper 3 (Right Stepped Tower)
        s.add(_makeRect(Rect.fromLTWH(c.dx + m * 0.15, c.dy + m * 0.02, m * 0.20, m * 0.38), size: 4.5));
        s.add(_makeStroke([Offset(c.dx + m * 0.25, c.dy + m * 0.02), Offset(c.dx + m * 0.25, c.dy - m * 0.15)], size: 4.0));
        // Flying Spinner Vehicle Zooming Across
        s.add(_makeEllipse(Offset(c.dx - m * 0.05, c.dy - m * 0.24), m * 0.08, m * 0.025, rotation: -0.15, size: 4.0));
        s.add(_makeStroke([Offset(c.dx - m * 0.30, c.dy - m * 0.20), Offset(c.dx - m * 0.13, c.dy - m * 0.23)], size: 3.0));
        break;

      case 2: // 🏛️ Vaporwave Classical Statue & Pyramids
        // Classical Sculpture Head
        final bustY = c.dy - m * 0.04;
        s.add(_makeCircle(Offset(c.dx, bustY), m * 0.18, size: 4.5));
        // Classical Hair Ringlets
        for (int i = 0; i < 6; i++) {
          final ang = -pi * 0.8 + (pi * 0.8 / 5) * i;
          s.add(_makeCircle(Offset(c.dx + (m * 0.19) * cos(ang), bustY + (m * 0.19) * sin(ang)), m * 0.04, size: 3.5));
        }
        // Marble Pedestal / Classical Torso
        s.add(_makeStroke([
          Offset(c.dx - m * 0.18, bustY + m * 0.14),
          Offset(c.dx - m * 0.12, c.dy + m * 0.35),
          Offset(c.dx + m * 0.12, c.dy + m * 0.35),
          Offset(c.dx + m * 0.18, bustY + m * 0.14),
        ], size: 4.5));
        // Classical Blindfold / Glitch Bar across eyes
        s.add(_makeRect(Rect.fromCenter(center: Offset(c.dx, bustY), width: m * 0.28, height: m * 0.055), size: 4.0));
        // Floating 3D Wireframe Pyramid in background
        final pyrApex = Offset(c.dx + m * 0.24, c.dy - m * 0.26);
        final pyrL = Offset(c.dx + m * 0.12, c.dy - m * 0.10);
        final pyrR = Offset(c.dx + m * 0.36, c.dy - m * 0.10);
        final pyrC = Offset(c.dx + m * 0.24, c.dy - m * 0.06);
        s.add(_makeStroke([pyrApex, pyrL, pyrC, pyrApex, pyrR, pyrC], size: 3.5));
        s.add(_makeStroke([pyrL, pyrR], size: 3.0));
        // Floating Diamond Glitches
        s.add(_makePolygon(Offset(c.dx - m * 0.26, c.dy - m * 0.20), m * 0.06, 4, size: 3.5));
        s.add(_makePolygon(Offset(c.dx - m * 0.28, c.dy + m * 0.15), m * 0.04, 4, size: 3.0));
        break;

      case 3: // 🧋 Kawaii Aesthetic Boba Cup
        final cupY = c.dy + m * 0.06;
        // Tapered Boba Cup Body
        s.add(_makeStroke([
          Offset(c.dx - m * 0.18, cupY - m * 0.18),
          Offset(c.dx - m * 0.13, cupY + m * 0.28),
          Offset(c.dx + m * 0.13, cupY + m * 0.28),
          Offset(c.dx + m * 0.18, cupY - m * 0.18),
          Offset(c.dx - m * 0.18, cupY - m * 0.18),
        ], size: 5.0));
        // Rounded Dome Lid
        s.add(_makeArc(Offset(c.dx, cupY - m * 0.18), m * 0.18, -pi, pi, size: 4.5));
        // Diagonal Striped Straw
        s.add(_makeStroke([Offset(c.dx + m * 0.06, cupY - m * 0.36), Offset(c.dx - m * 0.04, cupY + m * 0.22)], size: 6.5));
        // Kawaii Smiling Face on Cup
        s.add(_makeCircle(Offset(c.dx - m * 0.07, cupY), m * 0.025, size: 4.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.07, cupY), m * 0.025, size: 4.0));
        s.add(_makeArc(Offset(c.dx, cupY + m * 0.04), m * 0.03, 0.2, pi - 0.4, size: 3.5));
        // Heart-Shaped Ice Cubes floating
        s.add(_makePetal(Offset(c.dx - m * 0.08, cupY - m * 0.08), 0, m * 0.04, -pi * 0.25, 0.5, size: 3.0));
        s.add(_makePetal(Offset(c.dx + m * 0.08, cupY - m * 0.08), 0, m * 0.04, -pi * 0.75, 0.5, size: 3.0));
        // Plentiful Tapioca Pearls
        for (int p = 0; p < 7; p++) {
          final px = c.dx - m * 0.09 + (p % 4) * m * 0.06;
          final py = cupY + m * 0.16 + (p ~/ 4) * m * 0.06;
          s.add(_makeCircle(Offset(px, py), m * 0.026, size: 3.5));
        }
        // Floating sparkles
        s.add(_makeStar(Offset(c.dx - m * 0.26, c.dy - m * 0.15), m * 0.06, m * 0.025, 4, size: 3.5));
        s.add(_makeStar(Offset(c.dx + m * 0.26, c.dy - m * 0.10), m * 0.06, m * 0.025, 4, size: 3.5));
        break;

      case 4: // 🦊 Low-Poly Geometric Origami Fox
        final oC = Offset(c.dx, c.dy - m * 0.04);
        // Face Center Triangle
        s.add(_makePolygon(Offset(oC.dx, oC.dy - m * 0.04), m * 0.08, 3, startAngle: pi / 2, size: 4.5));
        // Left & Right Muzzle Facets
        s.add(_makeStroke([
          Offset(oC.dx, oC.dy + m * 0.08),
          Offset(oC.dx - m * 0.12, oC.dy - m * 0.04),
          Offset(oC.dx, oC.dy - m * 0.04),
          Offset(oC.dx, oC.dy + m * 0.08),
        ], size: 4.0));
        s.add(_makeStroke([
          Offset(oC.dx, oC.dy + m * 0.08),
          Offset(oC.dx + m * 0.12, oC.dy - m * 0.04),
          Offset(oC.dx, oC.dy - m * 0.04),
          Offset(oC.dx, oC.dy + m * 0.08),
        ], size: 4.0));
        // Origami Ears
        s.add(_makeStroke([
          Offset(oC.dx - m * 0.06, oC.dy - m * 0.10),
          Offset(oC.dx - m * 0.18, oC.dy - m * 0.28),
          Offset(oC.dx - m * 0.16, oC.dy - m * 0.04),
          Offset(oC.dx - m * 0.06, oC.dy - m * 0.10),
        ], size: 4.5));
        s.add(_makeStroke([
          Offset(oC.dx + m * 0.06, oC.dy - m * 0.10),
          Offset(oC.dx + m * 0.18, oC.dy - m * 0.28),
          Offset(oC.dx + m * 0.16, oC.dy - m * 0.04),
          Offset(oC.dx + m * 0.06, oC.dy - m * 0.10),
        ], size: 4.5));
        // Body Faceted Triangles
        s.add(_makeStroke([
          Offset(oC.dx, oC.dy + m * 0.08),
          Offset(oC.dx - m * 0.16, c.dy + m * 0.34),
          Offset(oC.dx + m * 0.16, c.dy + m * 0.34),
          Offset(oC.dx, oC.dy + m * 0.08),
        ], size: 4.5));
        // Huge Bushy Origami Tail Fan
        s.add(_makeStroke([
          Offset(oC.dx + m * 0.14, c.dy + m * 0.32),
          Offset(oC.dx + m * 0.32, c.dy + m * 0.10),
          Offset(oC.dx + m * 0.24, c.dy - m * 0.04),
          Offset(oC.dx + m * 0.08, c.dy + m * 0.18),
        ], size: 4.5));
        s.add(_makeStroke([Offset(oC.dx + m * 0.24, c.dy - m * 0.04), Offset(oC.dx + m * 0.32, c.dy + m * 0.10)], size: 3.5));
        break;

      case 5: // 📼 Retro Cassette Tape & Headphone Vibes
        final casY = c.dy + m * 0.04;
        // Cassette Body
        s.add(_makeRect(Rect.fromCenter(center: Offset(c.dx, casY), width: m * 0.60, height: m * 0.36), size: 5.0));
        // Inner Label Window
        s.add(_makeRect(Rect.fromCenter(center: Offset(c.dx, casY), width: m * 0.44, height: m * 0.22), size: 3.5));
        // Dual Tape Spools
        s.add(_makeCircle(Offset(c.dx - m * 0.12, casY), m * 0.06, size: 4.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.12, casY), m * 0.06, size: 4.0));
        // Spool Teeth / Hub Spokes
        for (int i = 0; i < 4; i++) {
          final ang = (pi / 2) * i;
          s.add(_makeStroke([
            Offset(c.dx - m * 0.12 + m * 0.03 * cos(ang), casY + m * 0.03 * sin(ang)),
            Offset(c.dx - m * 0.12 + m * 0.06 * cos(ang), casY + m * 0.06 * sin(ang)),
          ], size: 3.0));
          s.add(_makeStroke([
            Offset(c.dx + m * 0.12 + m * 0.03 * cos(ang), casY + m * 0.03 * sin(ang)),
            Offset(c.dx + m * 0.12 + m * 0.06 * cos(ang), casY + m * 0.06 * sin(ang)),
          ], size: 3.0));
        }
        // Headphone Arch over cassette
        s.add(_makeArc(Offset(c.dx, casY - m * 0.10), m * 0.28, -pi * 0.9, pi * 0.8, size: 6.0));
        // Headphone Ear Cushions
        s.add(_makeRect(Rect.fromCenter(center: Offset(c.dx - m * 0.28, casY), width: m * 0.08, height: m * 0.18), size: 4.5));
        s.add(_makeRect(Rect.fromCenter(center: Offset(c.dx + m * 0.28, casY), width: m * 0.08, height: m * 0.18), size: 4.5));
        // Floating Music Notes
        s.add(_makeCircle(Offset(c.dx - m * 0.22, c.dy - m * 0.26), m * 0.03, size: 4.0));
        s.add(_makeStroke([Offset(c.dx - m * 0.19, c.dy - m * 0.26), Offset(c.dx - m * 0.19, c.dy - m * 0.36)], size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.22, c.dy - m * 0.26), m * 0.03, size: 4.0));
        s.add(_makeStroke([Offset(c.dx + m * 0.25, c.dy - m * 0.26), Offset(c.dx + m * 0.25, c.dy - m * 0.36)], size: 3.5));
        break;

      case 6: // 👑 Street Graffiti Winged Crown
        final crwY = c.dy - m * 0.05;
        // 5-Point Graffiti Crown
        s.add(_makeStroke([
          Offset(c.dx - m * 0.22, crwY + m * 0.10),
          Offset(c.dx - m * 0.25, crwY - m * 0.12),
          Offset(c.dx - m * 0.12, crwY - m * 0.02),
          Offset(c.dx, crwY - m * 0.18),
          Offset(c.dx + m * 0.12, crwY - m * 0.02),
          Offset(c.dx + m * 0.25, crwY - m * 0.12),
          Offset(c.dx + m * 0.22, crwY + m * 0.10),
          Offset(c.dx - m * 0.22, crwY + m * 0.10),
        ], size: 5.5));
        // Crown Base Jewels & Paint Drips
        for (int j = -2; j <= 2; j++) {
          s.add(_makeCircle(Offset(c.dx + j * m * 0.08, crwY + m * 0.05), m * 0.025, size: 3.5));
          s.add(_makeStroke([Offset(c.dx + j * m * 0.08, crwY + m * 0.10), Offset(c.dx + j * m * 0.08, crwY + m * 0.18 + (j.abs() % 2) * m * 0.06)], size: 4.0));
          s.add(_makeCircle(Offset(c.dx + j * m * 0.08, crwY + m * 0.20 + (j.abs() % 2) * m * 0.06), m * 0.015, size: 3.0));
        }
        // Spreading Angel Wings Left & Right
        for (int w = 0; w < 4; w++) {
          s.add(_makePetal(Offset(c.dx - m * 0.20, crwY + m * 0.02), 0, m * (0.16 + w * 0.05), pi * 0.8 + w * 0.15, 0.35, size: 4.5));
          s.add(_makePetal(Offset(c.dx + m * 0.20, crwY + m * 0.02), 0, m * (0.16 + w * 0.05), pi * 0.2 - w * 0.15, 0.35, size: 4.5));
        }
        break;

      case 7: // 🕸️ Cosmic Sacred Dreamcatcher
        final dcY = c.dy - m * 0.08;
        // Outer Sacred Ring
        s.add(_makeCircle(Offset(c.dx, dcY), m * 0.24, size: 5.5));
        s.add(_makeCircle(Offset(c.dx, dcY), m * 0.22, size: 2.5));
        // Woven Web 8-Point Star Mandala
        for (int i = 0; i < 8; i++) {
          final theta = (2 * pi / 8) * i;
          final nextTheta = (2 * pi / 8) * (i + 1);
          final p1 = Offset(c.dx + m * 0.22 * cos(theta), dcY + m * 0.22 * sin(theta));
          final p2 = Offset(c.dx + m * 0.22 * cos(nextTheta), dcY + m * 0.22 * sin(nextTheta));
          final pMid = Offset(c.dx + m * 0.12 * cos(theta + pi / 8), dcY + m * 0.12 * sin(theta + pi / 8));
          s.add(_makeStroke([p1, pMid, p2], size: 3.5));
        }
        // Center Turquoise Stone Bead
        s.add(_makeCircle(Offset(c.dx, dcY), m * 0.035, size: 4.0));
        // 3 Hanging Beaded Feathers
        for (final offset in [-m * 0.14, 0.0, m * 0.14]) {
          final fTop = Offset(c.dx + offset, dcY + m * 0.24);
          final fBot = Offset(c.dx + offset, c.dy + m * 0.34);
          s.add(_makeStroke([fTop, fBot], size: 3.0));
          s.add(_makeCircle(Offset(c.dx + offset, dcY + m * 0.28), m * 0.018, size: 3.0));
          s.add(_makePetal(Offset(c.dx + offset, c.dy + m * 0.26), 0, m * 0.14, pi / 2, 0.35, size: 4.0));
        }
        break;

      case 8: // 💥 Pop Art Comic Boom Explosion
        s.add(_makeStar(c, m * 0.38, m * 0.20, 12, size: 5.5));
        s.add(_makeStar(c, m * 0.28, m * 0.14, 12, startAngle: pi / 12, size: 3.5));
        final textY = c.dy - m * 0.02;
        // Letter B
        s.add(_makeStroke([Offset(c.dx - m * 0.26, textY - m * 0.12), Offset(c.dx - m * 0.26, textY + m * 0.12)], size: 5.5));
        s.add(_makeArc(Offset(c.dx - m * 0.26, textY - m * 0.06), m * 0.06, -pi / 2, pi, size: 4.5));
        s.add(_makeArc(Offset(c.dx - m * 0.26, textY + m * 0.06), m * 0.06, -pi / 2, pi, size: 4.5));
        // Letter O (Left)
        s.add(_makeCircle(Offset(c.dx - m * 0.10, textY), m * 0.07, size: 5.0));
        s.add(_makeCircle(Offset(c.dx - m * 0.10, textY), m * 0.035, size: 3.5));
        // Letter O (Right)
        s.add(_makeCircle(Offset(c.dx + m * 0.08, textY), m * 0.07, size: 5.0));
        s.add(_makeCircle(Offset(c.dx + m * 0.08, textY), m * 0.035, size: 3.5));
        // Letter M
        s.add(_makeStroke([
          Offset(c.dx + m * 0.18, textY + m * 0.12),
          Offset(c.dx + m * 0.18, textY - m * 0.12),
          Offset(c.dx + m * 0.24, textY + m * 0.02),
          Offset(c.dx + m * 0.30, textY - m * 0.12),
          Offset(c.dx + m * 0.30, textY + m * 0.12),
        ], size: 5.0));
        // Comic Halftone Dots & Action Speed Lines
        for (int a = 0; a < 6; a++) {
          final ang = (2 * pi / 6) * a;
          s.add(_makeStroke([
            Offset(c.dx + m * 0.39 * cos(ang), c.dy + m * 0.39 * sin(ang)),
            Offset(c.dx + m * 0.44 * cos(ang), c.dy + m * 0.44 * sin(ang)),
          ], size: 4.0));
        }
        break;

      case 9: // 💀 Cybernetic Circuit Skull
      default:
        final skY = c.dy - m * 0.04;
        s.add(_makeCircle(Offset(c.dx, skY), m * 0.20, size: 5.5));
        // Cheekbones & Jaw
        s.add(_makeStroke([
          Offset(c.dx - m * 0.18, skY + m * 0.06),
          Offset(c.dx - m * 0.12, c.dy + m * 0.28),
          Offset(c.dx + m * 0.12, c.dy + m * 0.28),
          Offset(c.dx + m * 0.18, skY + m * 0.06),
        ], size: 5.0));
        // Circular Cyber Eye Sockets
        s.add(_makeCircle(Offset(c.dx - m * 0.08, skY + m * 0.02), m * 0.045, size: 4.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.08, skY + m * 0.02), m * 0.045, size: 4.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.08, skY + m * 0.02), m * 0.02, size: 3.0));
        // Inverted Triangle Nose
        s.add(_makePolygon(Offset(c.dx, skY + m * 0.09), m * 0.028, 3, startAngle: pi, size: 3.5));
        // Teeth rungs
        for (int t = -2; t <= 2; t++) {
          s.add(_makeStroke([Offset(c.dx + t * m * 0.04, c.dy + m * 0.20), Offset(c.dx + t * m * 0.04, c.dy + m * 0.27)], size: 3.5));
        }
        // Circuit Traces on Forehead & Temples
        s.add(_makeStroke([Offset(c.dx - m * 0.14, skY - m * 0.14), Offset(c.dx - m * 0.06, skY - m * 0.14), Offset(c.dx, skY - m * 0.08)], size: 3.5));
        s.add(_makeCircle(Offset(c.dx - m * 0.14, skY - m * 0.14), m * 0.015, size: 3.0));
        s.add(_makeStroke([Offset(c.dx + m * 0.14, skY - m * 0.14), Offset(c.dx + m * 0.06, skY - m * 0.14), Offset(c.dx, skY - m * 0.08)], size: 3.5));
        s.add(_makeCircle(Offset(c.dx + m * 0.14, skY - m * 0.14), m * 0.015, size: 3.0));
        // Hexagonal Halo surrounding Skull
        s.add(_makePolygon(Offset(c.dx, skY), m * 0.34, 6, size: 4.0));
        break;
    }
  }
}

