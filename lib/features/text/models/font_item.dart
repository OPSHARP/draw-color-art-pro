import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Categories of typography fonts available for styling.
enum FontCategory {
  all('All'),
  sansSerif('Modern Sans'),
  serif('Serif & Editorial'),
  script('Script & Hand'),
  display('Display & Bold'),
  futuristic('Sci-Fi & Tech'),
  vintage('Vintage & Gothic'),
  monospace('Monospace');

  const FontCategory(this.label);
  final String label;
}

/// Metadata and TextStyle builder for a single font.
class FontItem {
  const FontItem({
    required this.name,
    required this.category,
    required this.builder,
    this.popular = false,
  });

  final String name;
  final FontCategory category;
  final TextStyle Function({TextStyle? textStyle}) builder;
  final bool popular;

  TextStyle applyStyle(TextStyle base) {
    try {
      if (!GoogleFonts.config.allowRuntimeFetching) {
        return base.copyWith(fontFamily: name);
      }
      return builder(textStyle: base);
    } catch (_) {
      return base.copyWith(fontFamily: name);
    }
  }
}
