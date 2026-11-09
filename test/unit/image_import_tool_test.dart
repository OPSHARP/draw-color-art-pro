import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/features/canvas/models/tools.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/features/canvas/models/canvas_document.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';
import 'package:draw_color_art_pro/features/canvas/services/image_cache_service.dart';
import 'package:draw_color_art_pro/features/brushes/default_brushes.dart';

void main() {
  group('Image Import & Placement Tool Tests', () {
    test('DrawingTool.image is defined with correct label', () {
      expect(DrawingTool.image.label, contains('Photo'));
      expect(DrawingTool.values, contains(DrawingTool.image));
    });

    test('ShapeType.image is defined and serializes/deserializes', () {
      expect(ShapeType.image.label, contains('Photo'));
      expect(ShapeType.values, contains(ShapeType.image));

      final stroke = Stroke(
        points: const [
          StrokePoint(x: 10, y: 20),
          StrokePoint(x: 110, y: 220),
        ],
        color: Colors.white,
        brush: DefaultBrushes.hardBrush,
        shapeType: ShapeType.image,
        imagePath: '/tmp/test_image.jpg',
        imageRotation: 1.57,
      );

      final json = stroke.toJson();
      expect(json['shapeType'], 'image');
      expect(json['imagePath'], '/tmp/test_image.jpg');
      expect(json['imageRotation'], 1.57);

      final deserialized = Stroke.fromJson(json);
      expect(deserialized.shapeType, ShapeType.image);
      expect(deserialized.imagePath, '/tmp/test_image.jpg');
      expect(deserialized.imageRotation, 1.57);
    });

    test('ImageCacheService stores and clears cached images', () {
      final cache = ImageCacheService.instance;
      expect(cache.getImageSync('non_existent_path.png'), isNull);
      expect(cache.contains('non_existent_path.png'), isFalse);
      cache.clear();
    });

    test('ImagePlacementController commits placed image to current layer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final docNotifier = container.read(canvasDocumentProvider.notifier);
      docNotifier.createNew(name: 'Test Canvas', width: 800, height: 800);

      // Create a dummy stroke point representing image
      final stroke = Stroke(
        points: const [
          StrokePoint(x: 50, y: 50),
          StrokePoint(x: 350, y: 350),
        ],
        color: Colors.white,
        brush: DefaultBrushes.hardBrush,
        shapeType: ShapeType.image,
        imagePath: 'test_path.png',
        imageRotation: 0.0,
      );

      docNotifier.addStroke(stroke);

      final doc = container.read(canvasDocumentProvider);
      expect(doc.activeLayer!.strokes.length, 1);
      expect(doc.activeLayer!.strokes.first.shapeType, ShapeType.image);
      expect(doc.activeLayer!.strokes.first.imagePath, 'test_path.png');
    });

    test('ImagePlacementController creates dedicated image layer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final docNotifier = container.read(canvasDocumentProvider.notifier);
      docNotifier.createNew(name: 'Test Canvas', width: 800, height: 800);

      final initialLayerCount = container.read(canvasDocumentProvider).layers.length;

      final imageLayer = LayerModel(
        name: 'Photo 2',
        type: LayerType.image,
        opacity: 0.85,
        strokes: [
          Stroke(
            points: const [
              StrokePoint(x: 100, y: 100),
              StrokePoint(x: 400, y: 400),
            ],
            color: Colors.white,
            brush: DefaultBrushes.hardBrush,
            shapeType: ShapeType.image,
            imagePath: 'photo_layer.png',
          ),
        ],
      );

      docNotifier.insertLayer(imageLayer);

      final updatedDoc = container.read(canvasDocumentProvider);
      expect(updatedDoc.layers.length, initialLayerCount + 1);
      expect(updatedDoc.activeLayer!.type, LayerType.image);
      expect(updatedDoc.activeLayer!.strokes.first.shapeType, ShapeType.image);
    });
  });
}
