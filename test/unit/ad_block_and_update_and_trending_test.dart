import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:draw_color_art_pro/core/ads/ad_block_detector_service.dart';
import 'package:draw_color_art_pro/core/ads/ad_block_overlay.dart';
import 'package:draw_color_art_pro/core/ads/ad_block_notice_dialog.dart';
import 'package:draw_color_art_pro/core/services/in_app_update_service.dart';
import 'package:draw_color_art_pro/features/templates/services/coloring_catalog_service.dart';
import 'package:draw_color_art_pro/features/templates/services/template_procedural_generator.dart';

void main() {
  group('Anime & Trending Art Coloring Book Designs', () {
    test('TemplateCategory includes trendingArt with hot flame icon and gradient', () {
      expect(TemplateCategory.values.contains(TemplateCategory.trendingArt), isTrue);
      expect(TemplateCategory.trendingArt.label, equals('Trending & Pop Art'));
      expect(TemplateCategory.trendingArt.icon, equals(Icons.whatshot_rounded));
      expect(TemplateCategory.trendingArt.gradient.length, equals(2));
    });

    test('All 10 Trending Art motifs generate non-empty vector strokes', () {
      for (int motif = 0; motif < 10; motif++) {
        final strokes = TemplateProceduralGenerator.generate(
          42,
          TemplateCategory.trendingArt,
          1024,
          1024,
          motifIndex: motif,
        );
        expect(strokes.isNotEmpty, isTrue, reason: 'Trending motif $motif produced empty strokes');
        expect(strokes.length, greaterThan(5), reason: 'Trending motif $motif should have rich details');
      }
    });

    test('All 16 Anime & Character motifs generate rich vector strokes', () {
      for (int motif = 0; motif < 16; motif++) {
        final strokes = TemplateProceduralGenerator.generate(
          100 + motif,
          TemplateCategory.characters,
          1024,
          1024,
          motifIndex: motif,
        );
        expect(strokes.isNotEmpty, isTrue, reason: 'Anime motif $motif produced empty strokes');
        expect(strokes.length, greaterThan(4), reason: 'Anime motif $motif should have distinct strokes');
      }
    });

    test('ColoringCatalogService has new anime and trending art entries with unique IDs', () {
      final catalog = ColoringCatalogService.instance;

      // Verify specific new Anime entries
      expect(catalog.allTemplates.any((t) => t.id == 'characters_kitsune'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'characters_cyberninja'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'characters_saiyan'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'characters_mechapilot'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'characters_bobabarista'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'characters_sakurablade'), isTrue);

      // Verify specific new Trending Art entries
      expect(catalog.allTemplates.any((t) => t.id == 'trending_synthwave'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'trending_cyberpunk'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'trending_vaporwave'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'trending_boba'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'trending_origami_fox'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'trending_cassette'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'trending_graffiti_crown'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'trending_dreamcatcher'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'trending_popart_boom'), isTrue);
      expect(catalog.allTemplates.any((t) => t.id == 'trending_cyber_skull'), isTrue);
    });
  });

  group('Ad-Blocker Detector Service & 10s Toast Overlay', () {
    test('AdBlockDetectorService handles state, monitoring, and testing hooks', () {
      final service = AdBlockDetectorService.instance;
      service.reset();
      expect(service.isAdBlockerActive, isFalse);
      expect(service.hasChecked, isFalse);
      expect(service.shouldShowNotice(), isFalse);
      expect(service.isAdBlockerActiveNotifier.value, isFalse);

      // Verify test hook updates notifier
      service.setAdBlockerStateForTesting(true);
      expect(service.isAdBlockerActive, isTrue);
      expect(service.isAdBlockerActiveNotifier.value, isTrue);

      service.setAdBlockerStateForTesting(false);
      expect(service.isAdBlockerActive, isFalse);
      expect(service.isAdBlockerActiveNotifier.value, isFalse);
    });

    testWidgets('AdBlockToastOverlay shows nothing when ad blocker is disabled', (tester) async {
      final service = AdBlockDetectorService.instance;
      service.setAdBlockerStateForTesting(false);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdBlockToastOverlay(
            child: Scaffold(
              body: Center(child: Text('Normal App Content')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Content renders cleanly
      expect(find.text('Normal App Content'), findsOneWidget);
      // Zero toast or notice is shown
      expect(find.text('Ad Blocker / DNS Detected'), findsNothing);
    });

    testWidgets('AdBlockToastOverlay displays recurring toast when ad blocker is active', (tester) async {
      final service = AdBlockDetectorService.instance;
      service.setAdBlockerStateForTesting(true);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdBlockToastOverlay(
            child: Scaffold(
              body: Center(child: Text('Drawing Canvas Running')),
            ),
          ),
        ),
      );
      // Pump initial frame
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Drawing Canvas Running'), findsOneWidget);
      expect(find.text('Ad Blocker / DNS Detected'), findsOneWidget);
      expect(find.text('Recheck'), findsOneWidget);

      // Disable blocker -> should dismiss toast
      service.setAdBlockerStateForTesting(false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Ad Blocker / DNS Detected'), findsNothing);
    });

    testWidgets('AdBlockNoticeDialog renders dialog UI for user manual access', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdBlockNoticeDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ad Blocker Detected'), findsOneWidget);
      expect(find.text('Draw Color Art Pro is 100% Free'), findsOneWidget);
      expect(find.textContaining('We noticed an ad blocker is running'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Recheck'), findsOneWidget);
    });
  });

  group('In-App Flexible Update Service', () {
    test('InAppUpdateService has initial state and safe non-crashing check', () async {
      final updateService = InAppUpdateService.instance;
      expect(updateService.isChecking, isFalse);
      expect(updateService.isUpdateAvailable, isFalse);
      expect(updateService.isDownloading, isFalse);
    });
  });
}
