import 'package:flutter/material.dart';

/// Preset paper textures rendered procedurally onto the canvas.
enum CanvasPaperTexture {
  none('Clean Canvas', Icons.crop_square_rounded),
  watercolor('Cold-Press Watercolor', Icons.water_drop_rounded),
  parchment('Vintage Parchment', Icons.auto_stories_rounded),
  blueprint('Blueprint Grid', Icons.grid_4x4_rounded),
  darkSketchbook('Charcoal Sketchbook', Icons.dark_mode_rounded);

  const CanvasPaperTexture(this.label, this.icon);
  final String label;
  final IconData icon;

  /// Background tint associated with the paper texture.
  Color get baseTint => switch (this) {
    CanvasPaperTexture.none => Colors.white,
    CanvasPaperTexture.watercolor => const Color(0xFFFAF7F0),
    CanvasPaperTexture.parchment => const Color(0xFFF4EAD4),
    CanvasPaperTexture.blueprint => const Color(0xFF0D3B66),
    CanvasPaperTexture.darkSketchbook => const Color(0xFF1E2124),
  };
}
