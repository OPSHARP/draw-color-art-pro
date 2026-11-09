import 'package:flutter_test/flutter_test.dart';
import 'package:draw_color_art_pro/features/templates/services/coloring_catalog_service.dart';
import 'package:draw_color_art_pro/features/templates/services/template_procedural_generator.dart';
import 'package:draw_color_art_pro/features/templates/widgets/template_thumbnail_painter.dart';

void main() {
  group('Coloring Catalog Service - Duplicate Elimination & Diversity Tests', () {
    final catalog = ColoringCatalogService.instance;

    test('catalog contains 200 templates across all 16 categories', () {
      expect(catalog.totalCount, equals(200));
      expect(catalog.allTemplates.length, equals(200));
    });

    test('every template has a strictly unique ID with zero duplicates', () {
      final ids = <String>{};
      for (final template in catalog.allTemplates) {
        expect(ids.contains(template.id), isFalse, reason: 'Duplicate template ID found: ${template.id}');
        ids.add(template.id);
      }
      expect(ids.length, equals(200));
    });

    test('every template has a strictly unique Title with zero duplicates and no repeated numbers', () {
      final titles = <String>{};
      for (final template in catalog.allTemplates) {
        expect(titles.contains(template.title), isFalse, reason: 'Duplicate template title found: ${template.title}');
        expect(template.title.contains('#'), isFalse, reason: 'Template title contains artificial number suffix: ${template.title}');
        titles.add(template.title);
      }
      expect(titles.length, equals(200));
    });

    test('categories have expected counts (kids: 28, birds: 18, flowers: 18, characters: 16, others: 10)', () {
      expect(TemplateCategory.values.length, equals(16));
      for (final category in TemplateCategory.values) {
        final categoryTemplates = catalog.filter(categoryLabel: category.label);
        final expectedCount = switch (category) {
          TemplateCategory.kids => 28,
          TemplateCategory.birds => 18,
          TemplateCategory.flowers => 18,
          TemplateCategory.characters => 16,
          _ => 10,
        };
        expect(categoryTemplates.length, equals(expectedCount),
            reason: 'Category ${category.label} should have exactly $expectedCount distinct designs');
      }
    });

    test('every template generates valid non-empty vector strokes with proper bounds', () {
      for (final template in catalog.allTemplates) {
        final strokes = template.strokeGenerator(1000, 1000);
        expect(strokes.isNotEmpty, isTrue, reason: 'Template ${template.title} produced empty strokes');
        for (final stroke in strokes) {
          expect(stroke.points.isNotEmpty, isTrue, reason: 'Stroke in ${template.title} has no points');
          for (final point in stroke.points) {
            expect(point.x.isFinite, isTrue);
            expect(point.y.isFinite, isTrue);
          }
        }
      }
    });

    test('filter by query accurately matches unique titles', () {
      final lotusResults = catalog.filter(query: 'Lotus');
      expect(lotusResults.isNotEmpty, isTrue);
      expect(lotusResults.any((t) => t.title.contains('Lotus')), isTrue);

      final flamingoResults = catalog.filter(query: 'Flamingo');
      expect(flamingoResults.length, equals(1));
      expect(flamingoResults.first.title, equals('Elegant Pink Flamingo'));

      final sunflowerResults = catalog.filter(query: 'Giant Golden Sunflower');
      expect(sunflowerResults.length, equals(1));
      expect(sunflowerResults.first.title, equals('Giant Golden Sunflower'));

      final puppyResults = catalog.filter(query: 'Puppy');
      expect(puppyResults.length, equals(1));
      expect(puppyResults.first.title, equals('Cute Playful Puppy'));
    });

    test('filter by difficulty returns matching subsets', () {
      final easy = catalog.filter(difficulty: 'Easy');
      final medium = catalog.filter(difficulty: 'Medium');
      final detailed = catalog.filter(difficulty: 'Detailed');

      expect(easy.isNotEmpty, isTrue);
      expect(medium.isNotEmpty, isTrue);
      expect(detailed.isNotEmpty, isTrue);
      expect(easy.length + medium.length + detailed.length, equals(200));
    });

    test('getRandomTemplate returns a valid template from the catalog', () {
      final random = catalog.getRandomTemplate();
      expect(random.id.isNotEmpty, isTrue);
      expect(random.title.isNotEmpty, isTrue);
      expect(catalog.allTemplates.any((t) => t.id == random.id), isTrue);
    });

    test('favorites management tracks and filters user bookmarked templates', () {
      final initialFavCount = catalog.favoriteIds.length;
      expect(initialFavCount, greaterThan(0));

      final nonFav = catalog.allTemplates.firstWhere((t) => !catalog.isFavorite(t.id));
      expect(catalog.isFavorite(nonFav.id), isFalse);

      catalog.toggleFavorite(nonFav.id);
      expect(catalog.isFavorite(nonFav.id), isTrue);
      expect(catalog.favoriteIds.contains(nonFav.id), isTrue);
      expect(catalog.filter(onlyFavorites: true).length, equals(initialFavCount + 1));

      catalog.toggleFavorite(nonFav.id);
      expect(catalog.isFavorite(nonFav.id), isFalse);
      expect(catalog.filter(onlyFavorites: true).length, equals(initialFavCount));
    });

    test('TemplateThumbnailWidget compiled path cache produces valid cached paths', () {
      final template = catalog.allTemplates.first;
      final path1 = TemplateThumbnailWidget.getCompiledPath(template);
      final path2 = TemplateThumbnailWidget.getCompiledPath(template);
      expect(identical(path1, path2), isTrue);
      expect(path1.getBounds().isEmpty, isFalse);
    });

    test('template outer framing double border cleanly encloses design without cutting', () {
      final strokes = TemplateProceduralGenerator.generate(42, TemplateCategory.mandala, 1000, 1000);
      expect(strokes.length, greaterThanOrEqualTo(2));
      final outerFrame = strokes[0];
      final innerFrame = strokes[1];

      final xValues = outerFrame.points.map((p) => p.x).toList();
      final minX = xValues.reduce((a, b) => a < b ? a : b);
      final maxX = xValues.reduce((a, b) => a > b ? a : b);
      expect(maxX - minX, closeTo(940, 2));

      final innerX = innerFrame.points.map((p) => p.x).toList();
      final innerMinX = innerX.reduce((a, b) => a < b ? a : b);
      final innerMaxX = innerX.reduce((a, b) => a > b ? a : b);
      expect(innerMaxX - innerMinX, closeTo(910, 2));
    });
  });
}
