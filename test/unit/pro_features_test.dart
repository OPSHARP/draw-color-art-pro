import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:draw_color_art_pro/features/colors/models/color_harmonies.dart';
import 'package:draw_color_art_pro/features/colors/services/palette_extractor_service.dart';
import 'package:draw_color_art_pro/features/canvas/models/canvas_document.dart';
import 'package:draw_color_art_pro/features/canvas/models/drawing_guides.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';

void main() {
  group('ColorHarmonies Tests', () {
    test('Complementary harmony calculates opposing hue correctly', () {
      const red = Color(0xFFFF0000); // Hue 0
      final colors = ColorHarmonies.compute(red, HarmonyType.complementary);

      expect(colors.length, 2);
      expect(colors.first, red);

      final secondHsv = HSVColor.fromColor(colors[1]);
      expect((secondHsv.hue - 180.0).abs() < 1.0, isTrue); // Cyan
    });

    test('Triadic harmony produces 3 equidistant colors', () {
      const red = Color(0xFFFF0000);
      final colors = ColorHarmonies.compute(red, HarmonyType.triadic);

      expect(colors.length, 3);
      final hsv0 = HSVColor.fromColor(colors[0]);
      final hsv1 = HSVColor.fromColor(colors[1]);
      final hsv2 = HSVColor.fromColor(colors[2]);

      expect((hsv0.hue - 0.0).abs() < 1.0, isTrue);
      expect((hsv1.hue - 120.0).abs() < 1.0, isTrue);
      expect((hsv2.hue - 240.0).abs() < 1.0, isTrue);
    });

    test('Analogous harmony produces 3 adjacent colors', () {
      const green = Color(0xFF00FF00); // Hue 120
      final colors = ColorHarmonies.compute(green, HarmonyType.analogous);

      expect(colors.length, 3);
      final hsv0 = HSVColor.fromColor(colors[0]);
      final hsv1 = HSVColor.fromColor(colors[1]);
      final hsv2 = HSVColor.fromColor(colors[2]);

      expect((hsv0.hue - 90.0).abs() < 1.0, isTrue);
      expect((hsv1.hue - 120.0).abs() < 1.0, isTrue);
      expect((hsv2.hue - 150.0).abs() < 1.0, isTrue);
    });

    test('Monochromatic harmony generates 5 tone variations', () {
      const blue = Color(0xFF0000FF);
      final colors = ColorHarmonies.compute(blue, HarmonyType.monochromatic);

      expect(colors.length, 5);
      // All colors should share approximately the same hue
      for (final c in colors) {
        final hsv = HSVColor.fromColor(c);
        expect((hsv.hue - 240.0).abs() < 1.0, isTrue);
      }
    });

    test('Tetradic harmony produces 4 balanced colors', () {
      const base = Color(0xFFFF0000);
      final colors = ColorHarmonies.compute(base, HarmonyType.tetradic);
      expect(colors.length, 4);
    });
  });

  group('PaletteExtractorService Tests', () {
    test('Extracts harmonious swatches from image bytes', () async {
      // Create a synthetic test image with colorful stripes
      final image = img.Image(width: 32, height: 32);
      for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 32; x++) {
          image.setPixelRgba(x, y, 255, 60, 60, 255); // Red
        }
      }
      for (int y = 16; y < 32; y++) {
        for (int x = 0; x < 32; x++) {
          image.setPixelRgba(x, y, 60, 60, 255, 255); // Blue
        }
      }
      final bytes = img.encodePng(image);

      final palette = await PaletteExtractorService.instance.extractFromBytes(bytes);
      expect(palette.isNotEmpty, isTrue);
      expect(palette.length >= 4, isTrue);
    });
  });

  group('Layer Alpha Lock & Clipping Mask Tests', () {
    test('LayerModel defaults have isAlphaLocked and isClipping false', () {
      final layer = LayerModel(name: 'Test Layer');
      expect(layer.isAlphaLocked, isFalse);
      expect(layer.isClipping, isFalse);
    });

    test('LayerModel copyWith updates isAlphaLocked and isClipping', () {
      final layer = LayerModel(name: 'Layer 1');
      final updated = layer.copyWith(isAlphaLocked: true, isClipping: true);

      expect(updated.isAlphaLocked, isTrue);
      expect(updated.isClipping, isTrue);
      expect(updated.name, 'Layer 1');
    });

    test('LayerModel JSON serialization preserves alpha lock and clipping', () {
      final layer = LayerModel(
        name: 'Shading',
        isAlphaLocked: true,
        isClipping: true,
      );

      final json = layer.toJson();
      final restored = LayerModel.fromJson(json);

      expect(restored.isAlphaLocked, isTrue);
      expect(restored.isClipping, isTrue);
      expect(restored.name, 'Shading');
    });

    test('CanvasDocumentNotifier toggles alpha lock on layer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(canvasDocumentProvider.notifier);
      expect(container.read(canvasDocumentProvider).layers.first.isAlphaLocked, isFalse);

      notifier.toggleLayerAlphaLock(0);
      expect(container.read(canvasDocumentProvider).layers.first.isAlphaLocked, isTrue);

      notifier.toggleLayerAlphaLock(0);
      expect(container.read(canvasDocumentProvider).layers.first.isAlphaLocked, isFalse);
    });

    test('CanvasDocumentNotifier toggles clipping mask on upper layers but guards index 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(canvasDocumentProvider.notifier);
      // Add a second layer
      notifier.addLayer(name: 'Shadow');

      // Base layer 0 cannot be clipped
      notifier.toggleLayerClipping(0);
      expect(container.read(canvasDocumentProvider).layers[0].isClipping, isFalse);

      // Layer 1 can be clipped
      notifier.toggleLayerClipping(1);
      expect(container.read(canvasDocumentProvider).layers[1].isClipping, isTrue);

      notifier.toggleLayerClipping(1);
      expect(container.read(canvasDocumentProvider).layers[1].isClipping, isFalse);
    });
  });

  group('DrawingGuideConfig Tests', () {
    test('Default drawing guide is none and disabled', () {
      const guide = DrawingGuideConfig();
      expect(guide.type, DrawingGuideType.none);
      expect(guide.isEnabled, isFalse);
    });

    test('Setting guide type enables isEnabled', () {
      const guide = DrawingGuideConfig(type: DrawingGuideType.isometric);
      expect(guide.isEnabled, isTrue);
      expect(guide.spacing, 32.0);

      final copy = guide.copyWith(type: DrawingGuideType.perspective1P, opacity: 0.5);
      expect(copy.type, DrawingGuideType.perspective1P);
      expect(copy.opacity, 0.5);
    });
  });
}
