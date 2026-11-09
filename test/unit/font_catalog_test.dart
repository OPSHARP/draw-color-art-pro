import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:draw_color_art_pro/features/text/models/font_item.dart';
import 'package:draw_color_art_pro/features/text/services/font_catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('100+ Fonts Typography Catalog Tests', () {
    final catalog = FontCatalogService.instance;

    test('catalog contains 100+ curated Google Fonts', () {
      expect(catalog.totalCount, greaterThanOrEqualTo(100));
      expect(catalog.allFonts.length, greaterThanOrEqualTo(100));
    });

    test('catalog contains fonts across all typography categories', () {
      final categories = [
        FontCategory.sansSerif,
        FontCategory.serif,
        FontCategory.script,
        FontCategory.display,
        FontCategory.futuristic,
        FontCategory.vintage,
        FontCategory.monospace,
      ];

      for (final cat in categories) {
        final fontsInCat = catalog.filter(category: cat);
        expect(
          fontsInCat.isNotEmpty,
          isTrue,
          reason: 'Category ${cat.label} should have fonts',
        );
      }
    });

    test('font search filters correctly by name', () {
      final robotoResults = catalog.filter(query: 'roboto');
      expect(robotoResults.isNotEmpty, isTrue);
      expect(robotoResults.any((f) => f.name.toLowerCase().contains('roboto')), isTrue);

      final playfairResults = catalog.filter(query: 'playfair');
      expect(playfairResults.isNotEmpty, isTrue);
      expect(playfairResults.first.name, contains('Playfair'));

      final orbitronResults = catalog.filter(query: 'orbitron');
      expect(orbitronResults.isNotEmpty, isTrue);
      expect(orbitronResults.first.name, equals('Orbitron'));
    });

    test('applyStyle creates valid TextStyle with custom weight and size', () {
      final font = catalog.defaultFont;
      const base = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue);
      final styled = font.applyStyle(base);

      expect(styled.fontSize, equals(24));
      expect(styled.fontWeight, equals(FontWeight.bold));
      expect(styled.color, equals(Colors.blue));
    });
  });
}
