import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/features/canvas/views/drawing_screen.dart';
import 'package:draw_color_art_pro/features/canvas/models/tools.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';

void main() {
  testWidgets('All coloring and drawing tools exhibit distinct behavior and controls', (tester) async {
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

    // 1. Initial tool is Brush
    expect(container.read(activeToolProvider), DrawingTool.brush);
    expect(find.text('Brush'), findsOneWidget);

    // 2. Select Pencil -> Brush hardness set for graphite feel
    container.read(activeToolProvider.notifier).selectTool(DrawingTool.pencil);
    await tester.pumpAndSettle();
    expect(container.read(activeBrushProvider).hardness, greaterThanOrEqualTo(0.8));

    // 3. Select Pen -> Inking with smooth stabilization
    container.read(activeToolProvider.notifier).selectTool(DrawingTool.pen);
    await tester.pumpAndSettle();
    expect(container.read(activeBrushProvider).stabilization, StabilizationMode.smooth);

    // 4. Select Marker -> Chisel with Glaze opacity
    container.read(activeToolProvider.notifier).selectTool(DrawingTool.marker);
    await tester.pumpAndSettle();
    expect(container.read(activeBrushProvider).opacity, lessThanOrEqualTo(0.6));

    // 5. Select Eraser -> Eraser mode active
    container.read(activeToolProvider.notifier).selectTool(DrawingTool.eraser);
    await tester.pumpAndSettle();
    expect(container.read(activeBrushProvider).isEraser, isTrue);

    // 6. Select Bucket Fill -> Tolerance slider with flood fill helper
    container.read(activeToolProvider.notifier).selectTool(DrawingTool.fill);
    await tester.pumpAndSettle();
    expect(find.textContaining('Tolerance:'), findsOneWidget);
    expect(find.text('Tap area to flood fill'), findsOneWidget);

    // 7. Select Eyedropper -> Live hex swatch and canvas sampling helper
    container.read(activeToolProvider.notifier).selectTool(DrawingTool.eyedropper);
    await tester.pumpAndSettle();
    expect(find.textContaining('Color Picked:'), findsOneWidget);
    expect(find.text('Tap anywhere on canvas to pick color'), findsOneWidget);

    // 8. Select Shape -> Shape choices with Outline/Filled toggle
    container.read(activeToolProvider.notifier).selectTool(DrawingTool.shape);
    await tester.pumpAndSettle();
    expect(find.text('Outline'), findsOneWidget);
    expect(container.read(activeShapeProvider), ShapeType.rectangle);

    // Change shape to Circle
    container.read(activeShapeProvider.notifier).state = ShapeType.circle;
    await tester.pumpAndSettle();
    expect(container.read(activeShapeProvider), ShapeType.circle);

    // Toggle filled state
    container.read(isShapeFilledProvider.notifier).state = true;
    await tester.pumpAndSettle();
    expect(find.text('Filled'), findsOneWidget);

    // 9. Select Text -> Font selector dropdown button in toolbar strip
    container.read(activeToolProvider.notifier).selectTool(DrawingTool.text);
    await tester.pumpAndSettle();
    expect(find.byIcon(CupertinoIcons.chevron_up_chevron_down), findsOneWidget);

    // 10. Select Highlighter -> Chisel tip with Tint slider and Color Inside toggle
    container.read(activeToolProvider.notifier).selectTool(DrawingTool.highlighter);
    await tester.pumpAndSettle();
    expect(find.textContaining('Chisel:'), findsOneWidget);
    expect(find.textContaining('Tint:'), findsOneWidget);
    expect(container.read(activeBrushProvider).isHighlighter, isTrue);

    // 11. Select Rainbow -> Mode chips (Spectrum, Pastel, Neon, Sunset)
    container.read(activeToolProvider.notifier).selectTool(DrawingTool.rainbow);
    await tester.pumpAndSettle();
    expect(find.text('Spectrum'), findsOneWidget);
    expect(find.text('Pastel'), findsOneWidget);
    expect(find.text('Neon'), findsOneWidget);
    expect(find.text('Sunset'), findsOneWidget);
    expect(container.read(activeBrushProvider).isRainbow, isTrue);

    // 12. Select Gradient -> Linear / Radial chips
    container.read(activeToolProvider.notifier).selectTool(DrawingTool.gradient);
    await tester.pumpAndSettle();
    expect(find.text('Linear'), findsOneWidget);
    expect(find.text('Radial'), findsOneWidget);
    expect(find.textContaining('Drag line across canvas'), findsOneWidget);

    // 13. Select Selection -> Drag box helper
    container.read(activeToolProvider.notifier).selectTool(DrawingTool.selection);
    await tester.pumpAndSettle();
    expect(find.text('Drag box on canvas to select'), findsOneWidget);

    // 14. Select Transform -> Drag canvas helper & Center Layer button
    container.read(activeToolProvider.notifier).selectTool(DrawingTool.transform);
    await tester.pumpAndSettle();
    expect(find.text('Center Layer'), findsOneWidget);
    expect(find.text('Drag canvas to move active layer'), findsOneWidget);

    // 15. Quick Palette Theme switching
    expect(container.read(quickPaletteThemeProvider), QuickPaletteTheme.classic);
    container.read(quickPaletteThemeProvider.notifier).state =
        container.read(quickPaletteThemeProvider).nextTheme;
    await tester.pumpAndSettle();
    expect(container.read(quickPaletteThemeProvider), QuickPaletteTheme.pastel);
  });
}
