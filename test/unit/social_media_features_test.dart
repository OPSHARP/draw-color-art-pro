import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:draw_color_art_pro/core/constants/design_tokens.dart';
import 'package:draw_color_art_pro/features/canvas/models/canvas_document.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';
import 'package:draw_color_art_pro/features/canvas/services/image_search_service.dart';
import 'package:draw_color_art_pro/features/brushes/default_brushes.dart';
import 'package:draw_color_art_pro/features/text/views/font_picker_dialog.dart';

void main() {
  group('Social Media Canvas Presets Tests', () {
    test('socialPresets contains YouTube 16:9 and TikTok/Reels 9:16', () {
      final presets = CanvasPreset.socialPresets;
      expect(presets, isNotEmpty);

      // YouTube Thumbnail (16:9)
      final yt = presets.firstWhere((p) => p.name == 'youtubeThumbnail');
      expect(yt.width, equals(1280));
      expect(yt.height, equals(720));
      expect(yt.aspectRatio, closeTo(16 / 9, 0.01));

      // TikTok / Reels (9:16)
      final tiktok = presets.firstWhere((p) => p.name == 'tiktokVideo');
      expect(tiktok.width, equals(1080));
      expect(tiktok.height, equals(1920));
      expect(tiktok.aspectRatio, closeTo(9 / 16, 0.01));

      // Instagram Post (1:1)
      final igPost = presets.firstWhere((p) => p.name == 'instagramPost');
      expect(igPost.width, equals(1080));
      expect(igPost.height, equals(1080));
      expect(igPost.aspectRatio, closeTo(1.0, 0.01));
    });

    test('artPresets contains standard creative formats', () {
      final presets = CanvasPreset.artPresets;
      expect(presets, isNotEmpty);
      expect(presets.any((p) => p.name == 'square'), isTrue);
      expect(presets.any((p) => p.name == 'portrait'), isTrue);
      expect(presets.any((p) => p.name == 'landscape'), isTrue);
    });
  });

  group('TypographyStyleConfig Tests', () {
    test('default configuration has expected typography properties', () {
      const config = TypographyStyleConfig();
      expect(config.fontSize, equals(32.0));
      expect(config.textAlign, equals(TextAlign.center));
      expect(config.textDecoration, equals(TextDecoration.none));
      expect(config.hasShadow, isFalse);
      expect(config.lineHeight, equals(1.3));
    });

    test('copyWith updates text styling fields correctly', () {
      const config = TypographyStyleConfig();
      final updated = config.copyWith(
        textAlign: TextAlign.right,
        textDecoration: TextDecoration.underline,
        hasShadow: true,
        shadowOffsetX: 4.0,
        shadowOffsetY: 4.0,
        shadowBlur: 8.0,
        lineHeight: 1.5,
      );

      expect(updated.textAlign, equals(TextAlign.right));
      expect(updated.textDecoration, equals(TextDecoration.underline));
      expect(updated.hasShadow, isTrue);
      expect(updated.shadowOffsetX, equals(4.0));
      expect(updated.shadowOffsetY, equals(4.0));
      expect(updated.shadowBlur, equals(8.0));
      expect(updated.lineHeight, equals(1.5));
    });
  });

  group('Layer Management Tests (flattenVisible, group, ungroup)', () {
    late CanvasDocumentNotifier notifier;

    setUp(() {
      final s1 = Stroke(
        points: const [StrokePoint(x: 10, y: 10)],
        color: Colors.red,
        brush: DefaultBrushes.pencil,
      );
      final s2 = Stroke(
        points: const [StrokePoint(x: 20, y: 20)],
        color: Colors.blue,
        brush: DefaultBrushes.pencil,
      );
      final s3 = Stroke(
        points: const [StrokePoint(x: 30, y: 30)],
        color: Colors.green,
        brush: DefaultBrushes.pencil,
      );

      final l1 = LayerModel(name: 'Visible 1', isVisible: true, strokes: [s1]);
      final l2 = LayerModel(name: 'Hidden Layer', isVisible: false, strokes: [s2]);
      final l3 = LayerModel(name: 'Visible 2', isVisible: true, strokes: [s3]);

      final doc = CanvasDocument(
        name: 'Layer Test',
        width: 1000,
        height: 1000,
        layers: [l1, l2, l3],
        activeLayerIndex: 0,
      );

      notifier = CanvasDocumentNotifier()..loadDocument(doc);
    });

    test('flattenVisible preserves hidden layer and merges only visible ones', () {
      notifier.flattenVisible();
      final state = notifier.state;

      // 1 merged visible layer + 1 preserved hidden layer = 2 layers
      expect(state.layers.length, equals(2));
      final merged = state.layers.firstWhere((l) => l.name == 'Merged');
      expect(merged.isVisible, isTrue);
      // Merged strokes from Visible 1 and Visible 2 = 2 strokes
      expect(merged.strokes.length, equals(2));

      final hidden = state.layers.firstWhere((l) => l.name == 'Hidden Layer');
      expect(hidden.isVisible, isFalse);
      expect(hidden.strokes.length, equals(1));
    });

    test('groupLayers assigns parentGroupId to selected layers', () {
      notifier.groupLayers([0, 2], 'Header Group');
      final layers = notifier.state.layers;

      expect(layers[0].parentGroupId, isNotNull);
      expect(layers[2].parentGroupId, isNotNull);
      expect(layers[0].parentGroupId, equals(layers[2].parentGroupId));
      expect(layers[1].parentGroupId, isNull);
    });

    test('ungroupLayers clears parentGroupId for specified group', () {
      notifier.groupLayers([0, 2], 'Header Group');
      final groupId = notifier.state.layers[0].parentGroupId!;

      notifier.ungroupLayers(groupId);
      final layers = notifier.state.layers;
      expect(layers[0].parentGroupId, isNull);
      expect(layers[2].parentGroupId, isNull);
    });
  });

  group('Free Stock Photo Search Model Tests', () {
    test('SearchImageResult parses JSON successfully', () {
      final samplePexelsJson = jsonDecode('''
      {
        "id": 123456,
        "width": 1920,
        "height": 1080,
        "photographer": "Jane Doe",
        "photographer_url": "https://www.pexels.com/@janedoe",
        "alt": "A beautiful sunset over the mountains",
        "src": {
          "medium": "https://images.pexels.com/photos/123456/medium.jpg",
          "large": "https://images.pexels.com/photos/123456/large.jpg",
          "original": "https://images.pexels.com/photos/123456/original.jpg"
        }
      }
      ''');

      final result = SearchImageResult.fromPexelsJson(samplePexelsJson);
      expect(result.id, equals('123456'));
      expect(result.photographer, equals('Jane Doe'));
      expect(result.description, equals('A beautiful sunset over the mountains'));
      expect(result.regularUrl, contains('medium.jpg'));
      expect(result.fullUrl, contains('original.jpg'));
      expect(result.width, equals(1920));
      expect(result.height, equals(1080));
      expect(result.aspectRatio, closeTo(1920 / 1080, 0.01));
    });
  });

  group('Shapes & Icons Library Tests', () {
    test('new shape types are defined on ShapeType enum', () {
      expect(ShapeType.values.contains(ShapeType.pentagon), isTrue);
      expect(ShapeType.values.contains(ShapeType.octagon), isTrue);
      expect(ShapeType.values.contains(ShapeType.ring), isTrue);
      expect(ShapeType.values.contains(ShapeType.cross), isTrue);
      expect(ShapeType.values.contains(ShapeType.crescent), isTrue);
      expect(ShapeType.values.contains(ShapeType.chevron), isTrue);
      expect(ShapeType.values.contains(ShapeType.playButton), isTrue);
      expect(ShapeType.values.contains(ShapeType.musicNote), isTrue);
      expect(ShapeType.values.contains(ShapeType.crown), isTrue);
      expect(ShapeType.values.contains(ShapeType.banner), isTrue);
      expect(ShapeType.values.contains(ShapeType.starburst), isTrue);
      expect(ShapeType.values.contains(ShapeType.shield), isTrue);
    });

    test('Stroke bounds calculates correctly for geometric shapes', () {
      final stroke = Stroke(
        points: const [
          StrokePoint(x: 100, y: 100),
          StrokePoint(x: 300, y: 300),
        ],
        color: Colors.blue,
        brush: DefaultBrushes.pencil,
        shapeType: ShapeType.pentagon,
      );

      final bounds = stroke.bounds;
      expect(bounds.left, closeTo(100, 5));
      expect(bounds.top, closeTo(100, 5));
      expect(bounds.right, closeTo(300, 5));
      expect(bounds.bottom, closeTo(300, 5));
    });
  });
}
