import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:draw_color_art_pro/features/canvas/models/tools.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/horizontal_bottom_toolbar.dart';
import 'package:draw_color_art_pro/features/projects/models/project_entry.dart';
import 'package:draw_color_art_pro/features/projects/views/project_actions_bottom_sheet.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Hold to Delete & Pro Actions Tests', () {
    testWidgets('Holding / long pressing project triggers ProjectActionsBottomSheet with Delete option', (tester) async {
      final dummyProject = ProjectEntry(
        id: 'test_project_1',
        name: 'Masterpiece Sunset',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
        layerCount: 3,
        strokeCount: 42,
        width: 1080,
        height: 1920,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => Consumer(
                    builder: (context, ref, _) => GestureDetector(
                      onLongPress: () => ProjectActionsBottomSheet.show(context, ref, dummyProject),
                      child: const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Hold to delete test card'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Long press the card
      await tester.longPress(find.text('Hold to delete test card'));
      await tester.pumpAndSettle();

      // Verify bottom sheet opened
      expect(find.text('Masterpiece Sunset'), findsOneWidget);
      expect(find.text('Open & Continue Drawing'), findsOneWidget);
      expect(find.text('Share Artwork'), findsOneWidget);
      expect(find.text('Delete Artwork'), findsOneWidget);

      // Tap Delete Artwork
      await tester.tap(find.text('Delete Artwork'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Delete Artwork?'), findsOneWidget);
      expect(find.textContaining('Masterpiece Sunset'), findsAtLeastNWidgets(1));
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('Horizontal bottom toolbar includes Glow, Spray, Symmetry, Ruler and expanded shapes', (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: HorizontalBottomToolbar(
                isColorPickerOpen: false,
                isLayerPanelOpen: false,
                onToggleColorPicker: () {},
                onToggleLayerPanel: () {},
                onShareArt: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final toolbarScrollable = find.byType(Scrollable).last;

      // Check new tools exist (Glow Neon and Airbrush are consolidated into Draw)
      expect(find.text('Draw'), findsOneWidget);
      expect(find.text('Symmetry'), findsOneWidget);
      expect(find.text('Ruler'), findsOneWidget);

      // Tap Draw and verify sub-tool chips appear
      await tester.scrollUntilVisible(find.text('Draw'), 50, scrollable: toolbarScrollable);
      await tester.tap(find.text('Draw'));
      await tester.pumpAndSettle();
      // Brush is the default draw sub-tool
      expect(find.text('Brush'), findsOneWidget);
      expect(find.text('Pen'), findsOneWidget);
      expect(find.text('Pencil'), findsOneWidget);
      expect(find.text('Airbrush'), findsOneWidget);
      expect(find.text('Marker'), findsOneWidget);

      // Select Airbrush sub-tool via provider and verify it shows as active
      container.read(activeToolProvider.notifier).selectTool(DrawingTool.spray);
      await tester.pumpAndSettle();
      expect(container.read(activeToolProvider), DrawingTool.spray);

      // Switch to Shape and verify Heart & Hexagon choices
      await tester.scrollUntilVisible(find.text('Shape'), 50, scrollable: toolbarScrollable);
      await tester.tap(find.text('Shape'));
      await tester.pumpAndSettle();
      expect(find.text('Heart'), findsOneWidget);
      expect(find.text('Hexagon'), findsOneWidget);

      // Select Heart
      await tester.tap(find.text('Heart'));
      await tester.pumpAndSettle();
      expect(container.read(activeShapeProvider), ShapeType.heart);

      // Clear button exists
      expect(find.text('Clear'), findsOneWidget);
    });
  });
}
