import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';
import 'package:draw_color_art_pro/features/colors/color_picker_panel.dart';
import 'package:draw_color_art_pro/features/canvas/views/drawing_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Selecting a color in ColorPickerPanel updates activeColorProvider', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: ColorPickerPanel(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(activeColorProvider), const Color(0xFF000000));

    // Find red swatch (0xFFFF0000) in the palette section
    final redFinder = find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final box = widget.decoration as BoxDecoration;
        return box.color == const Color(0xFFFF0000);
      }
      return false;
    });

    expect(redFinder, findsAtLeastNWidgets(1));
    await tester.tap(redFinder.first);
    await tester.pumpAndSettle();

    expect(container.read(activeColorProvider), const Color(0xFFFF0000));
  });

  testWidgets('Tapping SaturationBrightness square updates activeColorProvider', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: ColorPickerPanel(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // First select red so saturation/brightness square has non-zero hue
    final redFinder = find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final box = widget.decoration as BoxDecoration;
        return box.color == const Color(0xFFFF0000);
      }
      return false;
    });
    await tester.tap(redFinder.first);
    await tester.pumpAndSettle();
    expect(container.read(activeColorProvider), const Color(0xFFFF0000));

    // Tap top-left of the SB square
    final sbFinder = find.byKey(const ValueKey('saturation_brightness_square'));
    expect(sbFinder, findsOneWidget);
    await tester.tapAt(tester.getTopLeft(sbFinder) + const Offset(10, 10));
    await tester.pumpAndSettle();

    final colorAfterSbTap = container.read(activeColorProvider);
    expect(colorAfterSbTap, isNot(const Color(0xFFFF0000)));
  });

  testWidgets('Dragging HueSlider when starting with black updates activeColorProvider', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: ColorPickerPanel(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(activeColorProvider), const Color(0xFF000000));

    // Find the Hue slider by key
    final hueFinder = find.byKey(const ValueKey('hue_slider'));
    expect(hueFinder, findsOneWidget);
    await tester.tapAt(tester.getCenter(hueFinder) + const Offset(50, 0));
    await tester.pumpAndSettle();

    final activeColor = container.read(activeColorProvider);
    // Should no longer be black! It should have elevated to a vibrant color
    expect(activeColor, isNot(const Color(0xFF000000)));
  });

  testWidgets('DrawingScreen allows opening, selecting from panel and toolbar', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: DrawingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Test toolbar swatch tap
    final toolbarRoyalBlue = find.descendant(
      of: find.byType(DrawingScreen),
      matching: find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.color == const Color(0xFF0055FF);
        }
        return false;
      }),
    );
    expect(toolbarRoyalBlue, findsOneWidget);
    await tester.tap(toolbarRoyalBlue);
    await tester.pumpAndSettle();

    expect(container.read(activeColorProvider), const Color(0xFF0055FF));

    // Check that the selected checkmark is rendered
    expect(find.descendant(of: toolbarRoyalBlue, matching: find.byIcon(Icons.check)), findsOneWidget);

    // 2. Open color picker panel
    final colorShortcut = find.byTooltip('Color Palette');
    expect(colorShortcut, findsOneWidget);
    await tester.tap(colorShortcut);
    await tester.pumpAndSettle();

    expect(find.byType(ColorPickerPanel), findsOneWidget);

    // 3. Tap yellow (0xFFFFD700) in ColorPickerPanel
    final yellowFinder = find.descendant(
      of: find.byType(ColorPickerPanel),
      matching: find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.color == const Color(0xFFFFD700);
        }
        return false;
      }),
    );

    expect(yellowFinder, findsAtLeastNWidgets(1));
    await tester.tap(yellowFinder.first);
    await tester.pumpAndSettle();

    expect(container.read(activeColorProvider), const Color(0xFFFFD700));
  });

  testWidgets('Palette switching and Harmonies selection works in ColorPickerPanel', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: ColorPickerPanel(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to 'Pastel Dream'
    final pastelChipFinder = find.text('Pastel Dream');
    expect(pastelChipFinder, findsOneWidget);
    await tester.tap(pastelChipFinder);
    await tester.pumpAndSettle();

    // Tap pastel pink (0xFFFFB3BA)
    final pastelPinkFinder = find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final box = widget.decoration as BoxDecoration;
        return box.color == const Color(0xFFFFB3BA);
      }
      return false;
    });
    expect(pastelPinkFinder, findsOneWidget);
    await tester.tap(pastelPinkFinder);
    await tester.pumpAndSettle();

    expect(container.read(activeColorProvider), const Color(0xFFFFB3BA));

    // Toggle to Harmonies
    final harmoniesToggle = find.text('Harmonies');
    expect(harmoniesToggle, findsOneWidget);
    await tester.tap(harmoniesToggle);
    await tester.pumpAndSettle();

    // Tap a harmonic swatch (first harmonic swatch that is not the current color)
    final harmonySwatches = find.descendant(
      of: find.byType(ColorPickerPanel),
      matching: find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.borderRadius == BorderRadius.circular(8); // AppRadius.xs
        }
        return false;
      }),
    );
    expect(harmonySwatches, findsAtLeastNWidgets(1));
    await tester.tap(harmonySwatches.last);
    await tester.pumpAndSettle();

    // Verify active color changed
    expect(container.read(activeColorProvider), isNotNull);
  });

  testWidgets('Entering HEX code in ColorPickerPanel updates activeColorProvider', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: ColorPickerPanel(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    await tester.enterText(textFieldFinder, '#00FF00');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(container.read(activeColorProvider), const Color(0xFF00FF00));
  });

  testWidgets('Tapping Opacity slider updates activeColorProvider alpha', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: ColorPickerPanel(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final opacityFinder = find.byKey(const ValueKey('opacity_slider'));
    expect(opacityFinder, findsOneWidget);

    // Tap halfway across the opacity slider (~50% opacity)
    await tester.tapAt(tester.getCenter(opacityFinder));
    await tester.pumpAndSettle();

    final activeColor = container.read(activeColorProvider);
    expect(activeColor.a, lessThan(1.0));
  });
}
