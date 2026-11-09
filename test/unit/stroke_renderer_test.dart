import 'package:flutter_test/flutter_test.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/rendering/engine/stroke_renderer.dart';

void main() {
  group('StrokeRenderer stabilization tests', () {
    test('off stabilization returns raw point', () {
      const p1 = StrokePoint(x: 10, y: 10);
      const p2 = StrokePoint(x: 20, y: 20);
      final stabilized = StrokeRenderer.stabilize(p2, [p1], StabilizationMode.off);
      expect(stabilized.x, equals(20.0));
      expect(stabilized.y, equals(20.0));
    });

    test('stabilization smooths between current and previous points', () {
      const p1 = StrokePoint(x: 0, y: 0);
      const p2 = StrokePoint(x: 100, y: 100);

      final basic = StrokeRenderer.stabilize(p2, [p1], StabilizationMode.basic);
      final strong = StrokeRenderer.stabilize(p2, [p1], StabilizationMode.strong);

      // Strong stabilization should weight previous point more heavily than basic
      expect(basic.x, greaterThan(0));
      expect(basic.x, lessThan(100));
      expect(strong.x, lessThan(basic.x));
    });

    test('empty history returns raw point without error', () {
      const p = StrokePoint(x: 50, y: 50);
      final result = StrokeRenderer.stabilize(p, [], StabilizationMode.strong);
      expect(result.x, equals(50.0));
      expect(result.y, equals(50.0));
    });
  });

  group('StrokeRenderer interpolation tests', () {
    test('fewer than 2 points returns original list', () {
      final pts = [const StrokePoint(x: 10, y: 10)];
      final interpolated = StrokeRenderer.interpolatePoints(pts);
      expect(interpolated.length, equals(1));
    });

    test('points spaced far apart are subdivided', () {
      final pts = [
        const StrokePoint(x: 0, y: 0),
        const StrokePoint(x: 100, y: 0),
      ];
      final interpolated = StrokeRenderer.interpolatePoints(pts, minDistance: 10.0);
      expect(interpolated.length, greaterThan(2));
      expect(interpolated.first.x, equals(0.0));
      expect(interpolated.last.x, equals(100.0));
    });

    test('points already close are preserved', () {
      final pts = [
        const StrokePoint(x: 0, y: 0),
        const StrokePoint(x: 1, y: 1),
      ];
      final interpolated = StrokeRenderer.interpolatePoints(pts, minDistance: 5.0);
      expect(interpolated.length, equals(2));
    });
  });
}
