import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/features/brushes/default_brushes.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/features/canvas/models/tools.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';

void main() {
  group('Text Tool Edit and Swift/Move Tests', () {
    test('selectedTextStrokeIdProvider defaults to null and resets on tool change', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedTextStrokeIdProvider), isNull);

      container.read(selectedTextStrokeIdProvider.notifier).state = 'stroke-123';
      expect(container.read(selectedTextStrokeIdProvider), 'stroke-123');

      // Changing active tool should reset selectedTextStrokeIdProvider
      container.read(activeToolProvider.notifier).state = DrawingTool.pencil;
      expect(container.read(selectedTextStrokeIdProvider), isNull);
    });

    test('CanvasDocumentNotifier.updateStroke updates text stroke in place', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialDoc = container.read(canvasDocumentProvider);
      expect(initialDoc.layers.isNotEmpty, isTrue);

      final textStroke = Stroke(
        id: 'text-test-1',
        points: const [
          StrokePoint(x: 100, y: 200, pressure: 1.0, timestamp: 1000),
        ],
        brush: DefaultBrushes.pencil,
        color: const Color(0xFF000000),
        shapeType: ShapeType.text,
        text: 'Initial Text',
        fontSize: 32,
      );

      container.read(canvasDocumentProvider.notifier).addStroke(textStroke);
      final activeLayer = container.read(canvasDocumentProvider).activeLayer!;
      expect(activeLayer.strokes.length, 1);
      expect(activeLayer.strokes.first.text, 'Initial Text');

      // Update text content and font size without adding duplicate stroke
      final updatedStroke = textStroke.copyWith(
        text: 'Edited Text Pro',
        fontSize: 48,
      );
      container.read(canvasDocumentProvider.notifier).updateStroke(updatedStroke);

      final updatedLayer = container.read(canvasDocumentProvider).activeLayer!;
      expect(updatedLayer.strokes.length, 1); // No duplicate!
      expect(updatedLayer.strokes.first.text, 'Edited Text Pro');
      expect(updatedLayer.strokes.first.fontSize, 48);
    });

    test('Text Swift/Move shifts stroke points correctly in place', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final textStroke = Stroke(
        id: 'text-move-1',
        points: const [
          StrokePoint(x: 150, y: 250, pressure: 1.0, timestamp: 1000),
        ],
        brush: DefaultBrushes.pencil,
        color: const Color(0xFF6C5CE7),
        shapeType: ShapeType.text,
        text: 'Movable Text',
        fontSize: 30,
      );

      container.read(canvasDocumentProvider.notifier).addStroke(textStroke);

      // Simulate dragging delta: dx = +50, dy = -30
      const dx = 50.0;
      const dy = -30.0;
      final movedStroke = textStroke.copyWith(
        points: textStroke.points.map((p) => StrokePoint(
          x: p.x + dx,
          y: p.y + dy,
          pressure: p.pressure,
          timestamp: p.timestamp,
        )).toList(),
      );

      container.read(canvasDocumentProvider.notifier).updateStroke(movedStroke);

      final activeLayer = container.read(canvasDocumentProvider).activeLayer!;
      expect(activeLayer.strokes.length, 1);
      expect(activeLayer.strokes.first.points.first.x, 200);
      expect(activeLayer.strokes.first.points.first.y, 220);
    });

    test('Text hit test bounding box is oriented downward from origin', () {
      const startX = 100.0;
      const startY = 150.0;
      const fontSize = 32.0;
      const textLength = 11;
      const estimatedWidth = textLength * fontSize * 0.65;
      const estimatedHeight = fontSize * 1.4;

      // Downward bounding box with padding
      const hitRect = Rect.fromLTWH(
        startX - 16,
        startY - 12,
        estimatedWidth + 32,
        estimatedHeight + 24,
      );

      // Points inside the text body
      expect(hitRect.contains(const Offset(105, 160)), isTrue);
      expect(hitRect.contains(const Offset(180, 170)), isTrue);

      // Points above startY - 12 should NOT be in the text body
      expect(hitRect.contains(const Offset(105, 120)), isFalse);

      // Points far away should not hit
      expect(hitRect.contains(const Offset(500, 500)), isFalse);
    });
  });
}
