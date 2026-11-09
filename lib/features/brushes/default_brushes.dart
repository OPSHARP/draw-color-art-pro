import '../canvas/models/stroke.dart';

/// Built-in brush presets for Phase 1 brush library.
///
/// Organized by category per the PRD: Basic, Sketching, Ink, Painting.
class DefaultBrushes {
  DefaultBrushes._();

  // ── Basic ───────────────────────────────────────────────────────

  static final pencil = BrushPreset(
    id: 'pencil',
    name: 'Pencil',
    category: BrushCategory.basic,
    size: 4.0,
    opacity: 0.85,
    flow: 0.9,
    hardness: 0.7,
    spacing: 0.08,
  );

  static final softBrush = BrushPreset(
    id: 'soft_brush',
    name: 'Soft Brush',
    category: BrushCategory.basic,
    size: 20.0,
    opacity: 0.8,
    flow: 0.7,
    hardness: 0.2,
    spacing: 0.12,
  );

  static final hardBrush = BrushPreset(
    id: 'hard_brush',
    name: 'Hard Brush',
    category: BrushCategory.basic,
    size: 12.0,
    opacity: 1.0,
    flow: 1.0,
    hardness: 0.95,
    spacing: 0.1,
  );

  static final eraser = BrushPreset(
    id: 'eraser',
    name: 'Eraser',
    category: BrushCategory.basic,
    size: 20.0,
    opacity: 1.0,
    flow: 1.0,
    hardness: 0.5,
    spacing: 0.1,
    isEraser: true,
  );

  // ── Sketching ───────────────────────────────────────────────────

  static final finePencil = BrushPreset(
    id: 'fine_pencil',
    name: 'Fine Pencil',
    category: BrushCategory.sketching,
    size: 2.0,
    opacity: 0.75,
    flow: 0.85,
    hardness: 0.85,
    spacing: 0.06,
  );

  static final charcoal = BrushPreset(
    id: 'charcoal',
    name: 'Charcoal',
    category: BrushCategory.sketching,
    size: 16.0,
    opacity: 0.7,
    flow: 0.6,
    hardness: 0.3,
    spacing: 0.08,
    scatter: 0.1,
    jitter: 0.05,
  );

  static final chalk = BrushPreset(
    id: 'chalk',
    name: 'Chalk',
    category: BrushCategory.sketching,
    size: 14.0,
    opacity: 0.65,
    flow: 0.5,
    hardness: 0.4,
    spacing: 0.1,
    scatter: 0.08,
  );

  // ── Ink ─────────────────────────────────────────────────────────

  static final ink = BrushPreset(
    id: 'ink',
    name: 'Ink',
    category: BrushCategory.ink,
    size: 6.0,
    opacity: 1.0,
    flow: 1.0,
    hardness: 1.0,
    spacing: 0.05,
    stabilization: StabilizationMode.smooth,
  );

  static final ballpoint = BrushPreset(
    id: 'ballpoint',
    name: 'Ballpoint',
    category: BrushCategory.ink,
    size: 3.0,
    opacity: 0.9,
    flow: 0.95,
    hardness: 0.9,
    spacing: 0.06,
  );

  static final brushPen = BrushPreset(
    id: 'brush_pen',
    name: 'Brush Pen',
    category: BrushCategory.ink,
    size: 8.0,
    opacity: 1.0,
    flow: 1.0,
    hardness: 0.85,
    spacing: 0.07,
    stabilization: StabilizationMode.smooth,
  );

  // ── Painting ────────────────────────────────────────────────────

  static final marker = BrushPreset(
    id: 'marker',
    name: 'Marker',
    category: BrushCategory.painting,
    size: 24.0,
    opacity: 0.85,
    flow: 0.9,
    hardness: 0.6,
    spacing: 0.1,
  );

  static final airbrush = BrushPreset(
    id: 'airbrush',
    name: 'Airbrush',
    category: BrushCategory.painting,
    size: 40.0,
    opacity: 0.35,
    flow: 0.45,
    hardness: 0.1,
    spacing: 0.06,
    isSpray: true,
  );

  static final glow = BrushPreset(
    id: 'glow_neon',
    name: 'Glow Neon',
    category: BrushCategory.effects,
    size: 16.0,
    opacity: 1.0,
    flow: 1.0,
    hardness: 0.85,
    spacing: 0.08,
    isGlow: true,
  );

  static final flatBrush = BrushPreset(
    id: 'flat_brush',
    name: 'Flat Brush',
    category: BrushCategory.painting,
    size: 30.0,
    opacity: 0.9,
    flow: 0.8,
    hardness: 0.5,
    spacing: 0.15,
  );

  // ── New Pro Tools ───────────────────────────────────────────────

  static final calligraphy = BrushPreset(
    id: 'calligraphy',
    name: 'Calligraphy',
    category: BrushCategory.ink,
    size: 8.0,
    opacity: 1.0,
    flow: 1.0,
    hardness: 1.0,
    spacing: 0.04,
    stabilization: StabilizationMode.smooth,
    isCalligraphy: true,
  );

  static final crayon = BrushPreset(
    id: 'crayon',
    name: 'Crayon',
    category: BrushCategory.sketching,
    size: 18.0,
    opacity: 0.75,
    flow: 0.6,
    hardness: 0.4,
    spacing: 0.06,
    scatter: 0.15,
    jitter: 0.1,
    isCrayon: true,
  );

  static final dottedPen = BrushPreset(
    id: 'dotted_pen',
    name: 'Dotted Pen',
    category: BrushCategory.effects,
    size: 6.0,
    opacity: 1.0,
    flow: 1.0,
    hardness: 1.0,
    spacing: 0.5,
    isDotted: true,
  );

  static final patternStamp = BrushPreset(
    id: 'pattern_stamp',
    name: 'Pattern Stamp',
    category: BrushCategory.effects,
    size: 20.0,
    opacity: 0.9,
    flow: 1.0,
    hardness: 1.0,
    spacing: 0.4,
    isPatternStamp: true,
  );

  static final pixelBrush = BrushPreset(
    id: 'pixel_brush',
    name: 'Pixel Brush',
    category: BrushCategory.pixel,
    size: 8.0,
    opacity: 1.0,
    flow: 1.0,
    hardness: 1.0,
    spacing: 0.0,
    isPixel: true,
  );

  static final highlighter = BrushPreset(
    id: 'highlighter',
    name: 'Highlighter',
    category: BrushCategory.coloring,
    size: 24.0,
    opacity: 0.55,
    flow: 0.9,
    hardness: 0.9,
    spacing: 0.05,
    isHighlighter: true,
  );

  static final rainbowBrush = BrushPreset(
    id: 'rainbow_brush',
    name: 'Rainbow Brush',
    category: BrushCategory.effects,
    size: 14.0,
    opacity: 1.0,
    flow: 1.0,
    hardness: 0.85,
    spacing: 0.06,
    stabilization: StabilizationMode.smooth,
    isRainbow: true,
  );

  /// All built-in brushes.
  static List<BrushPreset> get all => [
    pencil,
    softBrush,
    hardBrush,
    eraser,
    finePencil,
    charcoal,
    chalk,
    ink,
    ballpoint,
    brushPen,
    marker,
    airbrush,
    glow,
    flatBrush,
    calligraphy,
    crayon,
    dottedPen,
    patternStamp,
    pixelBrush,
    highlighter,
    rainbowBrush,
  ];

  /// Brushes by category.
  static Map<BrushCategory, List<BrushPreset>> get byCategory {
    final map = <BrushCategory, List<BrushPreset>>{};
    for (final brush in all) {
      map.putIfAbsent(brush.category, () => []).add(brush);
    }
    return map;
  }
}
