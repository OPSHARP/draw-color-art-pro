import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/features/canvas/models/canvas_document.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/canvas_background_modal.dart';

void main() {
  group('Canvas Background Selection Tests', () {
    test('CanvasDocument default background is white and non-transparent', () {
      final doc = CanvasDocument(name: 'Test', width: 1000, height: 1000);
      expect(doc.backgroundColor, equals(const Color(0xFFFFFFFF)));
      expect(doc.isTransparentBackground, isFalse);
    });

    test('CanvasDocument custom background color and transparency initialize properly', () {
      final parchmentDoc = CanvasDocument(
        name: 'Parchment',
        width: 1000,
        height: 1000,
        backgroundColor: const Color(0xFFF5E6CA),
        isTransparentBackground: false,
      );
      expect(parchmentDoc.backgroundColor, equals(const Color(0xFFF5E6CA)));
      expect(parchmentDoc.isTransparentBackground, isFalse);

      final transparentDoc = CanvasDocument(
        name: 'Sticker PNG',
        width: 500,
        height: 500,
        backgroundColor: Colors.transparent,
        isTransparentBackground: true,
      );
      expect(transparentDoc.isTransparentBackground, isTrue);
    });

    test('CanvasDocument copyWith updates background color and transparency', () {
      final doc = CanvasDocument(name: 'Test', width: 800, height: 600);
      final updated = doc.copyWith(
        backgroundColor: const Color(0xFF1E1E2E),
        isTransparentBackground: false,
      );
      expect(updated.backgroundColor, equals(const Color(0xFF1E1E2E)));
      expect(updated.isTransparentBackground, isFalse);

      final transCopy = updated.copyWith(isTransparentBackground: true);
      expect(transCopy.isTransparentBackground, isTrue);
    });

    test('CanvasDocument JSON serialization and deserialization preserves background', () {
      final doc = CanvasDocument(
        name: 'JsonTest',
        width: 1080,
        height: 1920,
        backgroundColor: const Color(0xFF1E3A8A), // Blueprint
        isTransparentBackground: false,
      );
      final json = doc.toJson();
      final restored = CanvasDocument.fromJson(json);

      expect(restored.backgroundColor, equals(const Color(0xFF1E3A8A)));
      expect(restored.isTransparentBackground, isFalse);
    });

    test('CanvasDocumentNotifier createNew with custom background color and transparency', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(canvasDocumentProvider.notifier);
      notifier.createNew(
        name: 'Custom Chalkboard',
        width: 1200,
        height: 1200,
        backgroundColor: const Color(0xFF1E1E2E),
        transparent: false,
      );

      final doc = container.read(canvasDocumentProvider);
      expect(doc.name, equals('Custom Chalkboard'));
      expect(doc.backgroundColor, equals(const Color(0xFF1E1E2E)));
      expect(doc.isTransparentBackground, isFalse);
    });

    test('CanvasDocumentNotifier setBackgroundColor changes background dynamically', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(canvasDocumentProvider.notifier);
      notifier.createNew(name: 'Test Session', width: 800, height: 800);

      // Change to Pastel Sky
      notifier.setBackgroundColor(const Color(0xFFE0F2FE));
      expect(container.read(canvasDocumentProvider).backgroundColor, equals(const Color(0xFFE0F2FE)));
      expect(container.read(canvasDocumentProvider).isTransparentBackground, isFalse);

      // Change to Transparent Checkerboard
      notifier.setBackgroundColor(Colors.transparent, transparent: true);
      expect(container.read(canvasDocumentProvider).isTransparentBackground, isTrue);
    });

    test('CanvasBackgroundPreset contains complete set of artistic paper presets and transparent', () {
      const presets = CanvasBackgroundPreset.allPresets;
      expect(presets.length, greaterThanOrEqualTo(12));

      final names = presets.map((p) => p.name).toSet();
      expect(names.contains('Pure White'), isTrue);
      expect(names.contains('Warm Cream'), isTrue);
      expect(names.contains('Vintage Parchment'), isTrue);
      expect(names.contains('Chalkboard Dark'), isTrue);
      expect(names.contains('Pitch Black'), isTrue);
      expect(names.contains('Blueprint Blue'), isTrue);
      expect(names.contains('Transparent'), isTrue);

      final transPreset = presets.firstWhere((p) => p.name == 'Transparent');
      expect(transPreset.isTransparent, isTrue);
    });
  });
}
