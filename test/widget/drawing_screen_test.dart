import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/features/canvas/views/drawing_screen.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/drawing_top_bar.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/horizontal_bottom_toolbar.dart';
import 'package:draw_color_art_pro/features/colors/color_picker_panel.dart';
import 'package:draw_color_art_pro/features/canvas/models/tools.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';
import 'package:draw_color_art_pro/features/templates/models/coloring_template.dart';

void main() {
  testWidgets('DrawingScreen renders all workspace components and allows toggling color picker', (WidgetTester tester) async {
    // Set desktop / tablet screen size for clear layout
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DrawingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify main components are present
    expect(find.byType(DrawingTopBar), findsOneWidget);
    expect(find.byType(HorizontalBottomToolbar), findsOneWidget);
    expect(find.text('Untitled'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DrawingTopBar),
        matching: find.textContaining('%'),
      ),
      findsOneWidget,
    );

    // Verify Undo & Redo are present on HorizontalBottomToolbar (feature layout)
    expect(
      find.descendant(
        of: find.byType(HorizontalBottomToolbar),
        matching: find.text('Undo'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(HorizontalBottomToolbar),
        matching: find.text('Redo'),
      ),
      findsOneWidget,
    );

    // Color picker is initially hidden
    expect(find.byType(ColorPickerPanel), findsNothing);

    // Find and tap the color swatch in the bottom toolbar
    final colorShortcutFinder = find.descendant(
      of: find.byType(HorizontalBottomToolbar),
      matching: find.byTooltip('Color Palette'),
    );
    expect(colorShortcutFinder, findsOneWidget);
    await tester.tap(colorShortcutFinder);
    await tester.pumpAndSettle();

    // Color picker should now be visible
    expect(find.byType(ColorPickerPanel), findsOneWidget);

    // Tap it again to toggle off
    await tester.tap(colorShortcutFinder);
    await tester.pumpAndSettle();
    expect(find.byType(ColorPickerPanel), findsNothing);
  });

  testWidgets('DrawingScreen back button works and pops safely', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DrawingScreen()),
                    );
                  },
                  child: const Text('Open Drawing'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open DrawingScreen
    await tester.tap(find.text('Open Drawing'));
    await tester.pumpAndSettle();
    expect(find.byType(DrawingScreen), findsOneWidget);

    // Tap Back button in DrawingTopBar
    final backButtonFinder = find.descendant(
      of: find.byType(DrawingTopBar),
      matching: find.byTooltip('Back'),
    );
    expect(backButtonFinder, findsOneWidget);
    await tester.tap(backButtonFinder);
    await tester.pumpAndSettle();

    // Should be popped back to the launcher screen
    expect(find.byType(DrawingScreen), findsNothing);
    expect(find.text('Open Drawing'), findsOneWidget);
  });

  testWidgets('Opening coloring book design automatically opens fit to screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer();
    final template = ColoringTemplates.sacredMandala;
    final doc = template.createDocument();
    container.read(canvasDocumentProvider.notifier).loadDocument(doc);
    container.read(autoFitToScreenProvider.notifier).state = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: DrawingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the canvas view state was auto-fitted
    final viewState = container.read(canvasViewProvider);
    // 400 wide screen, 2048 wide canvas: fitZoom is approximately (400 / 2048) * 0.90 = ~0.175
    expect(viewState.zoom, lessThan(0.5));
    expect(viewState.zoom, greaterThan(0.1));
    // Verify canvas is horizontally centered
    expect(viewState.panX, greaterThan(0.0));

    // Also verify DrawingTopBar does not show 100%
    expect(
      find.descendant(
        of: find.byType(DrawingTopBar),
        matching: find.text('100%'),
      ),
      findsNothing,
    );
  });

  testWidgets('Right vertical floating tool menu can be minimized and expanded with instant tool switching', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: DrawingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify right menu is initially expanded with 'Hide' minimize button and core tools
    expect(find.text('Hide'), findsOneWidget);
    expect(find.text('Draw'), findsWidgets);
    expect(find.text('Eraser'), findsWidgets);
    expect(find.text('Fill'), findsWidgets);

    // Tap 'Hide' to minimize the right menu
    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();

    // Verify expanded menu items are hidden and minimized pill with 'Expand Tools' is visible
    expect(find.text('Hide'), findsNothing);
    expect(find.byTooltip('Expand Tools'), findsOneWidget);

    // Tap minimized pill to expand it back
    await tester.tap(find.byTooltip('Expand Tools'));
    await tester.pumpAndSettle();

    // Verify menu is expanded again
    expect(find.text('Hide'), findsOneWidget);

    // Verify instant tool switching
    await tester.tap(find.text('Eraser').first);
    await tester.pumpAndSettle();
    expect(container.read(activeToolProvider), equals(DrawingTool.eraser));
  });
}

