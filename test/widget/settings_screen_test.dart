import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:draw_color_art_pro/features/settings/settings_screen.dart';
import 'package:draw_color_art_pro/features/settings/views/privacy_policy_screen.dart';
import 'package:draw_color_art_pro/features/settings/views/terms_of_service_screen.dart';
import 'package:draw_color_art_pro/features/templates/views/coloring_templates_modal.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildSettingsApp({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen Tests', () {
    testWidgets('renders all major sections and tiles', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Canvas'), findsOneWidget);
      expect(find.text('Audio & Haptics'), findsOneWidget);
      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('About & Legal'), findsOneWidget);

      expect(find.text('Default Canvas Size'), findsOneWidget);
      expect(find.text('Show Grid'), findsOneWidget);
      expect(find.text('Gestures'), findsOneWidget);
      expect(find.text('Sound Effects (SFX) & ASMR'), findsOneWidget);
      expect(find.text('Project Storage'), findsOneWidget);
      expect(find.text('Clear Cache'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('tapping Default Canvas Size opens preset picker and allows selection', (tester) async {
      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Default Canvas Size'));
      await tester.pumpAndSettle();

      expect(find.text('Applied when creating new blank artworks'), findsOneWidget);
      expect(find.text('Square 1:1 (2048 × 2048)'), findsOneWidget);

      await tester.tap(find.text('Square 1:1 (2048 × 2048)'));
      await tester.pumpAndSettle();

      // Modal dismissed and subtitle updated
      expect(find.text('Square 1:1 (2048 × 2048)'), findsOneWidget);
    });

    testWidgets('tapping Show Grid opens grid settings and toggles grid', (tester) async {
      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Grid'));
      await tester.pumpAndSettle();

      expect(find.text('Canvas Grid Settings'), findsOneWidget);
      expect(find.text('Overlay Grid on Canvas'), findsOneWidget);
      expect(find.text('Grid Cell Size'), findsOneWidget);

      // Toggle grid on
      await tester.tap(find.text('Overlay Grid on Canvas'));
      await tester.pumpAndSettle();

      // Change grid cell size to 64px
      await tester.tap(find.text('64 px'));
      await tester.pumpAndSettle();

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('On (64px grid)'), findsOneWidget);
    });

    testWidgets('tapping Gestures opens gesture settings modal', (tester) async {
      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gestures'));
      await tester.pumpAndSettle();

      expect(find.text('Touch Gestures'), findsOneWidget);
      expect(find.text('Two-Finger Tap: Undo'), findsOneWidget);
      expect(find.text('Three-Finger Tap: Redo'), findsOneWidget);
      expect(find.text('Two-Finger Canvas Rotation'), findsOneWidget);
      expect(find.text('Double-Tap Zoom Toggle'), findsOneWidget);
      expect(find.text('Stylus-Only Drawing Mode'), findsOneWidget);

      // Toggle palm rejection / stylus-only
      await tester.tap(find.text('Stylus-Only Drawing Mode'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('toggling Sound Effects switch updates sfx settings', (tester) async {
      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      final sfxFinder = find.widgetWithText(SwitchListTile, 'Sound Effects (SFX) & ASMR');
      expect(sfxFinder, findsOneWidget);

      await tester.tap(sfxFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('tapping Clear Cache shows confirmation dialog and clears cache', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear Cache'));
      await tester.pumpAndSettle();

      expect(find.text('Clear Temporary Cache?'), findsOneWidget);
      expect(find.textContaining('temporary rendering cache'), findsOneWidget);

      // Confirm clearing
      await tester.tap(find.widgetWithText(FilledButton, 'Clear Cache'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Cache cleared successfully.'), findsOneWidget);
    });

    testWidgets('tapping Privacy Policy opens full privacy policy view', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('100% Privacy by Design'), findsOneWidget);
      expect(find.text('1. Local-First & Zero Telemetry'), findsOneWidget);
    });

    testWidgets('tapping Terms of Service opens full terms view', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();

      expect(find.byType(TermsOfServiceScreen), findsOneWidget);
      expect(find.text('100% Artist Ownership'), findsOneWidget);
      expect(find.text('1. Intellectual Property & Artwork Ownership'), findsOneWidget);
    });
  });

  group('ColoringTemplatesModal Overflow Fix Tests', () {
    testWidgets('modal renders without horizontal overflow on narrow screens', (tester) async {
      // Simulate narrow phone screen (360x640)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      // Zero overflow error assertions
      expect(tester.takeException(), isNull);
    });
  });
}
