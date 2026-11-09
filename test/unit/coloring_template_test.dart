import 'package:flutter_test/flutter_test.dart';
import 'package:draw_color_art_pro/features/templates/models/coloring_template.dart';
import 'package:draw_color_art_pro/features/canvas/models/canvas_document.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';

void main() {
  group('Coloring Templates Tests', () {
    test('all templates library is populated with free templates', () {
      expect(ColoringTemplates.all.isNotEmpty, isTrue);
      expect(ColoringTemplates.all.length, greaterThanOrEqualTo(4));
    });

    test('template creates document with locked line art and active color layer', () {
      final template = ColoringTemplates.sacredMandala;
      final doc = template.createDocument(width: 1024, height: 1024);

      expect(doc.name, equals('Sacred Mandala'));
      expect(doc.width, equals(1024));
      expect(doc.height, equals(1024));
      expect(doc.layers.length, equals(2));

      // Layer 0 is the Color Layer (unlocked for painting)
      final colorLayer = doc.layers[0];
      expect(colorLayer.name, equals('Color Layer'));
      expect(colorLayer.isLocked, isFalse);
      expect(colorLayer.type, equals(LayerType.paint));

      // Layer 1 is the Line Art Layer (locked, multiply blend mode, vector strokes)
      final lineArtLayer = doc.layers[1];
      expect(lineArtLayer.name, contains('Line Art'));
      expect(lineArtLayer.isLocked, isTrue);
      expect(lineArtLayer.blendMode, equals(DrawBlendMode.multiply));
      expect(lineArtLayer.strokes.isNotEmpty, isTrue);

      // Active layer index is 0 so user immediately colors under the outlines
      expect(doc.activeLayerIndex, equals(0));
    });

    test('cyber cat template generates valid vector contours', () {
      final template = ColoringTemplates.cyberCat;
      final doc = template.createDocument();
      final lineLayer = doc.layers[1];

      expect(lineLayer.strokes.length, greaterThan(5));
      for (final stroke in lineLayer.strokes) {
        expect(stroke.points.isNotEmpty, isTrue);
      }
    });

    test('butterfly dream template generates symmetric wings and antennae', () {
      final template = ColoringTemplates.butterflyDream;
      final doc = template.createDocument();
      final lineLayer = doc.layers[1];

      expect(lineLayer.strokes.length, greaterThan(5));
    });
  });
}
