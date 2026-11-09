import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/features/ar_tracing/views/ar_tracing_screen.dart';
import 'package:draw_color_art_pro/features/templates/views/coloring_templates_modal.dart';

void main() {
  group('AR Tracing Studio Widget Tests', () {
    testWidgets('ArTracingScreen renders cleanly with simulated desk fallback in test environment', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArTracingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In tests/headless, camera defaults to simulated desk mode
      expect(find.text('Desk Simulation'), findsOneWidget);
      expect(find.text('Physical Paper Sheet (A4)'), findsOneWidget);

      // Verify controls are present
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Lock'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Templates'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });

    testWidgets('Tapping Lock toggles lock state and displays badge', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArTracingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap lock button
      await tester.tap(find.text('Lock'));
      await tester.pumpAndSettle();

      // Verify state changed to Locked
      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);

      // Tap again to unlock
      await tester.tap(find.text('Locked'));
      await tester.pumpAndSettle();

      expect(find.text('Lock'), findsOneWidget);
      expect(find.text('LOCKED'), findsNothing);
    });

    testWidgets('Tapping Filter cycles through visual filter modes', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArTracingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Normal'), findsOneWidget);

      // Tap filter
      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();
      expect(find.text('High Contrast'), findsOneWidget);

      // Tap filter again
      await tester.tap(find.text('High Contrast'));
      await tester.pumpAndSettle();
      expect(find.text('Neon Invert'), findsOneWidget);
    });

    testWidgets('Help button opens ArTutorialDialog with step-by-step guide', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ArTracingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap tutorial button
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('How to Trace in AR'), findsOneWidget);
      expect(find.text('Step 1: Elevate Your Phone'), findsOneWidget);
      expect(find.text('Step 2: Align & Lock'), findsOneWidget);
      expect(find.text('Step 3: Trace with Pen or Pencil'), findsOneWidget);
      expect(find.text('Got it, Start Tracing!'), findsOneWidget);

      // Tap dismiss button
      await tester.tap(find.text('Got it, Start Tracing!'));
      await tester.pumpAndSettle();

      expect(find.text('How to Trace in AR'), findsNothing);
    });
  });

  group('ColoringTemplatesModal 1000+ Browser Tests', () {
    testWidgets('modal renders search bar, surprise me hero, and category chips', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ColoringTemplatesModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coloring Book Templates'), findsOneWidget);
      expect(find.text('Surprise Me! (Random Template)'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsWidgets);
      expect(find.text('Mandala & Sacred'), findsWidgets);
      expect(find.text('Nature & Flora'), findsWidgets);

      // Verify template cards have Color and AR Trace actions
      expect(find.text('Color'), findsWidgets);
      expect(find.byIcon(Icons.camera_alt_rounded), findsWidgets);
    });

    testWidgets('typing into search bar filters template list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ColoringTemplatesModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'Lotus');
      await tester.pumpAndSettle();

      expect(find.textContaining('Lotus'), findsWidgets);
    });
  });
}
