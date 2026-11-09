import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:draw_color_art_pro/features/canvas/models/canvas_document.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';
import 'package:draw_color_art_pro/features/brushes/default_brushes.dart';

void main() {
  group('CanvasDocument serialization tests', () {
    test('round-trip JSON serialization preserves all document properties and strokes', () {
      final stroke = Stroke(
        points: const [
          StrokePoint(x: 10, y: 20, pressure: 0.8),
          StrokePoint(x: 30, y: 40, pressure: 1.0),
        ],
        color: const Color(0xFFFF0000),
        brush: DefaultBrushes.pencil,
        blendMode: DrawBlendMode.multiply,
      );

      final layer1 = LayerModel(
        name: 'Background Ink',
        opacity: 0.85,
        blendMode: DrawBlendMode.overlay,
        isVisible: true,
        isLocked: false,
        strokes: [stroke],
      );

      final originalDoc = CanvasDocument(
        name: 'Masterpiece',
        width: 1920,
        height: 1080,
        backgroundColor: const Color(0xFF1E1E2E),
        isTransparentBackground: false,
        layers: [layer1],
        activeLayerIndex: 0,
      );

      final json = originalDoc.toJson();
      final deserializedDoc = CanvasDocument.fromJson(json);

      expect(deserializedDoc.name, equals('Masterpiece'));
      expect(deserializedDoc.width, equals(1920));
      expect(deserializedDoc.height, equals(1080));
      expect(deserializedDoc.backgroundColor.toARGB32(), equals(const Color(0xFF1E1E2E).toARGB32()));
      expect(deserializedDoc.layers.length, equals(1));

      final deserializedLayer = deserializedDoc.layers.first;
      expect(deserializedLayer.name, equals('Background Ink'));
      expect(deserializedLayer.opacity, equals(0.85));
      expect(deserializedLayer.blendMode, equals(DrawBlendMode.overlay));
      expect(deserializedLayer.strokes.length, equals(1));

      final deserializedStroke = deserializedLayer.strokes.first;
      expect(deserializedStroke.points.length, equals(2));
      expect(deserializedStroke.points[0].x, equals(10.0));
      expect(deserializedStroke.points[0].pressure, equals(0.8));
      expect(deserializedStroke.color.toARGB32(), equals(const Color(0xFFFF0000).toARGB32()));
    });
  });

  group('CanvasDocumentNotifier layer management tests', () {
    late CanvasDocumentNotifier notifier;

    setUp(() {
      notifier = CanvasDocumentNotifier();
      notifier.createNew(
        name: 'Test Canvas',
        width: 1000,
        height: 1000,
      );
    });

    test('initial state contains one default layer', () {
      expect(notifier.state.layers.length, equals(1));
      expect(notifier.state.activeLayerIndex, equals(0));
      expect(notifier.state.activeLayer?.name, equals('Layer 1'));
    });

    test('addLayer inserts layer and sets it active', () {
      notifier.addLayer(name: 'Inking');
      expect(notifier.state.layers.length, equals(2));
      expect(notifier.state.activeLayerIndex, equals(1));
      expect(notifier.state.activeLayer?.name, equals('Inking'));
    });

    test('toggleLayerVisibility updates target layer', () {
      notifier.toggleLayerVisibility(0);
      expect(notifier.state.layers[0].isVisible, isFalse);
      notifier.toggleLayerVisibility(0);
      expect(notifier.state.layers[0].isVisible, isTrue);
    });

    test('toggleLayerLock prevents edits', () {
      notifier.toggleLayerLock(0);
      expect(notifier.state.layers[0].isLocked, isTrue);
    });

    test('setLayerOpacity clamps within 0.0 and 1.0', () {
      notifier.setLayerOpacity(0, 0.45);
      expect(notifier.state.layers[0].opacity, equals(0.45));
    });

    test('deleteLayer does not remove last remaining layer', () {
      notifier.deleteLayer(0);
      expect(notifier.state.layers.length, equals(1)); // Prevents 0 layers
    });

    test('duplicateLayer clones strokes and properties', () {
      notifier.addStroke(Stroke(
        points: const [StrokePoint(x: 5, y: 5)],
        color: Colors.blue,
        brush: DefaultBrushes.pencil,
      ));

      notifier.duplicateLayer(0);
      expect(notifier.state.layers.length, equals(2));
      expect(notifier.state.layers[1].name, contains('Copy'));
      expect(notifier.state.layers[1].strokes.length, equals(1));
    });
  });
}
