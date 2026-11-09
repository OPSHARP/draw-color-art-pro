import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/features/canvas/models/tools.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';
import 'package:draw_color_art_pro/features/canvas/providers/image_import_providers.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/image_placement_overlay.dart';

/// Helper to create a small dummy test ui.Image
Future<ui.Image> createTestImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 100, 100));
  final paint = Paint()..color = Colors.blue;
  canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), paint);
  final picture = recorder.endRecording();
  return picture.toImage(100, 100);
}

void main() {
  group('Image Placement Overlay Widget Tests', () {
    testWidgets('ImagePlacementOverlay does not render when placedImageProvider is null', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  ImagePlacementOverlay(),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ImagePlacementOverlay), findsOneWidget);
      expect(find.text('Fit Canvas'), findsNothing);
      expect(find.text('Place Image'), findsNothing);
    });

    testWidgets('ImagePlacementOverlay renders transform handles and controls when active', (tester) async {
      final testImage = await createTestImage();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(placedImageProvider.notifier).state = PlacedImageData(
        file: File('/tmp/test.png'),
        path: '/tmp/test.png',
        image: testImage,
        position: const Offset(50, 50),
        size: const Size(200, 200),
        opacity: 0.8,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  ImagePlacementOverlay(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fit Canvas'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('New Layer'), findsOneWidget);
      expect(find.text('Place Image'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);

      // Tap Cancel -> should dismiss placement
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(container.read(placedImageProvider), isNull);
      expect(container.read(activeToolProvider), DrawingTool.brush);
    });

    testWidgets('Tapping Place Image commits stroke to layer and clears overlay', (tester) async {
      final testImage = await createTestImage();

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final docNotifier = container.read(canvasDocumentProvider.notifier);
      docNotifier.createNew(name: 'Canvas 1', width: 1000, height: 1000);

      container.read(placedImageProvider.notifier).state = PlacedImageData(
        file: File('/tmp/photo.jpg'),
        path: '/tmp/photo.jpg',
        image: testImage,
        position: const Offset(100, 100),
        size: const Size(300, 300),
        opacity: 1.0,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  ImagePlacementOverlay(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Place Image
      await tester.tap(find.text('Place Image'));
      await tester.pumpAndSettle();

      expect(container.read(placedImageProvider), isNull);
      final doc = container.read(canvasDocumentProvider);
      expect(doc.activeLayer!.strokes.length, 1);
      expect(doc.activeLayer!.strokes.first.imagePath, '/tmp/photo.jpg');
    });
  });
}
