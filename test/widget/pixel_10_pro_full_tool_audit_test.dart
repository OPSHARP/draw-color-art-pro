import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/features/canvas/views/drawing_screen.dart';
import 'package:draw_color_art_pro/features/canvas/models/tools.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/radial_quick_menu.dart';
import 'package:draw_color_art_pro/features/canvas/widgets/animation_timeline_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Google Pixel 10 Pro simulated viewport (1080 × 2424 physical px, 412 × 915 logical px)
  const pixel10ProLogicalSize = Size(412, 915);

  Widget createTestWidget({required WidgetRefCallback onRefReady}) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        home: Consumer(
          builder: (context, ref, child) {
            onRefReady(ref);
            return const DrawingScreen();
          },
        ),
      ),
    );
  }

  group('Pixel 10 Pro Comprehensive Device & Tool Audit', () {
    testWidgets('DrawingScreen renders edge-to-edge on Pixel 10 Pro dimensions without overflow',
        (tester) async {
      tester.view.physicalSize = Size(
        pixel10ProLogicalSize.width * 2.625,
        pixel10ProLogicalSize.height * 2.625,
      );
      tester.view.devicePixelRatio = 2.625;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        createTestWidget(onRefReady: (ref) => capturedRef = ref),
      );
      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow on Pixel 10 Pro
      expect(tester.takeException(), isNull);
      expect(find.byType(DrawingScreen), findsOneWidget);
      expect(capturedRef.read(activeToolProvider), equals(DrawingTool.brush));

      // Verify Floating QuickMenu and Flipbook icons are rendered on screen
      expect(find.byIcon(CupertinoIcons.circle_grid_hex_fill), findsAtLeastNWidgets(1));
      expect(find.byIcon(CupertinoIcons.play_rectangle), findsAtLeastNWidgets(1));
    });

    testWidgets('Audit: All 26 tools in DrawingTool can be selected cleanly without crashing',
        (tester) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        createTestWidget(onRefReady: (ref) => capturedRef = ref),
      );
      await tester.pumpAndSettle();

      final activeToolNotifier = capturedRef.read(activeToolProvider.notifier);

      for (final tool in DrawingTool.values) {
        activeToolNotifier.selectTool(tool);
        await tester.pump();

        expect(capturedRef.read(activeToolProvider), equals(tool));
        final brush = capturedRef.read(activeBrushProvider);

        // Check tool-specific properties
        if (tool == DrawingTool.smudge) {
          expect(brush.isSmudge, isTrue);
        } else if (tool == DrawingTool.blur) {
          expect(brush.isBlur, isTrue);
        } else if (tool == DrawingTool.eraser) {
          expect(brush.isEraser, isTrue);
        } else if (tool == DrawingTool.calligraphy) {
          expect(brush.isCalligraphy, isTrue);
        } else if (tool == DrawingTool.crayon) {
          expect(brush.isCrayon, isTrue);
        } else if (tool == DrawingTool.pixel) {
          expect(brush.isPixel, isTrue);
        }
      }
    });

    testWidgets('RadialQuickMenu opens and displays all 8 quick action nodes',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => RadialQuickMenu.show(context),
                  child: const Text('Open QuickMenu'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open QuickMenu'));
      await tester.pumpAndSettle();

      expect(find.byType(RadialQuickMenu), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Redo'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Picker'), findsOneWidget);
      expect(find.text('Flip'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Fit'), findsOneWidget);
      expect(find.text('Animate'), findsOneWidget);

      // Dismiss
      await tester.tap(find.byIcon(CupertinoIcons.xmark));
      await tester.pumpAndSettle();
      expect(find.byType(RadialQuickMenu), findsNothing);
    });

    testWidgets('AnimationTimelineModal renders frames scrubber, onion skin chip, and play controls',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => AnimationTimelineModal.show(context),
                  child: const Text('Open Timeline'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Timeline'));
      await tester.pumpAndSettle();

      expect(find.byType(AnimationTimelineModal), findsOneWidget);
      expect(find.text('Flipbook Animation Timeline'), findsOneWidget);
      expect(find.text('Onion Skin'), findsOneWidget);
      expect(find.text('Play Loop'), findsOneWidget);
      expect(find.text('Speed: 8 FPS'), findsOneWidget);

      // Toggle Play
      await tester.tap(find.text('Play Loop'));
      await tester.pump();
      expect(find.text('Pause'), findsOneWidget);

      // Toggle Pause
      await tester.tap(find.text('Pause'));
      await tester.pump();
      expect(find.text('Play Loop'), findsOneWidget);
    });
  });
}

typedef WidgetRefCallback = void Function(WidgetRef ref);
