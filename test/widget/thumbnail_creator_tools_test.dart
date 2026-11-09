import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/features/canvas/models/canvas_document.dart';
import 'package:draw_color_art_pro/features/canvas/models/drawing_guides.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/canvas_painter.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/shapes_icons_panel.dart';
import 'package:draw_color_art_pro/features/canvas/models/thumbnail_palette.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/thumbnail_save_modal.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/thumbnail_tools_modal.dart';
import 'package:draw_color_art_pro/features/brushes/default_brushes.dart';

void main() {
  group('Thumbnail Creator Features & Bugs Verification', () {
    test('DrawingGuideType includes thumbnailSafeZone and ruleOfThirds with descriptions', () {
      expect(DrawingGuideType.thumbnailSafeZone.label, 'Thumbnail Safe Zone');
      expect(DrawingGuideType.thumbnailSafeZone.description, contains('timestamp'));
      expect(DrawingGuideType.ruleOfThirds.label, 'Rule of Thirds');
      expect(DrawingGuideType.ruleOfThirds.description, contains('composition grid'));

      const config = DrawingGuideConfig(
        type: DrawingGuideType.thumbnailSafeZone,
        opacity: 0.85,
      );
      expect(config.isEnabled, isTrue);
      expect(config.type, DrawingGuideType.thumbnailSafeZone);
    });

    test('Stroke model supports text outline stroke and text background color serialization', () {
      final stroke = Stroke(
        points: const [
          StrokePoint(x: 100, y: 100),
        ],
        color: Colors.white,
        brush: DefaultBrushes.hardBrush,
        text: 'BIG REVEAL!',
        fontFamily: 'Inter',
        fontSize: 48,
        isBold: true,
        textStrokeColor: Colors.black,
        textStrokeWidth: 5.0,
        textBackgroundColor: const Color(0xFFFF3366),
      );

      final json = stroke.toJson();
      expect(json['textStrokeWidth'], 5.0);
      expect(json['textStrokeColor'], Colors.black.toARGB32());
      expect(json['textBackgroundColor'], const Color(0xFFFF3366).toARGB32());

      final restored = Stroke.fromJson(json);
      expect(restored.text, 'BIG REVEAL!');
      expect(restored.textStrokeWidth, 5.0);
      expect(restored.textStrokeColor, Colors.black);
      expect(restored.textBackgroundColor, const Color(0xFFFF3366));
    });

    test('CanvasPainter renders YouTube safe zone and rule of thirds without throwing', () {
      final doc = CanvasDocument(
        name: 'Test Thumbnail',
        width: 1280,
        height: 720,
      );

      final safeZonePainter = CanvasPainter(
        document: doc,
        drawingGuide: const DrawingGuideConfig(
          type: DrawingGuideType.thumbnailSafeZone,
          opacity: 0.8,
        ),
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1280, 720));
      // Should execute cleanly without error
      safeZonePainter.paint(canvas, const Size(1280, 720));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();

      // Test Rule of Thirds
      final thirdsPainter = CanvasPainter(
        document: doc,
        drawingGuide: const DrawingGuideConfig(
          type: DrawingGuideType.ruleOfThirds,
          opacity: 0.8,
        ),
      );
      final recorder2 = ui.PictureRecorder();
      final canvas2 = Canvas(recorder2, const Rect.fromLTWH(0, 0, 1280, 720));
      thirdsPainter.paint(canvas2, const Size(1280, 720));
      final picture2 = recorder2.endRecording();
      expect(picture2, isNotNull);
      picture2.dispose();

      // Test isThumbnail mode (skips overlays and shadows)
      final thumbPainter = CanvasPainter(
        document: doc,
        isThumbnail: true,
        drawingGuide: const DrawingGuideConfig(
          type: DrawingGuideType.thumbnailSafeZone,
        ),
      );
      final recorder3 = ui.PictureRecorder();
      final canvas3 = Canvas(recorder3, const Rect.fromLTWH(0, 0, 320, 180));
      thumbPainter.paint(canvas3, const Size(320, 180));
      final picture3 = recorder3.endRecording();
      expect(picture3, isNotNull);
      picture3.dispose();
    });



    testWidgets('ShapesIconsPanel includes Creator Badges category with badge entries', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ShapesIconsPanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Creator Badges tab
      final badgeTab = find.text('Creator Badges');
      expect(badgeTab, findsOneWidget);
      await tester.tap(badgeTab);
      await tester.pumpAndSettle();

      // Check badges exist
      expect(find.text('NEW!'), findsWidgets);
      expect(find.text('VS'), findsWidgets);
      expect(find.text('TOP 10'), findsWidgets);
      expect(find.text('LIVE'), findsWidgets);
    });



    test('CanvasDocument correctly tracks and serializes isThumbnail property', () {
      final doc = CanvasDocument(
        name: 'My YouTube Thumbnail',
        width: 1920,
        height: 1080,
        isThumbnail: true,
      );
      expect(doc.isThumbnail, isTrue);

      final json = doc.toJson();
      expect(json['isThumbnail'], isTrue);

      final restored = CanvasDocument.fromJson(json);
      expect(restored.isThumbnail, isTrue);

      // Backward-compatible name check
      final legacyJson = Map<String, dynamic>.from(json)..remove('isThumbnail');
      final legacyRestored = CanvasDocument.fromJson(legacyJson);
      expect(legacyRestored.isThumbnail, isTrue);

      final nonThumbDoc = CanvasDocument(
        name: 'My Sketch',
        width: 1080,
        height: 1080,
      );
      expect(nonThumbDoc.isThumbnail, isFalse);
    });

    test('Thumbnail viewport fit-to-screen scale & centering calculation', () {
      const screenW = 412.0;
      const screenH = 800.0;
      const canvasW = 1280.0;
      const canvasH = 720.0;

      const scaleX = screenW / canvasW; // ~0.3218
      const scaleY = screenH / canvasH; // ~1.1111
      const fitZoom = (scaleX < scaleY ? scaleX : scaleY) * 0.90; // ~0.2897
      const fitPanX = (screenW - canvasW * fitZoom) / 2.0;
      const fitPanY = (screenH - canvasH * fitZoom) / 2.0;

      expect(fitZoom, lessThan(1.0));
      expect(canvasW * fitZoom, lessThanOrEqualTo(screenW));
      expect(canvasH * fitZoom, lessThanOrEqualTo(screenH));
      expect(fitPanX, isNonNegative);
      expect(fitPanY, isNonNegative);
    });

    test('ThumbnailColorPalette provides 8 curated palettes with 5 swatches and contrast analysis', () {
      expect(ThumbnailColorPalette.curatedPalettes.length, 8);
      for (final pal in ThumbnailColorPalette.curatedPalettes) {
        expect(pal.swatches.length, 5);
        expect(pal.ctrScore, greaterThanOrEqualTo(90));
        expect(pal.contrastRatio, greaterThan(1.0));
        expect(pal.contrastRating, isNotEmpty);
      }

      final neon = ThumbnailColorPalette.curatedPalettes.first;
      expect(neon.id, 'high_ctr_neon');
      expect(neon.name, 'High-CTR Neon');
      expect(neon.contrastRating, contains('SUPERIOR'));
    });

    testWidgets('ThumbnailSaveModal renders PNG/JPG format selector and resolution scale', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final doc = CanvasDocument(
        name: 'Viral Tech Review',
        width: 1920,
        height: 1080,
        isThumbnail: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThumbnailSaveModal(document: doc),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & dimensions
      expect(find.text('Save Thumbnail to Gallery'), findsOneWidget);
      expect(find.textContaining('Viral Tech Review'), findsWidgets);
      expect(find.text('CHOOSE IMAGE FORMAT'), findsOneWidget);

      // Verify PNG and JPG options exist
      expect(find.textContaining('PNG (Lossless'), findsOneWidget);
      expect(find.textContaining('JPG / JPEG'), findsOneWidget);

      // Verify scale selector
      expect(find.text('OUTPUT RESOLUTION:'), findsOneWidget);
      expect(find.text('Standard 1x'), findsOneWidget);
      expect(find.text('Ultra-Res 2x'), findsOneWidget);

      // Verify save button exists
      expect(find.textContaining('Save to Photos / Gallery'), findsOneWidget);

      // Tap JPG format
      await tester.tap(find.textContaining('JPG / JPEG'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Save to Photos / Gallery (JPG)'), findsOneWidget);
      expect(find.textContaining('smaller file size'), findsOneWidget);
    });

    testWidgets('ThumbnailToolsModal renders Color Palettes, Creator Badges, and Safe Zones', (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ThumbnailToolsModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thumbnail Pro Suite'), findsOneWidget);
      expect(find.text('Color Palettes'), findsOneWidget);
      expect(find.text('Creator Badges'), findsOneWidget);
      expect(find.text('Safe Zones'), findsOneWidget);
      expect(find.text('Save to Gallery (JPG / PNG)'), findsOneWidget);

      // Check curated palettes are listed in tab 0
      expect(find.text('High-CTR Neon'), findsOneWidget);
      expect(find.text('Viral Gaming'), findsOneWidget);

      // Switch to Creator Badges tab
      await tester.tap(find.text('Creator Badges'));
      await tester.pumpAndSettle();
      expect(find.text('NEW!'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('TOP 10'), findsOneWidget);
      expect(find.text('ALERT'), findsOneWidget);

      // Switch to Safe Zones tab
      await tester.tap(find.text('Safe Zones'));
      await tester.pumpAndSettle();
      expect(find.text('YouTube 16:9 Safe Zone'), findsOneWidget);
      expect(find.text('Rule of Thirds (3×3 Grid)'), findsOneWidget);
      expect(find.text('Guides Off'), findsOneWidget);
    });
  });
}

