import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/features/canvas/models/tools.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/canvas_size_picker_modal.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/shapes_icons_panel.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/image_search_modal.dart';
import 'package:draw_color_art_pro/features/text/views/font_picker_dialog.dart';

void main() {
  group('Social Media Tools Widget Tests', () {
    testWidgets('CanvasSizePickerModal shows Art & General and Social Media tabs and platform presets', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CanvasSizePickerModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify tabs exist
      expect(find.text('Art & General'), findsOneWidget);
      expect(find.text('Social Media'), findsOneWidget);

      // Switch to Social Media tab
      await tester.tap(find.text('Social Media'));
      await tester.pumpAndSettle();

      // Verify Social Media presets appear
      expect(find.textContaining('YouTube Thumbnail'), findsOneWidget);
      expect(find.textContaining('TikTok / Reels'), findsOneWidget);
      expect(find.textContaining('Instagram Post'), findsOneWidget);

      // Tap on YouTube Thumbnail (16:9)
      await tester.tap(find.textContaining('YouTube Thumbnail'));
      await tester.pumpAndSettle();

      // Verify width and height controllers are updated to 1280 and 720
      expect(find.widgetWithText(TextField, '1280'), findsOneWidget);
      expect(find.widgetWithText(TextField, '720'), findsOneWidget);
    });

    testWidgets('ShapesIconsPanel displays categorized shapes and inserts shape on tap', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ShapesIconsPanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify tabs / categories
      expect(find.text('Basic Shapes'), findsOneWidget);
      expect(find.text('Arrows & Lines'), findsOneWidget);
      expect(find.text('Social & Common'), findsOneWidget);
      expect(find.text('Decorative'), findsOneWidget);

      // Check for basic shapes
      expect(find.text('Rectangle'), findsOneWidget);
      expect(find.text('Circle'), findsOneWidget);
      expect(find.text('Star'), findsOneWidget);

      // Tap on 'Social & Common' tab
      await tester.tap(find.text('Social & Common'));
      await tester.pumpAndSettle();

      expect(find.text('Play Button'), findsOneWidget);
      expect(find.text('Crown'), findsOneWidget);

      // Tap on Crown to insert
      await tester.tap(find.text('Crown'));
      await tester.pumpAndSettle();

      // Verify active tool switched to shape and active shape is crown
      expect(container.read(activeToolProvider), equals(DrawingTool.shape));
      expect(container.read(activeShapeProvider), equals(ShapeType.crown));
      expect(container.read(canvasDocumentProvider).layers.first.strokes.isNotEmpty, isTrue);
    });

    testWidgets('FontPickerDialog displays typography controls and responds to styling toggles', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      String? appliedTextResult;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: FontPickerDialog(
                onApplyText: (text, style) {
                  appliedTextResult = text;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and live text card
      expect(find.text('100+ Fonts & Typography'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);

      // Tap bold button
      await tester.tap(find.byIcon(Icons.format_bold_rounded));
      await tester.pumpAndSettle();
      expect(container.read(typographyConfigProvider).isBold, isTrue);

      // Tap shadow toggle
      await tester.tap(find.byIcon(Icons.blur_on_rounded));
      await tester.pumpAndSettle();
      expect(container.read(typographyConfigProvider).hasShadow, isTrue);

      // Tap text transform button
      await tester.tap(find.text('Aa (Normal)'));
      await tester.pumpAndSettle();
      expect(container.read(typographyConfigProvider).textTransform, equals(TextTransformMode.uppercase));

      // Tap 'Use Font' button
      final useFontButton = find.textContaining('Use');
      await tester.ensureVisible(useFontButton);
      await tester.tap(useFontButton);
      await tester.pumpAndSettle();

      expect(appliedTextResult, isNotNull);
      // Because uppercase was chosen, applied text should be uppercase
      expect(appliedTextResult, equals(appliedTextResult!.toUpperCase()));
    });

    testWidgets('ImageSearchModal renders search bar and category chips', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ImageSearchModal(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Free Stock Images'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Trending'), findsOneWidget);
      expect(find.text('Nature'), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);

      // Tap on Nature category chip
      await tester.tap(find.text('Nature'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Images provided by Pexels · Free to use'), findsOneWidget);
    });
  });
}
