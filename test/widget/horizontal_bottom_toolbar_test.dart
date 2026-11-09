import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/features/canvas/models/tools.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/horizontal_bottom_toolbar.dart';

void main() {
  group('HorizontalBottomToolbar Widget Tests', () {
    testWidgets('renders all tools in horizontally scrolling bottom toolbar', (tester) async {
      bool colorPickerToggled = false;
      bool layerPanelToggled = false;
      bool shareArtTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: HorizontalBottomToolbar(
                isColorPickerOpen: false,
                isLayerPanelOpen: false,
                onToggleColorPicker: () => colorPickerToggled = true,
                onToggleLayerPanel: () => layerPanelToggled = true,
                onShareArt: () => shareArtTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap color swatch
      await tester.tap(find.byTooltip('Color Palette'));
      await tester.pumpAndSettle();
      expect(colorPickerToggled, isTrue);

      // Verify essential tools are present
      expect(find.text('Draw'), findsOneWidget);
      expect(find.text('Fill'), findsOneWidget);
      expect(find.text('Eraser'), findsOneWidget);

      // Scroll horizontally in the bottom toolbar (which is the second Scrollable)
      final bottomScrollable = find.byType(Scrollable).last;

      await tester.scrollUntilVisible(find.text('Text'), 50, scrollable: bottomScrollable);
      expect(find.text('Text'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Shape'), 50, scrollable: bottomScrollable);
      expect(find.text('Shape'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Layers'), 50, scrollable: bottomScrollable);
      expect(find.text('Layers'), findsOneWidget);

      // Tap Layers
      await tester.tap(find.text('Layers'));
      await tester.pumpAndSettle();
      expect(layerPanelToggled, isTrue);

      await tester.scrollUntilVisible(find.text('Share'), 50, scrollable: bottomScrollable);
      expect(find.text('Share'), findsOneWidget);

      // Tap share
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(shareArtTapped, isTrue);
    });

    testWidgets('switching tool dynamically updates the contextual options strip', (tester) async {
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

      // Initially Brush (Draw) options are shown — sub-tool chips + size slider
      expect(find.text('Brush'), findsOneWidget); // sub-tool chip
      expect(find.text('Pen'), findsOneWidget); // sub-tool chip
      expect(find.textContaining('px'), findsWidgets);

      // Switch to Shape tool
      container.read(activeToolProvider.notifier).selectTool(DrawingTool.shape);
      await tester.pumpAndSettle();

      // Shape options strip should now be visible
      expect(find.text('Shape:'), findsOneWidget);
      expect(find.text('Rectangle'), findsOneWidget);
      expect(find.text('Circle'), findsOneWidget);

      // Switch to Text tool
      container.read(activeToolProvider.notifier).selectTool(DrawingTool.text);
      await tester.pumpAndSettle();

      // Text options strip should now be visible with justified font selector pill & font size slider
      expect(find.byIcon(CupertinoIcons.textformat), findsWidgets);
      expect(find.textContaining('pt'), findsWidgets);
    });
  });
}
