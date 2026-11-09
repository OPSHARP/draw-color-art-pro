import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:draw_color_art_pro/features/canvas/models/symmetry.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/features/canvas/models/paper_texture.dart';
import 'package:draw_color_art_pro/features/brushes/default_brushes.dart';

void main() {
  group('SymmetryConfig Tests', () {
    final testStroke = Stroke(
      points: const [
        StrokePoint(x: 100, y: 150, pressure: 1.0),
        StrokePoint(x: 120, y: 180, pressure: 0.8),
      ],
      color: const Color(0xFF000000),
      brush: DefaultBrushes.pencil,
    );

    test('off mode returns only original stroke and points', () {
      const config = SymmetryConfig(mode: SymmetryMode.off);
      expect(config.isEnabled, isFalse);

      final pts = config.getSymmetricPoints(testStroke.points.first, 500, 500);
      expect(pts.length, equals(1));
      expect(pts.first, equals(testStroke.points.first));

      final strokes = config.generateSymmetricStrokes(testStroke, 1000, 1000);
      expect(strokes.length, equals(1));
    });

    test('vertical mirror reflects points across centerX', () {
      const config = SymmetryConfig(mode: SymmetryMode.vertical);
      expect(config.isEnabled, isTrue);

      const centerX = 500.0;
      const centerY = 500.0;
      final original = testStroke.points.first; // x: 100, y: 150
      final pts = config.getSymmetricPoints(original, centerX, centerY);

      expect(pts.length, equals(2));
      expect(pts[0].x, equals(100));
      expect(pts[0].y, equals(150));
      // Mirrored x = 500 - (100 - 500) = 500 - (-400) = 900
      expect(pts[1].x, equals(900));
      expect(pts[1].y, equals(150));

      final strokes = config.generateSymmetricStrokes(testStroke, 1000, 1000);
      expect(strokes.length, equals(2));
      // Second stroke should have unique ID
      expect(strokes[0].id, isNot(equals(strokes[1].id)));
    });

    test('horizontal mirror reflects points across centerY', () {
      const config = SymmetryConfig(mode: SymmetryMode.horizontal);
      const centerX = 500.0;
      const centerY = 500.0;
      final original = testStroke.points.first; // x: 100, y: 150
      final pts = config.getSymmetricPoints(original, centerX, centerY);

      expect(pts.length, equals(2));
      expect(pts[1].x, equals(100));
      expect(pts[1].y, equals(850)); // 500 - (150 - 500) = 850
    });

    test('dual 4-way cross produces 4 symmetrical points and strokes', () {
      const config = SymmetryConfig(mode: SymmetryMode.dual);
      const centerX = 500.0;
      const centerY = 500.0;
      final pts = config.getSymmetricPoints(testStroke.points.first, centerX, centerY);

      expect(pts.length, equals(4));

      final strokes = config.generateSymmetricStrokes(testStroke, 1000, 1000);
      expect(strokes.length, equals(4));

      // All 4 strokes must have distinct IDs
      final ids = strokes.map((s) => s.id).toSet();
      expect(ids.length, equals(4));
    });

    test('radial mandala generates N segments with rotational symmetry', () {
      const config = SymmetryConfig(mode: SymmetryMode.radial, segments: 8);
      const centerX = 500.0;
      const centerY = 500.0;
      final pts = config.getSymmetricPoints(testStroke.points.first, centerX, centerY);

      expect(pts.length, equals(8));

      final strokes = config.generateSymmetricStrokes(testStroke, 1000, 1000);
      expect(strokes.length, equals(8));
      final ids = strokes.map((s) => s.id).toSet();
      expect(ids.length, equals(8));
    });

    test('CanvasPaperTexture has valid base tints and icons', () {
      expect(CanvasPaperTexture.none.baseTint, equals(const Color(0xFFFFFFFF)));
      expect(CanvasPaperTexture.watercolor.baseTint, isNotNull);
      expect(CanvasPaperTexture.parchment.baseTint, isNotNull);
      expect(CanvasPaperTexture.blueprint.baseTint, isNotNull);
      expect(CanvasPaperTexture.darkSketchbook.baseTint, isNotNull);
    });
  });
}
