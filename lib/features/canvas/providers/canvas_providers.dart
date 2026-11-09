import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/canvas_document.dart';
import '../models/stroke.dart';
import '../models/tools.dart';
import '../models/symmetry.dart';
import '../models/paper_texture.dart';
import '../../brushes/default_brushes.dart';
import '../../../core/constants/design_tokens.dart';
export '../widgets/drawing_guides_modal.dart' show drawingGuideProvider;


// ─────────────────────────────────────────────────────────────────────────────
// Canvas Document State
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the canvas document state (layers, strokes, metadata).
class CanvasDocumentNotifier extends StateNotifier<CanvasDocument> {
  CanvasDocumentNotifier()
    : super(
        CanvasDocument(
          name: 'Untitled',
          width: CanvasDefaults.defaultWidth,
          height: CanvasDefaults.defaultHeight,
        ),
      );

  /// Initialize with a specific document.
  void loadDocument(CanvasDocument doc) {
    state = doc;
  }

  /// Create a new blank document.
  void createNew({
    required String name,
    required int width,
    required int height,
    Color backgroundColor = const Color(0xFFFFFFFF),
    bool transparent = false,
    bool isThumbnail = false,
  }) {
    state = CanvasDocument(
      name: name,
      width: width,
      height: height,
      backgroundColor: backgroundColor,
      isTransparentBackground: transparent,
      isThumbnail: isThumbnail,
      layers: [LayerModel(name: 'Layer 1')],
      activeLayerIndex: 0,
    );
  }

  /// Rename the document.
  void rename(String name) {
    state = state.copyWith(name: name);
  }

  /// Set the canvas background color or transparency mode.
  void setBackgroundColor(Color color, {bool transparent = false}) {
    state = state.copyWith(
      backgroundColor: color,
      isTransparentBackground: transparent,
    );
  }

  // ── Layer Operations ────────────────────────────────────────────

  /// Add a new layer above the active layer.
  void addLayer({String? name, LayerType type = LayerType.paint}) {
    final layers = List<LayerModel>.from(state.layers);
    final newIndex = state.activeLayerIndex + 1;
    final layerName = name ?? 'Layer ${layers.length + 1}';
    layers.insert(newIndex, LayerModel(name: layerName, type: type));
    state = state.copyWith(layers: layers, activeLayerIndex: newIndex);
  }

  /// Insert an entire layer at a specific index or above the active layer.
  void insertLayer(LayerModel layer, {int? atIndex}) {
    final layers = List<LayerModel>.from(state.layers);
    final targetIndex = atIndex ?? (state.activeLayerIndex + 1);
    final clampedIndex = targetIndex.clamp(0, layers.length);
    layers.insert(clampedIndex, layer);
    state = state.copyWith(layers: layers, activeLayerIndex: clampedIndex);
  }

  /// Delete the layer at the given index.
  void deleteLayer(int index) {
    if (state.layers.length <= 1) return; // Keep at least one layer
    final layers = List<LayerModel>.from(state.layers)..removeAt(index);
    final newActive = index >= layers.length ? layers.length - 1 : index;
    state = state.copyWith(layers: layers, activeLayerIndex: newActive);
  }

  /// Duplicate the layer at the given index.
  void duplicateLayer(int index) {
    final layers = List<LayerModel>.from(state.layers);
    final original = layers[index];
    final copy = original.copyWith(
      name: '${original.name} Copy',
    );
    // Need a fresh ID
    final newLayer = LayerModel(
      name: copy.name,
      type: copy.type,
      opacity: copy.opacity,
      blendMode: copy.blendMode,
      isVisible: copy.isVisible,
      strokes: List.from(copy.strokes),
    );
    layers.insert(index + 1, newLayer);
    state = state.copyWith(layers: layers, activeLayerIndex: index + 1);
  }

  /// Toggle visibility of a layer.
  void toggleLayerVisibility(int index) {
    final layers = List<LayerModel>.from(state.layers);
    layers[index] = layers[index].copyWith(
      isVisible: !layers[index].isVisible,
    );
    state = state.copyWith(layers: layers);
  }

  /// Toggle lock of a layer.
  void toggleLayerLock(int index) {
    final layers = List<LayerModel>.from(state.layers);
    layers[index] = layers[index].copyWith(
      isLocked: !layers[index].isLocked,
    );
    state = state.copyWith(layers: layers);
  }

  /// Toggle alpha lock for a layer (locks transparency boundary).
  void toggleLayerAlphaLock(int index) {
    if (index < 0 || index >= state.layers.length) return;
    final layers = List<LayerModel>.from(state.layers);
    layers[index] = layers[index].copyWith(
      isAlphaLocked: !layers[index].isAlphaLocked,
    );
    state = state.copyWith(layers: layers);
  }

  /// Toggle clipping mask for a layer (clips to layer below).
  void toggleLayerClipping(int index) {
    if (index <= 0 || index >= state.layers.length) return;
    final layers = List<LayerModel>.from(state.layers);
    layers[index] = layers[index].copyWith(
      isClipping: !layers[index].isClipping,
    );
    state = state.copyWith(layers: layers);
  }

  /// Set the active layer index.
  void setActiveLayer(int index) {
    if (index >= 0 && index < state.layers.length) {
      state = state.copyWith(activeLayerIndex: index);
    }
  }

  /// Set layer opacity.
  void setLayerOpacity(int index, double opacity) {
    final layers = List<LayerModel>.from(state.layers);
    layers[index] = layers[index].copyWith(opacity: opacity.clamp(0.0, 1.0));
    state = state.copyWith(layers: layers);
  }

  /// Set layer blend mode.
  void setLayerBlendMode(int index, DrawBlendMode mode) {
    final layers = List<LayerModel>.from(state.layers);
    layers[index] = layers[index].copyWith(blendMode: mode);
    state = state.copyWith(layers: layers);
  }

  /// Rename a layer.
  void renameLayer(int index, String name) {
    final layers = List<LayerModel>.from(state.layers);
    layers[index] = layers[index].copyWith(name: name);
    state = state.copyWith(layers: layers);
  }

  /// Reorder layers (move from oldIndex to newIndex).
  void reorderLayers(int oldIndex, int newIndex) {
    final layers = List<LayerModel>.from(state.layers);
    final layer = layers.removeAt(oldIndex);
    layers.insert(newIndex, layer);
    // Track the active layer
    int activeIndex = state.activeLayerIndex;
    if (oldIndex == activeIndex) {
      activeIndex = newIndex;
    } else if (oldIndex < activeIndex && newIndex >= activeIndex) {
      activeIndex--;
    } else if (oldIndex > activeIndex && newIndex <= activeIndex) {
      activeIndex++;
    }
    state = state.copyWith(layers: layers, activeLayerIndex: activeIndex);
  }

  /// Merge the given layer down into the layer below it.
  void mergeDown(int index) {
    if (index <= 0 || index >= state.layers.length) return;
    final layers = List<LayerModel>.from(state.layers);
    final upper = layers[index];
    final lower = layers[index - 1];
    final merged = lower.copyWith(
      strokes: [...lower.strokes, ...upper.strokes],
    );
    layers[index - 1] = merged;
    layers.removeAt(index);
    state = state.copyWith(
      layers: layers,
      activeLayerIndex: (index - 1).clamp(0, layers.length - 1),
    );
  }

  /// Flatten all layers into one.
  void flattenAll() {
    if (state.layers.length <= 1) return;
    final allStrokes =
        state.layers.expand((l) => l.strokes).toList();
    final flattened = LayerModel(name: 'Background', strokes: allStrokes);
    state = state.copyWith(layers: [flattened], activeLayerIndex: 0);
  }

  /// Flatten only visible layers into one, keeping hidden layers intact.
  void flattenVisible() {
    final layers = List<LayerModel>.from(state.layers);
    final visible = layers.where((l) => l.isVisible).toList();
    final hidden = layers.where((l) => !l.isVisible).toList();
    if (visible.length <= 1) return;

    final mergedStrokes = visible.expand((l) => l.strokes).toList();
    final mergedLayer = LayerModel(
      name: 'Merged',
      strokes: mergedStrokes,
    );
    final newLayers = [...hidden, mergedLayer];
    state = state.copyWith(
      layers: newLayers,
      activeLayerIndex: newLayers.length - 1,
    );
  }

  /// Group layers at the given indices under a named group.
  void groupLayers(List<int> indices, String groupName) {
    if (indices.length < 2) return;
    final sortedIndices = List<int>.from(indices)..sort();
    final layers = List<LayerModel>.from(state.layers);

    // Create the group layer
    final groupLayer = LayerModel(
      name: groupName,
      type: LayerType.group,
    );
    final groupId = groupLayer.id;

    // Update child layers with parentGroupId
    for (final idx in sortedIndices) {
      if (idx >= 0 && idx < layers.length) {
        layers[idx] = layers[idx].copyWith(parentGroupId: groupId);
      }
    }

    // Insert group above the topmost grouped layer
    final insertAt = sortedIndices.last + 1;
    layers.insert(insertAt.clamp(0, layers.length), groupLayer);
    state = state.copyWith(layers: layers, activeLayerIndex: insertAt);
  }

  /// Ungroup layers belonging to the given group ID.
  void ungroupLayers(String groupId) {
    final layers = List<LayerModel>.from(state.layers);

    // Remove the group layer
    layers.removeWhere((l) => l.id == groupId && l.type == LayerType.group);

    // Clear parentGroupId from child layers
    for (int i = 0; i < layers.length; i++) {
      if (layers[i].parentGroupId == groupId) {
        layers[i] = layers[i].copyWith(clearParentGroupId: true);
      }
    }

    state = state.copyWith(
      layers: layers,
      activeLayerIndex: state.activeLayerIndex.clamp(0, layers.length - 1),
    );
  }

  // ── Stroke Operations ───────────────────────────────────────────

  /// Add a completed stroke to the active layer.
  void addStroke(Stroke stroke) {
    final layers = List<LayerModel>.from(state.layers);
    final activeIndex = state.activeLayerIndex;
    if (activeIndex >= layers.length) return;
    final layer = layers[activeIndex];
    if (layer.isLocked) return;
    layers[activeIndex] = layer.copyWith(
      strokes: [...layer.strokes, stroke],
    );
    state = state.copyWith(layers: layers);
  }

  /// Update all strokes on the active layer (for transform/selection/move).
  void updateActiveLayerStrokes(List<Stroke> newStrokes) {
    final layers = List<LayerModel>.from(state.layers);
    final activeIndex = state.activeLayerIndex;
    if (activeIndex >= layers.length) return;
    final layer = layers[activeIndex];
    if (layer.isLocked) return;
    layers[activeIndex] = layer.copyWith(strokes: newStrokes);
    state = state.copyWith(layers: layers);
  }

  /// Remove the last stroke from the active layer (for undo).
  Stroke? removeLastStroke() {
    final layers = List<LayerModel>.from(state.layers);
    final activeIndex = state.activeLayerIndex;
    if (activeIndex >= layers.length) return null;
    final layer = layers[activeIndex];
    if (layer.strokes.isEmpty) return null;
    final strokes = List<Stroke>.from(layer.strokes);
    final removed = strokes.removeLast();
    layers[activeIndex] = layer.copyWith(strokes: strokes);
    state = state.copyWith(layers: layers);
    return removed;
  }

  /// Remove a stroke by its ID from the active layer.
  void removeStroke(String strokeId) {
    final layers = List<LayerModel>.from(state.layers);
    final activeIndex = state.activeLayerIndex;
    if (activeIndex >= layers.length) return;
    final layer = layers[activeIndex];
    final strokes = layer.strokes.where((s) => s.id != strokeId).toList();
    layers[activeIndex] = layer.copyWith(strokes: strokes);
    state = state.copyWith(layers: layers);
  }

  /// Update a single stroke on the active layer (for text editing, color/font updates).
  void updateStroke(Stroke updated) {
    final layers = List<LayerModel>.from(state.layers);
    final activeIndex = state.activeLayerIndex;
    if (activeIndex >= layers.length) return;
    final layer = layers[activeIndex];
    if (layer.isLocked) return;
    final updatedStrokes = layer.strokes.map((s) => s.id == updated.id ? updated : s).toList();
    layers[activeIndex] = layer.copyWith(strokes: updatedStrokes);
    state = state.copyWith(layers: layers);
  }

  /// Clear all strokes from the active layer.
  void clearActiveLayer() {
    final layers = List<LayerModel>.from(state.layers);
    final activeIndex = state.activeLayerIndex;
    if (activeIndex >= layers.length) return;
    final layer = layers[activeIndex];
    layers[activeIndex] = layer.copyWith(strokes: []);
    state = state.copyWith(layers: layers);
  }

  /// Flip all strokes in the active layer horizontally.
  void flipActiveLayerHorizontal() {
    final active = state.activeLayer;
    if (active == null || active.isLocked) return;
    final w = state.width.toDouble();
    final flipped = active.strokes.map((s) {
      final flippedPts = s.points.map((p) => p.copyWith(x: w - p.x)).toList();
      return s.copyWith(points: flippedPts);
    }).toList();
    updateActiveLayerStrokes(flipped);
  }
}

final canvasDocumentProvider =
    StateNotifierProvider<CanvasDocumentNotifier, CanvasDocument>((ref) {
      return CanvasDocumentNotifier();
    });

/// ID of the currently selected text stroke on the active layer.
final selectedTextStrokeIdProvider = StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Active Tool State
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the currently selected drawing tool and automatically configures
/// corresponding brush presets, hardness, opacity, and blend modes.
class ActiveToolNotifier extends StateNotifier<DrawingTool> {
  ActiveToolNotifier(this.ref) : super(DrawingTool.brush);
  final Ref ref;

  @override
  set state(DrawingTool value) {
    super.state = value;
    if (value != DrawingTool.text) {
      ref.read(selectedTextStrokeIdProvider.notifier).state = null;
    }
  }

  void selectTool(DrawingTool tool) {
    state = tool;

    final brushNotifier = ref.read(activeBrushProvider.notifier);
    switch (tool) {
      case DrawingTool.brush:
        brushNotifier.selectBrush(DefaultBrushes.softBrush.copyWith(
          size: 16.0,
          opacity: 0.85,
          hardness: 0.35,
        ));
        break;

      case DrawingTool.pencil:
        brushNotifier.selectBrush(DefaultBrushes.pencil.copyWith(
          size: 3.5,
          opacity: 0.85,
          hardness: 0.85,
        ));
        break;

      case DrawingTool.pen:
        brushNotifier.selectBrush(DefaultBrushes.ink.copyWith(
          size: 4.5,
          opacity: 1.0,
          hardness: 1.0,
          stabilization: StabilizationMode.smooth,
        ));
        break;

      case DrawingTool.marker:
        brushNotifier.selectBrush(DefaultBrushes.marker.copyWith(
          size: 26.0,
          opacity: 0.5,
          hardness: 0.9,
        ));
        break;

      case DrawingTool.eraser:
        brushNotifier.selectBrush(DefaultBrushes.eraser.copyWith(
          size: 24.0,
          isEraser: true,
        ));
        break;

      case DrawingTool.glow:
        brushNotifier.selectBrush(DefaultBrushes.glow.copyWith(
          size: 16.0,
          opacity: 1.0,
          hardness: 0.85,
          isGlow: true,
        ));
        break;

      case DrawingTool.spray:
        brushNotifier.selectBrush(DefaultBrushes.airbrush.copyWith(
          size: 36.0,
          opacity: 0.4,
          hardness: 0.1,
          isSpray: true,
        ));
        break;

      case DrawingTool.symmetry:
        final sym = ref.read(symmetryProvider);
        if (!sym.isEnabled) {
          ref.read(symmetryProvider.notifier).state = sym.copyWith(mode: SymmetryMode.vertical);
        }
        break;

      case DrawingTool.ruler:
        final rMode = ref.read(rulerGuideModeProvider);
        if (rMode == RulerGuideMode.off) {
          ref.read(rulerGuideModeProvider.notifier).state = RulerGuideMode.straight;
        }
        break;

      case DrawingTool.smudge:
        brushNotifier.selectBrush(DefaultBrushes.softBrush.copyWith(
          size: 28.0,
          opacity: 0.5,
          hardness: 0.2,
          isSmudge: true,
          isBlur: false,
        ));
        break;

      case DrawingTool.blur:
        brushNotifier.selectBrush(DefaultBrushes.softBrush.copyWith(
          size: 32.0,
          opacity: 0.35,
          hardness: 0.05,
          isBlur: true,
          isSmudge: false,
        ));
        break;

      case DrawingTool.fill:
      case DrawingTool.eyedropper:
      case DrawingTool.selection:
      case DrawingTool.transform:
      case DrawingTool.shape:
        break;

      case DrawingTool.calligraphy:
        brushNotifier.selectBrush(DefaultBrushes.calligraphy.copyWith(
          size: 8.0,
          opacity: 1.0,
          hardness: 1.0,
          isCalligraphy: true,
        ));
        break;

      case DrawingTool.crayon:
        brushNotifier.selectBrush(DefaultBrushes.crayon.copyWith(
          size: 18.0,
          opacity: 0.75,
          hardness: 0.4,
          isCrayon: true,
        ));
        break;

      case DrawingTool.dotted:
        brushNotifier.selectBrush(DefaultBrushes.dottedPen.copyWith(
          size: 6.0,
          opacity: 1.0,
          hardness: 1.0,
          isDotted: true,
        ));
        break;

      case DrawingTool.patternStamp:
        brushNotifier.selectBrush(DefaultBrushes.patternStamp.copyWith(
          size: 20.0,
          opacity: 0.9,
          isPatternStamp: true,
        ));
        break;

      case DrawingTool.pixel:
        brushNotifier.selectBrush(DefaultBrushes.pixelBrush.copyWith(
          size: ref.read(pixelGridSizeProvider),
          opacity: 1.0,
          hardness: 1.0,
          isPixel: true,
        ));
        break;

      case DrawingTool.highlighter:
        brushNotifier.selectBrush(DefaultBrushes.highlighter.copyWith(
          size: 24.0,
          opacity: 0.55,
          hardness: 0.9,
          isHighlighter: true,
        ));
        break;

      case DrawingTool.rainbow:
        brushNotifier.selectBrush(DefaultBrushes.rainbowBrush.copyWith(
          size: 14.0,
          opacity: 1.0,
          isRainbow: true,
        ));
        break;

      case DrawingTool.gradient:
        break;

      default:
        break;
    }
  }
}

final activeToolProvider =
    StateNotifierProvider<ActiveToolNotifier, DrawingTool>((ref) {
      return ActiveToolNotifier(ref);
    });

/// Shape tool state: active geometric shape type.
final activeShapeProvider = StateProvider<ShapeType>((ref) => ShapeType.rectangle);

/// Shape tool state: whether shape is filled or outline.
final isShapeFilledProvider = StateProvider<bool>((ref) => false);

/// Eyedropper state: current sampled color during touch/hover.
final eyedropperColorProvider = StateProvider<Color?>((ref) => null);

/// Eyedropper state: current sampled coordinate during touch/hover.
final eyedropperPositionProvider = StateProvider<Offset?>((ref) => null);

/// Fill tool tolerance (0..100)
final fillToleranceProvider = StateProvider<int>((ref) => 35);

/// Ruler precision guide modes.
enum RulerGuideMode {
  off('Off'),
  straight('Straight Snap'),
  angle45('Angle 45°'),
  isometric('Isometric 30°'),
  grid('Grid Guide');

  const RulerGuideMode(this.label);
  final String label;
}

final rulerGuideModeProvider = StateProvider<RulerGuideMode>((ref) => RulerGuideMode.straight);

/// Pattern stamp type selector for the stamp tool.
final patternStampTypeProvider = StateProvider<PatternStampType>(
  (ref) => PatternStampType.star,
);

/// Pixel grid size for the pixel brush tool.
final pixelGridSizeProvider = StateProvider<double>((ref) => 8.0);

/// Quick Palette Theme Presets for coloring and drawing.
enum QuickPaletteTheme {
  classic('Classic'),
  pastel('Pastel'),
  neon('Neon'),
  earth('Earth & Skin'),
  manga('Manga'),
  watercolor('Watercolor');

  const QuickPaletteTheme(this.label);
  final String label;

  List<Color> get colors => switch (this) {
    QuickPaletteTheme.classic => const [
      Color(0xFF000000),
      Color(0xFFFFFFFF),
      Color(0xFFFF3B30),
      Color(0xFF007AFF),
      Color(0xFF34C759),
      Color(0xFFFF9500),
      Color(0xFFAF52DE),
      Color(0xFFFF2D55),
    ],
    QuickPaletteTheme.pastel => const [
      Color(0xFFFFB3BA),
      Color(0xFFFFDFBA),
      Color(0xFFFFFFBA),
      Color(0xFFBAFFC9),
      Color(0xFFBAE1FF),
      Color(0xFFE8BAFF),
      Color(0xFFC4FAF8),
      Color(0xFFF3E5AB),
    ],
    QuickPaletteTheme.neon => const [
      Color(0xFF00F0FF),
      Color(0xFFFF007F),
      Color(0xFF39FF14),
      Color(0xFFFFEE00),
      Color(0xFFBF00FF),
      Color(0xFFFF5F00),
      Color(0xFF00FFA3),
      Color(0xFFFFFFFF),
    ],
    QuickPaletteTheme.earth => const [
      Color(0xFF3B2219),
      Color(0xFF6A381F),
      Color(0xFF9E5B32),
      Color(0xFFC68A4C),
      Color(0xFFE0AC69),
      Color(0xFFF1C27D),
      Color(0xFF556B2F),
      Color(0xFF8F9779),
    ],
    QuickPaletteTheme.manga => const [
      Color(0xFF2C3E50),
      Color(0xFFE74C3C),
      Color(0xFFF39C12),
      Color(0xFF27AE60),
      Color(0xFF2980B9),
      Color(0xFF8E44AD),
      Color(0xFFFF85A1),
      Color(0xFFFFFFFF),
    ],
    QuickPaletteTheme.watercolor => const [
      Color(0xFF1B4965),
      Color(0xFF62B6CB),
      Color(0xFF588157),
      Color(0xFFBC4749),
      Color(0xFFE76F51),
      Color(0xFFF4A261),
      Color(0xFFE9C46A),
      Color(0xFF2B2D42),
    ],
  };

  QuickPaletteTheme get nextTheme {
    final nextIndex = (index + 1) % QuickPaletteTheme.values.length;
    return QuickPaletteTheme.values[nextIndex];
  }
}

final quickPaletteThemeProvider = StateProvider<QuickPaletteTheme>(
  (ref) => QuickPaletteTheme.classic,
);

/// Gradient fill tool state: linear or radial.
final gradientTypeProvider = StateProvider<GradientType>(
  (ref) => GradientType.linear,
);

/// Gradient fill tool state: secondary accent color.
final gradientSecondaryColorProvider = StateProvider<Color>(
  (ref) => const Color(0xFF00F0FF),
);

/// Rainbow brush dynamic spectrum mode.
final rainbowModeProvider = StateProvider<RainbowMode>(
  (ref) => RainbowMode.spectrum,
);

/// Active marquee selection rectangle (in canvas coordinates).
final activeSelectionRectProvider = StateProvider<Rect?>((ref) => null);

// ─────────────────────────────────────────────────────────────────────────────
// Active Brush State
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the currently active brush and its settings.
class ActiveBrushNotifier extends StateNotifier<BrushPreset> {
  ActiveBrushNotifier()
    : super(
        BrushPreset(
          name: 'Brush',
          category: BrushCategory.basic,
          size: CanvasDefaults.defaultBrushSize,
        ),
      );

  void selectBrush(BrushPreset brush) {
    state = brush;
  }

  void setSize(double size) {
    state = state.copyWith(
      size: size.clamp(CanvasDefaults.minBrushSize, CanvasDefaults.maxBrushSize),
    );
  }

  void setOpacity(double opacity) {
    state = state.copyWith(opacity: opacity.clamp(0.0, 1.0));
  }

  void setFlow(double flow) {
    state = state.copyWith(flow: flow.clamp(0.0, 1.0));
  }

  void setHardness(double hardness) {
    state = state.copyWith(hardness: hardness.clamp(0.0, 1.0));
  }

  void setStabilization(StabilizationMode mode) {
    state = state.copyWith(stabilization: mode);
  }
}

final activeBrushProvider =
    StateNotifierProvider<ActiveBrushNotifier, BrushPreset>((ref) {
      return ActiveBrushNotifier();
    });

// ─────────────────────────────────────────────────────────────────────────────
// Active Color State
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the current drawing color and color history.
class ActiveColorNotifier extends StateNotifier<Color> {
  ActiveColorNotifier() : super(const Color(0xFF000000));

  final List<Color> _history = [];
  static const int _maxHistory = 20;

  List<Color> get history => List.unmodifiable(_history);

  void setColor(Color color) {
    if (state != color) {
      _history.remove(color);
      _history.insert(0, state);
      if (_history.length > _maxHistory) {
        _history.removeLast();
      }
    }
    state = color;
  }

  void addHistoryColor(Color color) {
    _history.remove(color);
    _history.insert(0, color);
    if (_history.length > _maxHistory) {
      _history.removeLast();
    }
  }
}

final activeColorProvider =
    StateNotifierProvider<ActiveColorNotifier, Color>((ref) {
      return ActiveColorNotifier();
    });

/// Exposes color history as a separate provider.
final colorHistoryProvider = Provider<List<Color>>((ref) {
  // Access the notifier to get history
  final notifier = ref.watch(activeColorProvider.notifier);
  // Re-read on color changes
  ref.watch(activeColorProvider);
  return notifier.history;
});

// ─────────────────────────────────────────────────────────────────────────────
// Canvas View State (zoom, pan, rotation)
// ─────────────────────────────────────────────────────────────────────────────

/// Canvas viewport state.
class CanvasViewState {
  const CanvasViewState({
    this.zoom = 1.0,
    this.panX = 0.0,
    this.panY = 0.0,
    this.rotation = 0.0,
  });

  final double zoom;
  final double panX;
  final double panY;
  final double rotation;

  CanvasViewState copyWith({
    double? zoom,
    double? panX,
    double? panY,
    double? rotation,
  }) {
    return CanvasViewState(
      zoom: zoom ?? this.zoom,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      rotation: rotation ?? this.rotation,
    );
  }

  /// Zoom percentage for display.
  int get zoomPercent => (zoom * 100).round();
}

/// Manages canvas viewport (zoom, pan, rotation).
class CanvasViewNotifier extends StateNotifier<CanvasViewState> {
  CanvasViewNotifier() : super(const CanvasViewState());

  void setZoom(double zoom) {
    state = state.copyWith(
      zoom: zoom.clamp(CanvasDefaults.minZoom, CanvasDefaults.maxZoom),
    );
  }

  void setViewport({
    required double zoom,
    required double panX,
    required double panY,
    double rotation = 0.0,
  }) {
    state = CanvasViewState(
      zoom: zoom.clamp(CanvasDefaults.minZoom, CanvasDefaults.maxZoom),
      panX: panX,
      panY: panY,
      rotation: rotation,
    );
  }

  void applyPinchTransform({
    required double newScale,
    required Offset focalPoint,
    required Offset focalDelta,
    double? newRotation,
  }) {
    final double clampedZoom = newScale.clamp(CanvasDefaults.minZoom, CanvasDefaults.maxZoom);
    final double currentZoom = state.zoom;
    if (currentZoom <= 0) return;

    final double zoomRatio = clampedZoom / currentZoom;
    final double oldPanX = state.panX;
    final double oldPanY = state.panY;

    final double newPanX = focalPoint.dx - (focalPoint.dx - oldPanX) * zoomRatio + focalDelta.dx;
    final double newPanY = focalPoint.dy - (focalPoint.dy - oldPanY) * zoomRatio + focalDelta.dy;

    state = state.copyWith(
      zoom: clampedZoom,
      panX: newPanX,
      panY: newPanY,
      rotation: newRotation ?? state.rotation,
    );
  }

  void zoomIn() {
    setZoom(state.zoom * 1.25);
  }

  void zoomOut() {
    setZoom(state.zoom / 1.25);
  }

  void setPan(double x, double y) {
    state = state.copyWith(panX: x, panY: y);
  }

  void addPan(double dx, double dy) {
    state = state.copyWith(
      panX: state.panX + dx,
      panY: state.panY + dy,
    );
  }

  void setRotation(double angle) {
    state = state.copyWith(rotation: angle);
  }

  void resetView() {
    state = const CanvasViewState();
  }

  void reset() => resetView();

  void fitToScreen(
    double screenWidth,
    double screenHeight,
    int canvasWidth,
    int canvasHeight, {
    double paddingFactor = 0.90,
  }) {
    if (screenWidth <= 0 || screenHeight <= 0 || canvasWidth <= 0 || canvasHeight <= 0) return;
    final scaleX = screenWidth / canvasWidth;
    final scaleY = screenHeight / canvasHeight;
    final zoom = ((scaleX < scaleY ? scaleX : scaleY) * paddingFactor)
        .clamp(CanvasDefaults.minZoom, CanvasDefaults.maxZoom);
    state = CanvasViewState(
      zoom: zoom,
      panX: (screenWidth - canvasWidth * zoom) / 2,
      panY: (screenHeight - canvasHeight * zoom) / 2,
      rotation: 0.0,
    );
  }
}

final canvasViewProvider =
    StateNotifierProvider<CanvasViewNotifier, CanvasViewState>((ref) {
      return CanvasViewNotifier();
    });

/// Controls whether the next/active canvas should auto-fit to screen upon presentation.
final autoFitToScreenProvider = StateProvider<bool>((ref) => false);

// ─────────────────────────────────────────────────────────────────────────────
// Undo/Redo State
// ─────────────────────────────────────────────────────────────────────────────

/// Represents an undoable action.
abstract class UndoableAction {
  void undo();
  void redo();
}

/// Stroke-based undo action — the most common action type.
class StrokeAction implements UndoableAction {
  StrokeAction({
    required this.documentNotifier,
    required this.stroke,
  });

  final CanvasDocumentNotifier documentNotifier;
  final Stroke stroke;

  @override
  void undo() {
    documentNotifier.removeLastStroke();
  }

  @override
  void redo() {
    documentNotifier.addStroke(stroke);
  }
}

/// Undoable action for clearing an entire layer.
class ClearCanvasAction implements UndoableAction {
  ClearCanvasAction({
    required this.documentNotifier,
    required this.clearedStrokes,
  });

  final CanvasDocumentNotifier documentNotifier;
  final List<Stroke> clearedStrokes;

  @override
  void undo() {
    for (final s in clearedStrokes) {
      documentNotifier.addStroke(s);
    }
  }

  @override
  void redo() {
    documentNotifier.clearActiveLayer();
  }
}

/// Undoable action for batch updating/transforming layer strokes (for transform, selection delete, filters).
class LayerStrokesAction implements UndoableAction {
  LayerStrokesAction({
    required this.documentNotifier,
    required this.oldStrokes,
    required this.newStrokes,
  });

  final CanvasDocumentNotifier documentNotifier;
  final List<Stroke> oldStrokes;
  final List<Stroke> newStrokes;

  @override
  void undo() {
    documentNotifier.updateActiveLayerStrokes(oldStrokes);
  }

  @override
  void redo() {
    documentNotifier.updateActiveLayerStrokes(newStrokes);
  }
}

/// Manages undo/redo history with memory-aware eviction.
class UndoRedoNotifier extends StateNotifier<UndoRedoState> {
  UndoRedoNotifier() : super(const UndoRedoState());

  void pushAction(UndoableAction action) {
    final undoStack = List<UndoableAction>.from(state.undoStack)..add(action);
    // Evict old entries if over limit
    if (undoStack.length > CanvasDefaults.maxUndoHistory) {
      undoStack.removeAt(0);
    }
    state = UndoRedoState(undoStack: undoStack, redoStack: []);
  }

  void undo() {
    if (state.undoStack.isEmpty) return;
    final undoStack = List<UndoableAction>.from(state.undoStack);
    final action = undoStack.removeLast();
    action.undo();
    final redoStack = List<UndoableAction>.from(state.redoStack)..add(action);
    state = UndoRedoState(undoStack: undoStack, redoStack: redoStack);
  }

  void redo() {
    if (state.redoStack.isEmpty) return;
    final redoStack = List<UndoableAction>.from(state.redoStack);
    final action = redoStack.removeLast();
    action.redo();
    final undoStack = List<UndoableAction>.from(state.undoStack)..add(action);
    state = UndoRedoState(undoStack: undoStack, redoStack: redoStack);
  }

  void clear() {
    state = const UndoRedoState();
  }
}

class UndoRedoState {
  const UndoRedoState({
    this.undoStack = const [],
    this.redoStack = const [],
  });

  final List<UndoableAction> undoStack;
  final List<UndoableAction> redoStack;

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
}

final undoRedoProvider =
    StateNotifierProvider<UndoRedoNotifier, UndoRedoState>((ref) {
      return UndoRedoNotifier();
    });

// ─────────────────────────────────────────────────────────────────────────────
// Current Stroke (in-progress drawing)
// ─────────────────────────────────────────────────────────────────────────────

/// Multiple strokes grouped as 1 logical undo action (for symmetry mode).
class MultiStrokeAction implements UndoableAction {
  MultiStrokeAction({
    required this.documentNotifier,
    required this.strokes,
  });

  final CanvasDocumentNotifier documentNotifier;
  final List<Stroke> strokes;

  @override
  void undo() {
    for (final s in strokes) {
      documentNotifier.removeStroke(s.id);
    }
  }

  @override
  void redo() {
    for (final s in strokes) {
      documentNotifier.addStroke(s);
    }
  }
}

/// The stroke currently being drawn (null when not drawing).
final currentStrokeProvider = StateProvider<Stroke?>((ref) => null);

/// Save status.
final saveStatusProvider = StateProvider<SaveStatus>((ref) => SaveStatus.saved);

/// Symmetry configuration provider.
final symmetryProvider = StateProvider<SymmetryConfig>(
  (ref) => const SymmetryConfig(),
);

/// Canvas paper texture provider.
final paperTextureProvider = StateProvider<CanvasPaperTexture>(
  (ref) => CanvasPaperTexture.none,
);

/// Onion skinning animation preview toggle provider.
final onionSkinEnabledProvider = StateProvider<bool>((ref) => false);

/// QuickShape auto-shape recognition (Draw & Hold) toggle provider.
final quickShapeEnabledProvider = StateProvider<bool>((ref) => true);

/// Adjustable streamline brush stabilizer level (0.0 to 1.0).
final streamlineLevelProvider = StateProvider<double>((ref) => 0.0);

