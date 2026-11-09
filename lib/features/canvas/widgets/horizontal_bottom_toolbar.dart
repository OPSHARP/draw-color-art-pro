import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stroke.dart';
import '../models/symmetry.dart';
import '../models/tools.dart';
import '../providers/canvas_providers.dart';
import 'canvas_background_modal.dart';
import 'image_source_modal.dart';
import 'shapes_icons_panel.dart';
import 'radial_quick_menu.dart';
import 'animation_timeline_modal.dart';
import '../providers/image_import_providers.dart';
import '../../text/views/font_picker_dialog.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// iOS-styled horizontally scrolling toolbar pinned to the bottom of the screen.
///
/// Features Apple HIG frosted glass background, Cupertino icons, fluid bouncing
/// scroll physics, springy pill selections, and iOS haptics.
class HorizontalBottomToolbar extends ConsumerWidget {
  const HorizontalBottomToolbar({
    super.key,
    required this.onToggleColorPicker,
    required this.onToggleLayerPanel,
    required this.onShareArt,
    required this.isColorPickerOpen,
    required this.isLayerPanelOpen,
    this.onOpenInspiration,
    this.onOpenAdjustments,
  });

  final VoidCallback onToggleColorPicker;
  final VoidCallback onToggleLayerPanel;
  final VoidCallback onShareArt;
  final bool isColorPickerOpen;
  final bool isLayerPanelOpen;
  final VoidCallback? onOpenInspiration;
  final VoidCallback? onOpenAdjustments;

  /// The 5 draw sub-tools consolidated under a single "Draw" button.
  static const _drawSubTools = [
    (DrawingTool.pen, CupertinoIcons.pen, 'Pen'),
    (DrawingTool.brush, CupertinoIcons.paintbrush, 'Brush'),
    (DrawingTool.pencil, CupertinoIcons.pencil, 'Pencil'),
    (DrawingTool.spray, CupertinoIcons.cloud_fill, 'Airbrush'),
    (DrawingTool.marker, CupertinoIcons.paintbrush_fill, 'Marker'),
  ];

  static const _tools = [
    (DrawingTool.brush, CupertinoIcons.paintbrush, 'Draw'),
    (DrawingTool.fill, CupertinoIcons.drop_fill, 'Fill'),
    (DrawingTool.gradient, CupertinoIcons.circle_lefthalf_fill, 'Gradient'),
    (DrawingTool.eraser, CupertinoIcons.bandage, 'Eraser'),
    (DrawingTool.shape, CupertinoIcons.square_on_circle, 'Shape'),
    (DrawingTool.text, CupertinoIcons.textformat, 'Text'),
    (DrawingTool.image, CupertinoIcons.photo, 'Photo'),
    (DrawingTool.symmetry, CupertinoIcons.arrow_right_arrow_left, 'Symmetry'),
    (DrawingTool.ruler, Icons.straighten_rounded, 'Ruler'),
    (DrawingTool.eyedropper, CupertinoIcons.eyedropper, 'Picker'),
    (DrawingTool.selection, CupertinoIcons.selection_pin_in_out, 'Select'),
    (DrawingTool.transform, CupertinoIcons.move, 'Move'),
    (DrawingTool.smudge, CupertinoIcons.hand_draw, 'Smudge'),
    (DrawingTool.blur, CupertinoIcons.circle_grid_hex, 'Blur'),
  ];

  static const _graphicSwatches = [
    Color(0xFF0055FF), // Royal Blue
    Color(0xFF0099FF), // Sky Blue
    Color(0xFF00D2FF), // Cyan Aqua
    Color(0xFF00E5A3), // Mint Teal
    Color(0xFFFFCC00), // Sunshine Yellow
    Color(0xFFFF8800), // Bright Orange
    Color(0xFFFF3366), // Coral Pink
    Color(0xFFE91E63), // Rose Red
    Color(0xFF9C27B0), // Purple Violet
    Color(0xFFFFFFFF), // Pure White
    Color(0xFF1E1E24), // Rich Black
  ];

  static const _neonPalette = [
    Color(0xFF00F0FF),
    Color(0xFFFF007F),
    Color(0xFF39FF14),
    Color(0xFFFFEE00),
    Color(0xFFBF00FF),
    Color(0xFFFF5F00),
  ];

  /// Returns true if tool is one of the 5 draw sub-tools.
  bool _isDrawSubTool(DrawingTool tool) {
    return tool == DrawingTool.brush ||
        tool == DrawingTool.pen ||
        tool == DrawingTool.pencil ||
        tool == DrawingTool.marker ||
        tool == DrawingTool.spray;
  }

  bool _isSpecializedTool(DrawingTool tool) {
    return switch (tool) {
      DrawingTool.brush ||
      DrawingTool.pen ||
      DrawingTool.pencil ||
      DrawingTool.marker ||
      DrawingTool.spray ||
      DrawingTool.text ||
      DrawingTool.shape ||
      DrawingTool.image ||
      DrawingTool.glow ||
      DrawingTool.symmetry ||
      DrawingTool.ruler ||
      DrawingTool.gradient ||
      DrawingTool.selection ||
      DrawingTool.transform ||
      DrawingTool.eyedropper ||
      DrawingTool.highlighter ||
      DrawingTool.rainbow ||
      DrawingTool.calligraphy ||
      DrawingTool.crayon ||
      DrawingTool.dotted ||
      DrawingTool.patternStamp ||
      DrawingTool.pixel ||
      DrawingTool.fill => true,
      _ => false,
    };
  }

  void _cycleBrushOpacity(WidgetRef ref, double currentOpacity) {
    final next = currentOpacity <= 0.35
        ? 1.0
        : currentOpacity <= 0.65
            ? 0.3
            : 0.6;
    ref.read(activeBrushProvider.notifier).setOpacity(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    final activeBrush = ref.watch(activeBrushProvider);
    final activeColor = ref.watch(activeColorProvider);
    final undoRedo = ref.watch(undoRedoProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final bottomInset = max(max(media.padding.bottom, media.viewPadding.bottom), 12.0);
    final sideInset = max(media.padding.left, media.padding.right);

    return ClipRect(
      child: BackdropFilter(
        filter: AppBlur.toolbar,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1B2A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(
                color: isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator,
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: bottomInset,
            left: sideInset,
            right: sideInset,
            top: 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Tier 1: Contextual Options OR Size Slider & Badge (from Graphic) ──
              _isSpecializedTool(activeTool)
                  ? Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: _buildToolOptions(context, ref, activeTool, activeBrush),
                      ),
                    )
                  : _buildSizeSliderRow(context, ref, activeBrush, isDark),

              // ── Tier 2: Color Palette Row (Rainbow Wheel + Swatches + Alpha Lock / Blend) ──
              _buildColorPaletteRow(context, ref, activeColor, activeBrush, isDark),

              // ── Tier 3: Brush Carousel Row ──
              _buildBrushCarouselRow(context, ref, activeTool, undoRedo, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeSliderRow(
    BuildContext context,
    WidgetRef ref,
    BrushPreset brush,
    bool isDark,
  ) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: IOSColors.brandPrimary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Size:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 140,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: IOSColors.brandPrimary,
                  inactiveTrackColor: isDark ? IOSColors.darkElevated : IOSColors.systemGray5,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, elevation: 3),
                  overlayColor: IOSColors.brandPrimary.withValues(alpha: 0.15),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: brush.size.clamp(1.0, 150.0),
                  min: 1.0,
                  max: 150.0,
                  onChanged: (val) {
                    ref.read(activeBrushProvider.notifier).setSize(val);
                  },
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? IOSColors.darkElevated : IOSColors.systemGray6,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator,
                  width: 0.5,
                ),
              ),
              child: Text(
                '${brush.size.toInt()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            _buildDivider(context),
            for (final sz in [4, 8, 16, 32, 64])
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _IOSChip(
                  label: '$sz',
                  isSelected: brush.size.toInt() == sz,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    SoundEffectService.instance.playPop();
                    ref.read(activeBrushProvider.notifier).setSize(sz.toDouble());
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPaletteRow(
    BuildContext context,
    WidgetRef ref,
    Color activeColor,
    BrushPreset brush,
    bool isDark,
  ) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Rainbow Color Wheel Circle Button (taps to open full color picker)
          Tooltip(
            message: 'Color Palette',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                SoundEffectService.instance.playPop();
                onToggleColorPicker();
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      Colors.red,
                      Colors.yellow,
                      Colors.green,
                      Colors.cyan,
                      Colors.blue,
                      Colors.purple,
                      Colors.red,
                    ],
                  ),
                  border: Border.all(
                    color: isColorPickerOpen ? IOSColors.brandPrimary : Colors.white,
                    width: isColorPickerOpen ? 2.2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Vibrant Horizontal Color Swatches from Feature Graphic
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final color in _graphicSwatches)
                    Builder(
                      builder: (context) {
                        final isSelected = activeColor.toARGB32() == color.toARGB32() ||
                            ((activeColor.r * 255).round() == (color.r * 255).round() &&
                             (activeColor.g * 255).round() == (color.g * 255).round() &&
                             (activeColor.b * 255).round() == (color.b * 255).round());
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            SoundEffectService.instance.playPop();
                            ref.read(activeColorProvider.notifier).setColor(color);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                            child: Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? IOSColors.brandPrimary
                                      : (isDark ? Colors.white24 : Colors.black12),
                                  width: isSelected ? 2.5 : 1.0,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.45),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 13,
                                      color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 3. Alpha Lock ("Color Inside") Checkered Circle Toggle
          Builder(
            builder: (ctx) {
              final doc = ref.watch(canvasDocumentProvider);
              final isAlphaLocked = doc.activeLayer?.isAlphaLocked ?? false;
              return Tooltip(
                message: isAlphaLocked ? 'Color Inside: ON' : 'Color Inside: OFF',
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    SoundEffectService.instance.playPop();
                    ref.read(canvasDocumentProvider.notifier).toggleLayerAlphaLock(doc.activeLayerIndex);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAlphaLocked
                          ? IOSColors.brandPrimary.withValues(alpha: 0.18)
                          : (isDark ? IOSColors.darkElevated : IOSColors.systemGray6),
                      border: Border.all(
                        color: isAlphaLocked
                            ? IOSColors.brandPrimary
                            : (isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator),
                        width: isAlphaLocked ? 1.5 : 1.0,
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.circle_grid_hex,
                      size: 15,
                      color: isAlphaLocked ? IOSColors.brandPrimary : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 6),

          // 4. Opacity / Blend Circle Toggle
          Tooltip(
            message: 'Opacity: ${(brush.opacity * 100).toInt()}% (Tap to adjust)',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                SoundEffectService.instance.playPop();
                _cycleBrushOpacity(ref, brush.opacity);
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? IOSColors.darkElevated : IOSColors.systemGray6,
                  border: Border.all(
                    color: isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator,
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.circle_lefthalf_fill,
                  size: 15,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrushCarouselRow(
    BuildContext context,
    WidgetRef ref,
    DrawingTool activeTool,
    dynamic undoRedo,
    bool isDark,
  ) {
    return SizedBox(
      height: 56,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // All tools — "Draw" entry highlights when any draw sub-tool is active
            for (final (tool, icon, label) in _tools)
              _ToolItem(
                tool: tool,
                icon: icon,
                label: label,
                isActive: label == 'Draw'
                    ? _isDrawSubTool(activeTool)
                    : activeTool == tool,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  if (label == 'Draw') {
                    // If not already on a draw sub-tool, default to brush
                    if (!_isDrawSubTool(activeTool)) {
                      ref.read(activeToolProvider.notifier).selectTool(DrawingTool.brush);
                    }
                    // Otherwise keep current draw sub-tool (just re-highlight)
                  } else {
                    ref.read(activeToolProvider.notifier).selectTool(tool);
                  }
                  if (tool == DrawingTool.text) {
                    FontPickerDialog.show(
                      context,
                      onApplyText: (text, _) => _applyTextToCanvas(ref, text),
                    );
                  } else if (tool == DrawingTool.image) {
                    ImageSourceModal.show(context, ref);
                  }
                },
              ),

            _buildDivider(context),

            // Quick Action: Undo
            _ActionItem(
              icon: CupertinoIcons.arrow_uturn_left,
              label: 'Undo',
              isEnabled: undoRedo.canUndo,
              onTap: () {
                HapticFeedback.mediumImpact();
                SoundEffectService.instance.playWhoosh();
                ref.read(undoRedoProvider.notifier).undo();
              },
            ),

            // Quick Action: Redo
            _ActionItem(
              icon: CupertinoIcons.arrow_uturn_right,
              label: 'Redo',
              isEnabled: undoRedo.canRedo,
              onTap: () {
                HapticFeedback.mediumImpact();
                SoundEffectService.instance.playPop();
                ref.read(undoRedoProvider.notifier).redo();
              },
            ),

            // Quick Action: Layers Toggle
            _ActionItem(
              icon: CupertinoIcons.square_stack_3d_up,
              label: 'Layers',
              isActive: isLayerPanelOpen,
              onTap: () {
                HapticFeedback.selectionClick();
                SoundEffectService.instance.playPop();
                onToggleLayerPanel();
              },
            ),

            // Quick Action: Canvas Background
            _ActionItem(
              icon: CupertinoIcons.photo,
              label: 'Canvas Bg',
              onTap: () {
                HapticFeedback.lightImpact();
                SoundEffectService.instance.playPop();
                CanvasBackgroundModal.show(context, ref);
              },
            ),

            // Quick Action: Color Adjustments & Filters
            _ActionItem(
              icon: CupertinoIcons.slider_horizontal_3,
              label: 'Adjust',
              highlightColor: IOSColors.systemIndigo,
              onTap: () {
                HapticFeedback.lightImpact();
                SoundEffectService.instance.playPop();
                onOpenAdjustments?.call();
              },
            ),

            // Quick Action: Inspiration Studio & Palettes
            _ActionItem(
              icon: CupertinoIcons.lightbulb_fill,
              label: 'Inspire',
              highlightColor: IOSColors.systemYellow,
              onTap: () {
                HapticFeedback.lightImpact();
                SoundEffectService.instance.playPop();
                onOpenInspiration?.call();
              },
            ),

            // Quick Action: Social Share
            _ActionItem(
              icon: CupertinoIcons.share,
              label: 'Share',
              highlightColor: IOSColors.systemPink,
              onTap: () {
                HapticFeedback.mediumImpact();
                SoundEffectService.instance.playCelebration();
                onShareArt();
              },
            ),

            // Quick Action: Radial QuickMenu
            _ActionItem(
              icon: CupertinoIcons.circle_grid_hex_fill,
              label: 'QuickMenu',
              highlightColor: const Color(0xFFFF9F0A),
              onTap: () {
                RadialQuickMenu.show(
                  context,
                  onOpenColorPicker: onToggleColorPicker,
                  onOpenAnimationTimeline: () => AnimationTimelineModal.show(context),
                );
              },
            ),

            // Quick Action: Flipbook Animation Timeline
            _ActionItem(
              icon: CupertinoIcons.play_rectangle_fill,
              label: 'Flipbook',
              highlightColor: const Color(0xFF30D158),
              onTap: () {
                AnimationTimelineModal.show(context);
              },
            ),

            _buildDivider(context),

            // Quick Action: Clear Canvas Layer
            _ActionItem(
              icon: CupertinoIcons.trash,
              label: 'Clear',
              highlightColor: IOSColors.systemRed,
              onTap: () => _confirmClearCanvas(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 28,
      child: VerticalDivider(
        width: 14,
        thickness: 0.5,
        indent: 4,
        endIndent: 4,
        color: isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator,
      ),
    );
  }

  Widget _buildTextFormatToggle({
    required IconData icon,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isActive
              ? IOSColors.brandPrimary.withValues(alpha: 0.18)
              : (isDark ? const Color(0xFF28283C) : const Color(0xFFEFF0F5)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? IOSColors.brandPrimary
                : (isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator),
            width: isActive ? 1.2 : 0.6,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 15,
            color: isActive
                ? IOSColors.brandPrimary
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  void _applyTextToCanvas(WidgetRef ref, String text) {
    final doc = ref.read(canvasDocumentProvider);
    final activeLayer = doc.activeLayer;
    if (activeLayer == null || activeLayer.isLocked || !activeLayer.isVisible) {
      return;
    }
    final selectedId = ref.read(selectedTextStrokeIdProvider);

    // If an existing text element is selected, update it in place!
    if (selectedId != null) {
      final existingIndex = activeLayer.strokes.indexWhere((s) => s.id == selectedId);
      if (existingIndex != -1) {
        final existing = activeLayer.strokes[existingIndex];
        final font = ref.read(selectedFontProvider);
        final typoConfig = ref.read(typographyConfigProvider);
        final updated = existing.copyWith(
          text: text.isNotEmpty ? text : existing.text,
          fontFamily: font.name,
          fontSize: typoConfig.fontSize,
          isBold: typoConfig.isBold,
          isItalic: typoConfig.isItalic,
          textAlign: typoConfig.textAlign.name,
          color: typoConfig.color != Colors.black ? typoConfig.color : existing.color,
          hasShadow: typoConfig.hasShadow,
          textShadowOffsetX: typoConfig.shadowOffsetX,
          textShadowOffsetY: typoConfig.shadowOffsetY,
          textShadowBlur: typoConfig.shadowBlur,
          textLineHeight: typoConfig.lineHeight,
          textStrokeColor: typoConfig.strokeWidth > 0 ? typoConfig.strokeColor : null,
          textStrokeWidth: typoConfig.strokeWidth > 0 ? typoConfig.strokeWidth : null,
          textBackgroundColor: typoConfig.hasBackgroundBox ? typoConfig.backgroundColor : null,
        );
        ref.read(canvasDocumentProvider.notifier).updateStroke(updated);
        ref.read(undoRedoProvider.notifier).pushAction(
          LayerStrokesAction(
            documentNotifier: ref.read(canvasDocumentProvider.notifier),
            oldStrokes: List<Stroke>.from(activeLayer.strokes),
            newStrokes: activeLayer.strokes.map((s) => s.id == selectedId ? updated : s).toList(),
          ),
        );
        ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
        SoundEffectService.instance.playCelebration();
        return;
      }
    }

    final font = ref.read(selectedFontProvider);
    final typoConfig = ref.read(typographyConfigProvider);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);
    final undoNotifier = ref.read(undoRedoProvider.notifier);
    final color = ref.read(activeColorProvider);
    final brush = ref.read(activeBrushProvider);

    final textStroke = Stroke(
      points: [
        StrokePoint(
          x: (doc.width / 2) - 120,
          y: (doc.height / 2) - 20,
          pressure: 1.0,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      ],
      color: typoConfig.color != Colors.black ? typoConfig.color : color,
      brush: brush,
      shapeType: ShapeType.text,
      text: text.isNotEmpty ? text : typoConfig.text,
      fontFamily: font.name,
      fontSize: typoConfig.fontSize,
      isBold: typoConfig.isBold,
      isItalic: typoConfig.isItalic,
      textAlign: typoConfig.textAlign.name,
      textDecoration: typoConfig.textDecoration == TextDecoration.underline
          ? 'underline'
          : typoConfig.textDecoration == TextDecoration.lineThrough
              ? 'strikethrough'
              : 'none',
      hasShadow: typoConfig.hasShadow,
      textShadowOffsetX: typoConfig.shadowOffsetX,
      textShadowOffsetY: typoConfig.shadowOffsetY,
      textShadowBlur: typoConfig.shadowBlur,
      textLineHeight: typoConfig.lineHeight,
      textStrokeColor: typoConfig.strokeWidth > 0 ? typoConfig.strokeColor : null,
      textStrokeWidth: typoConfig.strokeWidth > 0 ? typoConfig.strokeWidth : null,
      textBackgroundColor: typoConfig.hasBackgroundBox ? typoConfig.backgroundColor : null,
    );
    docNotifier.addStroke(textStroke);
    undoNotifier.pushAction(
      StrokeAction(documentNotifier: docNotifier, stroke: textStroke),
    );
    ref.read(selectedTextStrokeIdProvider.notifier).state = textStroke.id;
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
  }

  void _updateSelectedTextStroke(WidgetRef ref, Stroke Function(Stroke s) updater) {
    final selectedId = ref.read(selectedTextStrokeIdProvider);
    if (selectedId == null) return;
    final doc = ref.read(canvasDocumentProvider);
    final activeLayer = doc.activeLayer;
    if (activeLayer == null) return;
    final strokeIndex = activeLayer.strokes.indexWhere((s) => s.id == selectedId);
    if (strokeIndex == -1) return;
    final stroke = activeLayer.strokes[strokeIndex];
    final updated = updater(stroke);
    ref.read(canvasDocumentProvider.notifier).updateStroke(updated);
  }

  void _confirmClearCanvas(BuildContext context, WidgetRef ref) {
    HapticFeedback.heavyImpact();
    SoundEffectService.instance.playWhoosh();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Clear Layer?'),
        content: const Text('Are you sure you want to clear this layer? You can undo anytime.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              final doc = ref.read(canvasDocumentProvider);
              final activeLayer = doc.activeLayer;
              if (activeLayer != null && activeLayer.strokes.isNotEmpty) {
                final oldStrokes = List<Stroke>.from(activeLayer.strokes);
                ref.read(canvasDocumentProvider.notifier).clearActiveLayer();
                ref.read(undoRedoProvider.notifier).pushAction(
                  ClearCanvasAction(
                    documentNotifier: ref.read(canvasDocumentProvider.notifier),
                    clearedStrokes: oldStrokes,
                  ),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolOptions(
    BuildContext context,
    WidgetRef ref,
    DrawingTool activeTool,
    BrushPreset brush,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? IOSColors.systemGray : IOSColors.systemGray2;

    // ── Draw sub-tool selector (Pen, Brush, Pencil, Airbrush, Marker) + size slider ──
    if (_isDrawSubTool(activeTool)) {
      return Row(
        children: [
          for (final (tool, _, label) in _drawSubTools)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _IOSChip(
                label: label,
                isSelected: activeTool == tool,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(activeToolProvider.notifier).selectTool(tool);
                },
              ),
            ),
          _buildDivider(context),
          Text(
            '${brush.size.toInt()}px',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          SizedBox(
            width: 100,
            child: CupertinoSlider(
              value: brush.size.clamp(1.0, 150.0),
              min: 1.0,
              max: 150.0,
              activeColor: IOSColors.brandPrimary,
              onChanged: (val) {
                ref.read(activeBrushProvider.notifier).setSize(val);
              },
            ),
          ),
          const SizedBox(width: 4),
          for (final sz in [4, 8, 16, 32])
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: _IOSChip(
                label: '$sz',
                isSelected: brush.size.toInt() == sz,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(activeBrushProvider.notifier).setSize(sz.toDouble());
                },
              ),
            ),
          _buildDivider(context),
          // Streamline rope stabilizer
          Builder(
            builder: (ctx) {
              final streamline = ref.watch(streamlineLevelProvider);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rope: ${(streamline * 100).round()}%',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  SizedBox(
                    width: 70,
                    child: CupertinoSlider(
                      value: streamline,
                      min: 0.0,
                      max: 1.0,
                      activeColor: const Color(0xFF00CEC9),
                      onChanged: (val) {
                        ref.read(streamlineLevelProvider.notifier).state = val;
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
          // QuickShape auto-snap toggle
          Builder(
            builder: (ctx) {
              final quickShape = ref.watch(quickShapeEnabledProvider);
              return _IOSChip(
                label: quickShape ? 'Auto Shape: ON' : 'Auto Shape: OFF',
                isSelected: quickShape,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(quickShapeEnabledProvider.notifier).state = !quickShape;
                },
              );
            },
          ),
        ],
      );
    }

    if (activeTool == DrawingTool.text) {
      final selectedFont = ref.watch(selectedFontProvider);
      final typoConfig = ref.watch(typographyConfigProvider);

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Font Selector Pill (Clean, Justified, Premium HIG Style) ──
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              SoundEffectService.instance.playPop();
              final selectedId = ref.read(selectedTextStrokeIdProvider);
              final doc = ref.read(canvasDocumentProvider);
              final activeLayer = doc.activeLayer;
              String? currentText;
              if (selectedId != null && activeLayer != null) {
                final match = activeLayer.strokes.where((s) => s.id == selectedId).firstOrNull;
                currentText = match?.text;
              }
              FontPickerDialog.show(
                context,
                initialText: currentText,
                onApplyText: (text, _) => _applyTextToCanvas(ref, text),
              );
            },
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF28283C) : const Color(0xFFEFF0F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.textformat,
                    size: 14,
                    color: IOSColors.brandPrimary,
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      selectedFont.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_up_chevron_down,
                    size: 11,
                    color: subColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Bold Toggle ──
          _buildTextFormatToggle(
            icon: CupertinoIcons.bold,
            isActive: typoConfig.isBold,
            isDark: isDark,
            onTap: () {
              HapticFeedback.selectionClick();
              SoundEffectService.instance.playPop();
              final newBold = !typoConfig.isBold;
              ref.read(typographyConfigProvider.notifier).state =
                  typoConfig.copyWith(isBold: newBold);
              _updateSelectedTextStroke(ref, (s) => s.copyWith(isBold: newBold));
            },
          ),
          const SizedBox(width: 4),

          // ── Italic Toggle ──
          _buildTextFormatToggle(
            icon: CupertinoIcons.italic,
            isActive: typoConfig.isItalic,
            isDark: isDark,
            onTap: () {
              HapticFeedback.selectionClick();
              SoundEffectService.instance.playPop();
              final newItalic = !typoConfig.isItalic;
              ref.read(typographyConfigProvider.notifier).state =
                  typoConfig.copyWith(isItalic: newItalic);
              _updateSelectedTextStroke(ref, (s) => s.copyWith(isItalic: newItalic));
            },
          ),
          const SizedBox(width: 8),

          // ── Divider ──
          _buildDivider(context),

          // ── Text Size Slider ──
          Text(
            '${typoConfig.fontSize.toInt()}pt',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: textColor,
            ),
          ),
          SizedBox(
            width: 100,
            child: CupertinoSlider(
              value: typoConfig.fontSize.clamp(12.0, 96.0),
              min: 12.0,
              max: 96.0,
              activeColor: IOSColors.brandPrimary,
              onChanged: (val) {
                ref.read(typographyConfigProvider.notifier).state =
                    typoConfig.copyWith(fontSize: val);
                _updateSelectedTextStroke(ref, (s) => s.copyWith(fontSize: val));
              },
            ),
          ),
        ],
      );
    }

    if (activeTool == DrawingTool.shape) {
      final activeShape = ref.watch(activeShapeProvider);
      final isFilled = ref.watch(isShapeFilledProvider);

      return Row(
        children: [
          Text('Shape:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subColor)),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _IOSChip(
              label: 'Library ✦',
              isSelected: false,
              onTap: () {
                ShapesIconsPanel.show(context);
              },
            ),
          ),
          _buildDivider(context),
          for (final shape in [
            ShapeType.line,
            ShapeType.rectangle,
            ShapeType.roundedRectangle,
            ShapeType.circle,
            ShapeType.triangle,
            ShapeType.star,
            ShapeType.heart,
            ShapeType.hexagon,
            ShapeType.pentagon,
            ShapeType.octagon,
            ShapeType.diamond,
            ShapeType.ring,
            ShapeType.cross,
            ShapeType.crescent,
            ShapeType.arrow,
            ShapeType.chevron,
            ShapeType.playButton,
            ShapeType.crown,
            ShapeType.banner,
            ShapeType.starburst,
            ShapeType.shield,
            ShapeType.speechBubble,
            ShapeType.cloud,
          ])
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _IOSChip(
                label: shape.label,
                isSelected: activeShape == shape,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(activeShapeProvider.notifier).state = shape;
                },
              ),
            ),
          _buildDivider(context),
          _IOSChip(
            label: isFilled ? 'Filled' : 'Outline',
            isSelected: isFilled,
            onTap: () {
              HapticFeedback.selectionClick();
              SoundEffectService.instance.playPop();
              ref.read(isShapeFilledProvider.notifier).state = !isFilled;
            },
          ),
        ],
      );
    }

    if (activeTool == DrawingTool.image) {
      final placed = ref.watch(placedImageProvider);
      return Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: const Size(30, 30),
            color: IOSColors.brandPrimary,
            borderRadius: BorderRadius.circular(8),
            onPressed: () => ImageSourceModal.show(context, ref),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.photo_on_rectangle, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  placed == null ? 'Import Photo' : 'Change Photo',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
          if (placed != null) ...[
            const SizedBox(width: 8),
            Text(
              'Opacity: ${(placed.opacity * 100).toInt()}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
            ),
            SizedBox(
              width: 90,
              child: CupertinoSlider(
                value: placed.opacity,
                min: 0.05,
                max: 1.0,
                activeColor: IOSColors.brandPrimary,
                onChanged: (v) {
                  ref.read(placedImageProvider.notifier).state = placed.copyWith(opacity: v);
                },
              ),
            ),
            const SizedBox(width: 6),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(28, 28),
              color: isDark ? IOSColors.darkElevated : IOSColors.systemGray5,
              borderRadius: BorderRadius.circular(8),
              onPressed: () {
                HapticFeedback.mediumImpact();
                SoundEffectService.instance.playCelebration();
                ImagePlacementController.commit(ref, asNewLayer: false);
              },
              child: const Text('Place', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: IOSColors.systemGreen)),
            ),
            const SizedBox(width: 4),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(28, 28),
              color: isDark ? IOSColors.darkElevated : IOSColors.systemGray5,
              borderRadius: BorderRadius.circular(8),
              onPressed: () {
                HapticFeedback.lightImpact();
                SoundEffectService.instance.playWhoosh();
                ImagePlacementController.cancel(ref);
              },
              child: const Text('Cancel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: IOSColors.systemRed)),
            ),
          ],
        ],
      );
    }

    if (activeTool == DrawingTool.glow) {
      final activeColor = ref.watch(activeColorProvider);
      return Row(
        children: [
          const Icon(CupertinoIcons.sparkles, size: 16, color: Color(0xFF00F0FF)),
          const SizedBox(width: 6),
          Text(
            'Glow Size: ${brush.size.toInt()}px',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          SizedBox(
            width: 100,
            child: CupertinoSlider(
              value: brush.size.clamp(4.0, 80.0),
              min: 4.0,
              max: 80.0,
              activeColor: const Color(0xFF00F0FF),
              onChanged: (val) {
                ref.read(activeBrushProvider.notifier).setSize(val);
              },
            ),
          ),
          _buildDivider(context),
          Text('Neon Lights:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: subColor)),
          const SizedBox(width: 6),
          for (final nc in _neonPalette)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(activeColorProvider.notifier).setColor(nc);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: nc,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeColor.toARGB32() == nc.toARGB32() ? Colors.white : Colors.transparent,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: nc.withValues(alpha: 0.6),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: activeColor.toARGB32() == nc.toARGB32()
                      ? Icon(
                          Icons.check,
                          size: 12,
                          color: nc.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                        )
                      : null,
                ),
              ),
            ),
        ],
      );
    }

    if (activeTool == DrawingTool.spray) {
      return Row(
        children: [
          const Icon(CupertinoIcons.cloud_fill, size: 16, color: IOSColors.brandPrimary),
          const SizedBox(width: 6),
          Text(
            'Spray Size: ${brush.size.toInt()}px',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          SizedBox(
            width: 100,
            child: CupertinoSlider(
              value: brush.size.clamp(10.0, 100.0),
              min: 10.0,
              max: 100.0,
              activeColor: IOSColors.brandPrimary,
              onChanged: (val) {
                ref.read(activeBrushProvider.notifier).setSize(val);
              },
            ),
          ),
          _buildDivider(context),
          Text('Density:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: subColor)),
          const SizedBox(width: 4),
          for (final (label, flowVal) in [('Mist', 0.25), ('Medium', 0.55), ('Dense', 0.85)])
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _IOSChip(
                label: label,
                isSelected: (brush.flow - flowVal).abs() < 0.18,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(activeBrushProvider.notifier).setFlow(flowVal);
                },
              ),
            ),
        ],
      );
    }

    if (activeTool == DrawingTool.highlighter) {
      final activeColor = ref.watch(activeColorProvider);
      final doc = ref.watch(canvasDocumentProvider);
      final isAlphaLocked = doc.activeLayer?.isAlphaLocked ?? false;
      const fluors = [
        Color(0xFFFFE600), // Neon Yellow
        Color(0xFF39FF14), // Neon Green
        Color(0xFFFF007F), // Hot Pink
        Color(0xFFFF5F00), // Neon Orange
        Color(0xFF00F0FF), // Cyber Cyan
        Color(0xFFBF55EC), // Soft Lilac
      ];

      return Row(
        children: [
          const Icon(CupertinoIcons.pencil_ellipsis_rectangle, size: 16, color: Color(0xFFFFE600)),
          const SizedBox(width: 6),
          Text(
            'Chisel: ${brush.size.toInt()}px',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          SizedBox(
            width: 80,
            child: CupertinoSlider(
              value: brush.size.clamp(8.0, 100.0),
              min: 8.0,
              max: 100.0,
              activeColor: IOSColors.brandPrimary,
              onChanged: (val) {
                ref.read(activeBrushProvider.notifier).setSize(val);
              },
            ),
          ),
          _buildDivider(context),
          Text(
            'Tint: ${(brush.opacity * 100).toInt()}%',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          SizedBox(
            width: 70,
            child: CupertinoSlider(
              value: brush.opacity.clamp(0.1, 0.8),
              min: 0.1,
              max: 0.8,
              activeColor: IOSColors.brandPrimary,
              onChanged: (val) {
                ref.read(activeBrushProvider.notifier).setOpacity(val);
              },
            ),
          ),
          _buildDivider(context),
          for (final fc in fluors)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(activeColorProvider.notifier).setColor(fc);
                },
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fc,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeColor.toARGB32() == fc.toARGB32() ? Colors.white : Colors.transparent,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: fc.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: activeColor.toARGB32() == fc.toARGB32()
                      ? Icon(
                          Icons.check,
                          size: 12,
                          color: fc.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          _buildDivider(context),
          _IOSChip(
            label: isAlphaLocked ? '🔒 Color Inside' : '🔓 Free Draw',
            isSelected: isAlphaLocked,
            onTap: () {
              HapticFeedback.selectionClick();
              SoundEffectService.instance.playPop();
              ref.read(canvasDocumentProvider.notifier).toggleLayerAlphaLock(doc.activeLayerIndex);
            },
          ),
        ],
      );
    }

    if (activeTool == DrawingTool.rainbow) {
      final rainbowMode = ref.watch(rainbowModeProvider);
      final doc = ref.watch(canvasDocumentProvider);
      final isAlphaLocked = doc.activeLayer?.isAlphaLocked ?? false;

      return Row(
        children: [
          const Icon(CupertinoIcons.color_filter, size: 16, color: Color(0xFFFF2D55)),
          const SizedBox(width: 6),
          Text(
            'Size: ${brush.size.toInt()}px',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          SizedBox(
            width: 80,
            child: CupertinoSlider(
              value: brush.size.clamp(4.0, 100.0),
              min: 4.0,
              max: 100.0,
              activeColor: IOSColors.brandPrimary,
              onChanged: (val) {
                ref.read(activeBrushProvider.notifier).setSize(val);
              },
            ),
          ),
          _buildDivider(context),
          for (final mode in RainbowMode.values)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _IOSChip(
                label: mode.label,
                isSelected: rainbowMode == mode,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(rainbowModeProvider.notifier).state = mode;
                },
              ),
            ),
          _buildDivider(context),
          _IOSChip(
            label: isAlphaLocked ? '🔒 Color Inside' : '🔓 Free Draw',
            isSelected: isAlphaLocked,
            onTap: () {
              HapticFeedback.selectionClick();
              SoundEffectService.instance.playPop();
              ref.read(canvasDocumentProvider.notifier).toggleLayerAlphaLock(doc.activeLayerIndex);
            },
          ),
        ],
      );
    }

    if (activeTool == DrawingTool.gradient) {
      final gradType = ref.watch(gradientTypeProvider);
      final secondaryColor = ref.watch(gradientSecondaryColorProvider);
      const gradPresets = [
        Color(0xFFFFFFFF),
        Color(0xFF000000),
        Color(0xFF007AFF),
        Color(0xFFFF2D55),
        Color(0xFFFF9500),
        Color(0xFFAF52DE),
        Color(0xFF00F0FF),
      ];

      return Row(
        children: [
          const Icon(CupertinoIcons.circle_lefthalf_fill, size: 16, color: IOSColors.brandPrimary),
          const SizedBox(width: 6),
          _IOSChip(
            label: 'Linear',
            isSelected: gradType == GradientType.linear,
            onTap: () {
              HapticFeedback.selectionClick();
              SoundEffectService.instance.playPop();
              ref.read(gradientTypeProvider.notifier).state = GradientType.linear;
            },
          ),
          const SizedBox(width: 4),
          _IOSChip(
            label: 'Radial',
            isSelected: gradType == GradientType.radial,
            onTap: () {
              HapticFeedback.selectionClick();
              SoundEffectService.instance.playPop();
              ref.read(gradientTypeProvider.notifier).state = GradientType.radial;
            },
          ),
          _buildDivider(context),
          Text('End Color:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: subColor)),
          const SizedBox(width: 4),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: secondaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
          const SizedBox(width: 4),
          for (final sc in gradPresets)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(gradientSecondaryColorProvider.notifier).state = sc;
                },
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: sc,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: secondaryColor == sc ? IOSColors.brandPrimary : Colors.black12,
                      width: secondaryColor == sc ? 1.5 : 0.8,
                    ),
                  ),
                ),
              ),
            ),
          _buildDivider(context),
          Text('Drag line across canvas to fill gradient', style: TextStyle(fontSize: 10, color: subColor)),
        ],
      );
    }

    if (activeTool == DrawingTool.symmetry) {
      final symmetry = ref.watch(symmetryProvider);
      return Row(
        children: [
          const Icon(CupertinoIcons.arrow_right_arrow_left, size: 16, color: IOSColors.brandPrimary),
          const SizedBox(width: 6),
          Text('Symmetry:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subColor)),
          const SizedBox(width: 6),
          for (final m in SymmetryMode.values)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _IOSChip(
                label: m.label,
                isSelected: symmetry.mode == m,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(symmetryProvider.notifier).state = symmetry.copyWith(mode: m);
                },
              ),
            ),
          if (symmetry.mode == SymmetryMode.radial) ...[
            _buildDivider(context),
            Text('Segments:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: subColor)),
            const SizedBox(width: 4),
            for (final seg in [4, 6, 8, 12, 16])
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _IOSChip(
                  label: '$seg',
                  isSelected: symmetry.segments == seg,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    SoundEffectService.instance.playPop();
                    ref.read(symmetryProvider.notifier).state = symmetry.copyWith(segments: seg);
                  },
                ),
              ),
          ],
        ],
      );
    }

    if (activeTool == DrawingTool.ruler) {
      final rMode = ref.watch(rulerGuideModeProvider);
      return Row(
        children: [
          const Icon(Icons.straighten_rounded, size: 16, color: IOSColors.systemTeal),
          const SizedBox(width: 6),
          Text('Ruler:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subColor)),
          const SizedBox(width: 6),
          for (final rm in RulerGuideMode.values)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _IOSChip(
                label: rm.label,
                isSelected: rMode == rm,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(rulerGuideModeProvider.notifier).state = rm;
                },
              ),
            ),
        ],
      );
    }

    if (activeTool == DrawingTool.calligraphy) {
      return Row(
        children: [
          const Icon(CupertinoIcons.signature, size: 16, color: Color(0xFF8B4513)),
          const SizedBox(width: 6),
          Text(
            'Nib: ${brush.size.toInt()}px',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          SizedBox(
            width: 90,
            child: CupertinoSlider(
              value: brush.size.clamp(2.0, 40.0),
              min: 2.0,
              max: 40.0,
              activeColor: IOSColors.brandPrimary,
              onChanged: (val) {
                ref.read(activeBrushProvider.notifier).setSize(val);
              },
            ),
          ),
          _buildDivider(context),
          Text('Smooth:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: subColor)),
          const SizedBox(width: 4),
          for (final (label, mode) in [
            ('Off', StabilizationMode.off),
            ('Smooth', StabilizationMode.smooth),
            ('Pro', StabilizationMode.professional),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _IOSChip(
                label: label,
                isSelected: brush.stabilization == mode,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(activeBrushProvider.notifier).setStabilization(mode);
                },
              ),
            ),
        ],
      );
    }

    if (activeTool == DrawingTool.crayon) {
      return Row(
        children: [
          const Icon(CupertinoIcons.scribble, size: 16, color: Color(0xFFE67E22)),
          const SizedBox(width: 6),
          Text(
            'Size: ${brush.size.toInt()}px',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          SizedBox(
            width: 90,
            child: CupertinoSlider(
              value: brush.size.clamp(6.0, 60.0),
              min: 6.0,
              max: 60.0,
              activeColor: IOSColors.brandPrimary,
              onChanged: (val) {
                ref.read(activeBrushProvider.notifier).setSize(val);
              },
            ),
          ),
          _buildDivider(context),
          Text(
            'Opacity: ${(brush.opacity * 100).toInt()}%',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          SizedBox(
            width: 80,
            child: CupertinoSlider(
              value: brush.opacity.clamp(0.1, 1.0),
              min: 0.1,
              max: 1.0,
              activeColor: IOSColors.brandPrimary,
              onChanged: (val) {
                ref.read(activeBrushProvider.notifier).setOpacity(val);
              },
            ),
          ),
        ],
      );
    }

    if (activeTool == DrawingTool.dotted) {
      return Row(
        children: [
          const Icon(CupertinoIcons.ellipsis, size: 16, color: IOSColors.systemBlue),
          const SizedBox(width: 6),
          Text(
            'Size: ${brush.size.toInt()}px',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          SizedBox(
            width: 90,
            child: CupertinoSlider(
              value: brush.size.clamp(2.0, 30.0),
              min: 2.0,
              max: 30.0,
              activeColor: IOSColors.brandPrimary,
              onChanged: (val) {
                ref.read(activeBrushProvider.notifier).setSize(val);
              },
            ),
          ),
          _buildDivider(context),
          Text('Spacing:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: subColor)),
          const SizedBox(width: 4),
          for (final (label, sp) in [('Tight', 0.25), ('Normal', 0.5), ('Wide', 1.0)])
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _IOSChip(
                label: label,
                isSelected: (brush.spacing - sp).abs() < 0.15,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(activeBrushProvider.notifier).selectBrush(brush.copyWith(spacing: sp));
                },
              ),
            ),
        ],
      );
    }

    if (activeTool == DrawingTool.patternStamp) {
      final stampType = ref.watch(patternStampTypeProvider);
      return Row(
        children: [
          const Icon(CupertinoIcons.star, size: 16, color: Color(0xFF9B59B6)),
          const SizedBox(width: 6),
          Text(
            'Size: ${brush.size.toInt()}px',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          SizedBox(
            width: 80,
            child: CupertinoSlider(
              value: brush.size.clamp(8.0, 60.0),
              min: 8.0,
              max: 60.0,
              activeColor: IOSColors.brandPrimary,
              onChanged: (val) {
                ref.read(activeBrushProvider.notifier).setSize(val);
              },
            ),
          ),
          _buildDivider(context),
          for (final pt in PatternStampType.values)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _IOSChip(
                label: pt.label,
                isSelected: stampType == pt,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(patternStampTypeProvider.notifier).state = pt;
                },
              ),
            ),
        ],
      );
    }

    if (activeTool == DrawingTool.pixel) {
      final gridSize = ref.watch(pixelGridSizeProvider);
      return Row(
        children: [
          const Icon(CupertinoIcons.square_grid_2x2, size: 16, color: IOSColors.systemGreen),
          const SizedBox(width: 6),
          Text(
            'Pixel: ${gridSize.toInt()}px',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(width: 6),
          for (final sz in [2.0, 4.0, 8.0, 16.0, 32.0])
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _IOSChip(
                label: '${sz.toInt()}',
                isSelected: (gridSize - sz).abs() < 0.5,
                onTap: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(pixelGridSizeProvider.notifier).state = sz;
                  ref.read(activeBrushProvider.notifier).setSize(sz);
                },
              ),
            ),
        ],
      );
    }

    if (activeTool == DrawingTool.fill) {
      final tolerance = ref.watch(fillToleranceProvider);
      return Row(
        children: [
          const Icon(CupertinoIcons.drop_fill, size: 16, color: IOSColors.brandPrimary),
          const SizedBox(width: 6),
          Text('Tolerance: $tolerance%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
          SizedBox(
            width: 120,
            child: CupertinoSlider(
              value: tolerance.toDouble(),
              min: 5.0,
              max: 80.0,
              activeColor: IOSColors.brandPrimary,
              onChanged: (val) {
                ref.read(fillToleranceProvider.notifier).state = val.round();
              },
            ),
          ),
          Text('Tap area to flood fill', style: TextStyle(fontSize: 10, color: subColor)),
        ],
      );
    }

    if (activeTool == DrawingTool.selection) {
      final activeSelection = ref.watch(activeSelectionRectProvider);
      return Row(
        children: [
          const Icon(CupertinoIcons.selection_pin_in_out, size: 16, color: IOSColors.brandPrimary),
          const SizedBox(width: 6),
          Text(
            activeSelection == null
                ? 'Drag box on canvas to select'
                : 'Selected: ${activeSelection.width.toInt()}×${activeSelection.height.toInt()}px',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          if (activeSelection != null) ...[
            const SizedBox(width: 8),
            _IOSChip(
              label: 'Fill Rect',
              isSelected: false,
              onTap: () {
                HapticFeedback.mediumImpact();
                SoundEffectService.instance.playCelebration();
                final docNotifier = ref.read(canvasDocumentProvider.notifier);
                final undoNotifier = ref.read(undoRedoProvider.notifier);
                final color = ref.read(activeColorProvider);
                final fillBrush = ref.read(activeBrushProvider);
                final fillStroke = Stroke(
                  points: [
                    StrokePoint(x: activeSelection.left, y: activeSelection.top, pressure: 1.0, timestamp: 0),
                    StrokePoint(x: activeSelection.right, y: activeSelection.bottom, pressure: 1.0, timestamp: 1),
                  ],
                  color: color,
                  brush: fillBrush,
                  shapeType: ShapeType.rectangle,
                  isFilled: true,
                );
                docNotifier.addStroke(fillStroke);
                undoNotifier.pushAction(StrokeAction(documentNotifier: docNotifier, stroke: fillStroke));
              },
            ),
            const SizedBox(width: 4),
            _IOSChip(
              label: 'Delete Inside',
              isSelected: false,
              onTap: () {
                HapticFeedback.mediumImpact();
                SoundEffectService.instance.playWhoosh();
                final doc = ref.read(canvasDocumentProvider);
                final activeLayer = doc.activeLayer;
                if (activeLayer != null && activeLayer.strokes.isNotEmpty) {
                  final oldStrokes = List<Stroke>.from(activeLayer.strokes);
                  final remaining = activeLayer.strokes.where((s) {
                    final b = s.bounds;
                    return !activeSelection.overlaps(b);
                  }).toList();
                  if (remaining.length != oldStrokes.length) {
                    final docNotifier = ref.read(canvasDocumentProvider.notifier);
                    docNotifier.updateActiveLayerStrokes(remaining);
                    ref.read(undoRedoProvider.notifier).pushAction(
                      LayerStrokesAction(
                        documentNotifier: docNotifier,
                        oldStrokes: oldStrokes,
                        newStrokes: remaining,
                      ),
                    );
                  }
                }
                ref.read(activeSelectionRectProvider.notifier).state = null;
              },
            ),
            const SizedBox(width: 4),
            _IOSChip(
              label: 'Clear Box',
              isSelected: false,
              onTap: () {
                HapticFeedback.selectionClick();
                SoundEffectService.instance.playPop();
                ref.read(activeSelectionRectProvider.notifier).state = null;
              },
            ),
          ],
        ],
      );
    }

    if (activeTool == DrawingTool.transform) {
      return Row(
        children: [
          const Icon(CupertinoIcons.move, size: 16, color: IOSColors.brandPrimary),
          const SizedBox(width: 6),
          Text(
            'Drag canvas to move active layer',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(width: 8),
          _IOSChip(
            label: 'Center Layer',
            isSelected: false,
            onTap: () {
              HapticFeedback.mediumImpact();
              SoundEffectService.instance.playPop();
              final doc = ref.read(canvasDocumentProvider);
              final activeLayer = doc.activeLayer;
              if (activeLayer != null && activeLayer.strokes.isNotEmpty) {
                final oldStrokes = List<Stroke>.from(activeLayer.strokes);
                double minX = double.infinity, minY = double.infinity;
                double maxX = -double.infinity, maxY = -double.infinity;
                for (final s in activeLayer.strokes) {
                  final b = s.bounds;
                  if (b.left < minX) minX = b.left;
                  if (b.top < minY) minY = b.top;
                  if (b.right > maxX) maxX = b.right;
                  if (b.bottom > maxY) maxY = b.bottom;
                }
                final layerCenterX = (minX + maxX) / 2;
                final layerCenterY = (minY + maxY) / 2;
                final canvasCenterX = doc.width / 2;
                final canvasCenterY = doc.height / 2;
                final dx = canvasCenterX - layerCenterX;
                final dy = canvasCenterY - layerCenterY;

                if (dx.abs() > 0.5 || dy.abs() > 0.5) {
                  final moved = activeLayer.strokes.map((s) {
                    return s.copyWith(
                      points: s.points.map((p) => p.copyWith(x: p.x + dx, y: p.y + dy)).toList(),
                    );
                  }).toList();
                  final docNotifier = ref.read(canvasDocumentProvider.notifier);
                  docNotifier.updateActiveLayerStrokes(moved);
                  ref.read(undoRedoProvider.notifier).pushAction(
                    LayerStrokesAction(
                      documentNotifier: docNotifier,
                      oldStrokes: oldStrokes,
                      newStrokes: moved,
                    ),
                  );
                }
              }
            },
          ),
        ],
      );
    }

    if (activeTool == DrawingTool.eyedropper) {
      final activeColor = ref.watch(activeColorProvider);
      final hex = '#${activeColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
      return Row(
        children: [
          const Icon(CupertinoIcons.eyedropper, size: 16, color: IOSColors.brandPrimary),
          const SizedBox(width: 6),
          Container(width: 14, height: 14, decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('Color Picked: $hex', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(width: 8),
          Text('Tap anywhere on canvas to pick color', style: TextStyle(fontSize: 10, color: subColor)),
        ],
      );
    }

    // Default for Brush, Pencil, Pen, Marker, Eraser, Smudge, Blur
    return Row(
      children: [
        Text(
          'Size: ${brush.size.toInt()}px',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
        ),
        SizedBox(
          width: 100,
          child: CupertinoSlider(
            value: brush.size.clamp(1.0, 150.0),
            min: 1.0,
            max: 150.0,
            activeColor: IOSColors.brandPrimary,
            onChanged: (val) {
              ref.read(activeBrushProvider.notifier).setSize(val);
            },
          ),
        ),
        // Preset pills
        for (final sz in [4.0, 8.0, 16.0, 32.0, 64.0])
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _IOSChip(
              label: '${sz.toInt()}',
              isSelected: (brush.size - sz).abs() < 1.5,
              onTap: () {
                HapticFeedback.selectionClick();
                SoundEffectService.instance.playPop();
                ref.read(activeBrushProvider.notifier).setSize(sz);
              },
            ),
          ),
        _buildDivider(context),
        Text(
          'Opacity: ${(brush.opacity * 100).toInt()}%',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
        ),
        SizedBox(
          width: 90,
          child: CupertinoSlider(
            value: brush.opacity.clamp(0.05, 1.0),
            min: 0.05,
            max: 1.0,
            activeColor: IOSColors.brandPrimary,
            onChanged: (val) {
              ref.read(activeBrushProvider.notifier).setOpacity(val);
            },
          ),
        ),
        _buildDivider(context),
        Text('Smooth:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: subColor)),
        const SizedBox(width: 4),
        for (final (label, mode) in [
          ('Off', StabilizationMode.off),
          ('Smooth', StabilizationMode.smooth),
          ('Pro', StabilizationMode.professional),
        ])
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _IOSChip(
              label: label,
              isSelected: brush.stabilization == mode,
              onTap: () {
                HapticFeedback.selectionClick();
                SoundEffectService.instance.playPop();
                ref.read(activeBrushProvider.notifier).setStabilization(mode);
              },
            ),
          ),
        _buildDivider(context),
        Builder(
          builder: (ctx) {
            final doc = ref.watch(canvasDocumentProvider);
            final isAlphaLocked = doc.activeLayer?.isAlphaLocked ?? false;
            return _IOSChip(
              label: isAlphaLocked ? '🔒 Color Inside' : '🔓 Free Draw',
              isSelected: isAlphaLocked,
              onTap: () {
                HapticFeedback.selectionClick();
                SoundEffectService.instance.playPop();
                ref.read(canvasDocumentProvider.notifier).toggleLayerAlphaLock(doc.activeLayerIndex);
              },
            );
          },
        ),
      ],
    );
  }
}

/// iOS-styled selectable chip pill.
class _IOSChip extends StatelessWidget {
  const _IOSChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(26, 26),
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? IOSColors.brandPrimary
              : (isDark ? IOSColors.darkElevated : IOSColors.systemGray6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? IOSColors.systemGray : IOSColors.systemGray2),
          ),
        ),
      ),
    );
  }
}

/// iOS-styled Tool Button Pill in the bottom toolbar.
class _ToolItem extends StatelessWidget {
  const _ToolItem({
    required this.tool,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final DrawingTool tool;
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(48, 50),
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? IOSColors.brandPrimary.withValues(alpha: 0.28)
                  : const Color(0xFFD8EEFF)) // Exact soft blue pill container from Feature Graphic
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isActive
              ? Border.all(
                  color: IOSColors.brandPrimary.withValues(alpha: 0.4),
                  width: 1.0,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? IOSColors.brandPrimary
                  : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? IOSColors.brandPrimary
                    : (isDark ? IOSColors.systemGray : const Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-styled Action Item (Undo, Redo, Layers, Share, Clear).
class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isEnabled = true,
    this.isActive = false,
    this.highlightColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isEnabled;
  final bool isActive;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = highlightColor ?? IOSColors.brandPrimary;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 52),
      onPressed: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive ? Border.all(color: color.withValues(alpha: 0.5), width: 1) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: (isActive || highlightColor != null)
                    ? color
                    : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: (isActive || highlightColor != null)
                      ? color
                      : (isDark ? IOSColors.systemGray : const Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
