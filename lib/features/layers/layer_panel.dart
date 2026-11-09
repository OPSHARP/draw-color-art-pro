import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../canvas/models/canvas_document.dart';
import '../canvas/providers/canvas_providers.dart';
import '../canvas/widgets/canvas_background_modal.dart';
import '../canvas/widgets/image_source_modal.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../core/constants/design_tokens.dart';

/// iOS-styled slide-over panel for layer management.
///
/// Features Apple HIG frosted glass background, Cupertino buttons and sliders,
/// haptic feedback, and CupertinoActionSheet context menus.
class LayerPanel extends ConsumerWidget {
  const LayerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(canvasDocumentProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
      child: BackdropFilter(
        filter: AppBlur.sheet,
        child: Container(
          width: 270,
          decoration: BoxDecoration(
            color: isDark ? IOSColors.frostedDark : IOSColors.frostedLight,
            border: Border(
              left: BorderSide(
                color: isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              // ── iOS Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                child: Row(
                  children: [
                    Text(
                      'Layers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    // + Add Layer Button
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(32, 32),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        SoundEffectService.instance.playPop();
                        ref.read(canvasDocumentProvider.notifier).addLayer();
                      },
                      child: const Icon(
                        CupertinoIcons.plus_circle_fill,
                        size: 22,
                        color: IOSColors.brandPrimary,
                      ),
                    ),
                    // ••• Overflow Menu
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      minimumSize: const Size(32, 32),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _showPanelActionSheet(context, ref, document);
                      },
                      child: Icon(
                        CupertinoIcons.ellipsis_circle,
                        size: 22,
                        color: isDark ? IOSColors.systemGray : IOSColors.systemGray2,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 0.5,
                thickness: 0.5,
                color: isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator,
              ),

              // ── Layer List (Reorderable) ──
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  itemCount: document.layers.length,
                  onReorderItem: (oldIndex, newIndex) {
                    HapticFeedback.mediumImpact();
                    ref
                        .read(canvasDocumentProvider.notifier)
                        .reorderLayers(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    // Top layer = first in UI
                    final displayIndex = document.layers.length - 1 - index;
                    final layer = document.layers[displayIndex];
                    final isActive = displayIndex == document.activeLayerIndex;

                    return _IOSLayerTile(
                      key: ValueKey(layer.id),
                      layer: layer,
                      index: displayIndex,
                      isActive: isActive,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        SoundEffectService.instance.playPop();
                        ref
                            .read(canvasDocumentProvider.notifier)
                            .setActiveLayer(displayIndex);
                      },
                      onToggleVisibility: () {
                        HapticFeedback.selectionClick();
                        SoundEffectService.instance.playPop();
                        ref
                            .read(canvasDocumentProvider.notifier)
                            .toggleLayerVisibility(displayIndex);
                      },
                      onToggleLock: () {
                        HapticFeedback.selectionClick();
                        SoundEffectService.instance.playPop();
                        ref
                            .read(canvasDocumentProvider.notifier)
                            .toggleLayerLock(displayIndex);
                      },
                      onToggleAlphaLock: () {
                        HapticFeedback.selectionClick();
                        SoundEffectService.instance.playPop();
                        ref
                            .read(canvasDocumentProvider.notifier)
                            .toggleLayerAlphaLock(displayIndex);
                      },
                      onToggleClipping: () {
                        HapticFeedback.selectionClick();
                        SoundEffectService.instance.playPop();
                        ref
                            .read(canvasDocumentProvider.notifier)
                            .toggleLayerClipping(displayIndex);
                      },
                      onDelete: () {
                        HapticFeedback.heavyImpact();
                        SoundEffectService.instance.playWhoosh();
                        ref
                            .read(canvasDocumentProvider.notifier)
                            .deleteLayer(displayIndex);
                      },
                      onDuplicate: () {
                        HapticFeedback.mediumImpact();
                        SoundEffectService.instance.playPop();
                        ref
                            .read(canvasDocumentProvider.notifier)
                            .duplicateLayer(displayIndex);
                      },
                      onOpacityChanged: (v) => ref
                          .read(canvasDocumentProvider.notifier)
                          .setLayerOpacity(displayIndex, v),
                    );
                  },
                ),
              ),

              Divider(
                height: 0.5,
                thickness: 0.5,
                color: isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator,
              ),

              // ── Canvas Background Layer (Bottom of stack) ──
              _IOSCanvasBackgroundTile(
                document: document,
                onTap: () {
                  HapticFeedback.lightImpact();
                  CanvasBackgroundModal.show(context, ref);
                },
                onToggleVisibility: () {
                  HapticFeedback.selectionClick();
                  SoundEffectService.instance.playPop();
                  ref.read(canvasDocumentProvider.notifier).setBackgroundColor(
                        document.backgroundColor,
                        transparent: !document.isTransparentBackground,
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPanelActionSheet(BuildContext context, WidgetRef ref, CanvasDocument document) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Layer Actions'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              ImageSourceModal.show(context, ref);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, size: 18, color: IOSColors.brandPrimary),
                SizedBox(width: 8),
                Text('Import Photo as Layer'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.lightImpact();
              SoundEffectService.instance.playPop();
              ref.read(canvasDocumentProvider.notifier).addLayer(
                name: 'Text Layer',
                type: LayerType.text,
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.textformat, size: 18, color: IOSColors.systemPurple),
                SizedBox(width: 8),
                Text('Add Text Layer'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.lightImpact();
              SoundEffectService.instance.playPop();
              ref.read(canvasDocumentProvider.notifier).addLayer(
                name: 'Shape Layer',
                type: LayerType.paint,
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.square_on_circle, size: 18, color: IOSColors.systemOrange),
                SizedBox(width: 8),
                Text('Add Shape Layer'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              SoundEffectService.instance.playWhoosh();
              ref.read(canvasDocumentProvider.notifier).mergeDown(document.activeLayerIndex);
            },
            child: const Text('Merge Down'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              SoundEffectService.instance.playWhoosh();
              ref.read(canvasDocumentProvider.notifier).flattenVisible();
            },
            child: const Text('Flatten Visible Layers'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              SoundEffectService.instance.playWhoosh();
              ref.read(canvasDocumentProvider.notifier).flattenAll();
            },
            isDestructiveAction: true,
            child: const Text('Flatten All Layers'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

/// Single iOS-style layer card tile.
class _IOSLayerTile extends StatelessWidget {
  const _IOSLayerTile({
    super.key,
    required this.layer,
    required this.index,
    required this.isActive,
    required this.onTap,
    required this.onToggleVisibility,
    required this.onToggleLock,
    required this.onToggleAlphaLock,
    required this.onToggleClipping,
    required this.onDelete,
    required this.onDuplicate,
    required this.onOpacityChanged,
  });

  final LayerModel layer;
  final int index;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;
  final VoidCallback onToggleLock;
  final VoidCallback onToggleAlphaLock;
  final VoidCallback onToggleClipping;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final ValueChanged<double> onOpacityChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.standard,
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? IOSColors.brandPrimary.withValues(alpha: 0.22)
                  : IOSColors.brandPrimary.withValues(alpha: 0.10))
              : (isDark
                  ? IOSColors.darkElevated.withValues(alpha: 0.5)
                  : IOSColors.lightSurface.withValues(alpha: 0.7)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? IOSColors.brandPrimary.withValues(alpha: 0.5)
                : (isDark ? IOSColors.darkSeparator.withValues(alpha: 0.3) : Colors.black12),
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Clipping Mask Indicator
                if (layer.isClipping) ...[
                  const Icon(
                    CupertinoIcons.arrow_turn_down_right,
                    size: 14,
                    color: IOSColors.brandPrimary,
                  ),
                  const SizedBox(width: 4),
                ],

                // Layer Type Badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? IOSColors.darkElevated : IOSColors.systemGray6,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        _getCupertinoLayerIcon(layer.type),
                        size: 15,
                        color: isActive
                            ? IOSColors.brandPrimary
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                      if (layer.isAlphaLocked)
                        const Positioned(
                          right: 2,
                          bottom: 2,
                          child: Icon(
                            CupertinoIcons.shield_fill,
                            size: 8,
                            color: IOSColors.brandPrimary,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Layer Name & Meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        layer.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${layer.blendMode.label} · ${(layer.opacity * 100).round()}%${layer.isAlphaLocked ? ' · 🔒' : ''}${layer.isClipping ? ' · ⮑' : ''}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? IOSColors.systemGray : IOSColors.systemGray2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Visibility Toggle (Eye)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(26, 26),
                  onPressed: onToggleVisibility,
                  child: Icon(
                    layer.isVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    size: 16,
                    color: layer.isVisible
                        ? (isActive ? IOSColors.brandPrimary : (isDark ? Colors.white70 : Colors.black54))
                        : (isDark ? IOSColors.darkSeparator : IOSColors.systemGray4),
                  ),
                ),

                // Lock Toggle
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(26, 26),
                  onPressed: onToggleLock,
                  child: Icon(
                    layer.isLocked ? CupertinoIcons.lock_fill : CupertinoIcons.lock_open,
                    size: 14,
                    color: layer.isLocked
                        ? IOSColors.systemOrange
                        : (isDark ? IOSColors.darkSeparator : IOSColors.systemGray4),
                  ),
                ),

                // Action Sheet Menu for this Layer
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(24, 26),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showLayerItemMenu(context);
                  },
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    size: 14,
                    color: isDark ? IOSColors.systemGray : IOSColors.systemGray2,
                  ),
                ),
              ],
            ),

            // Opacity slider (when active)
            if (isActive) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Opacity',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? IOSColors.systemGray : IOSColors.systemGray2,
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 24,
                      child: CupertinoSlider(
                        value: layer.opacity,
                        activeColor: IOSColors.brandPrimary,
                        onChanged: onOpacityChanged,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${(layer.opacity * 100).round()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLayerItemMenu(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(layer.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onToggleAlphaLock();
            },
            child: Text(layer.isAlphaLocked ? 'Disable Alpha Lock' : 'Enable Alpha Lock'),
          ),
          if (index > 0)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                onToggleClipping();
              },
              child: Text(layer.isClipping ? 'Release Clipping Mask' : 'Create Clipping Mask'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onDuplicate();
            },
            child: const Text('Duplicate Layer'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Delete Layer'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  IconData _getCupertinoLayerIcon(LayerType type) {
    return switch (type) {
      LayerType.paint => CupertinoIcons.paintbrush,
      LayerType.sketch => CupertinoIcons.pencil,
      LayerType.lineArt => CupertinoIcons.pen,
      LayerType.image => CupertinoIcons.photo,
      LayerType.text => CupertinoIcons.textformat,
      LayerType.adjustment => CupertinoIcons.slider_horizontal_3,
      LayerType.group => CupertinoIcons.folder,
    };
  }
}

/// Dedicated bottom tile in LayerPanel showing and controlling the canvas background.
class _IOSCanvasBackgroundTile extends StatelessWidget {
  const _IOSCanvasBackgroundTile({
    required this.document,
    required this.onTap,
    required this.onToggleVisibility,
  });

  final CanvasDocument document;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTrans = document.isTransparentBackground;
    final bgColor = document.backgroundColor;

    final presetName = isTrans
        ? 'Transparent'
        : (CanvasBackgroundPreset.allPresets
                .where((p) => !p.isTransparent && p.color == bgColor)
                .firstOrNull
                ?.name ??
            '#${bgColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}');

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? IOSColors.darkElevated.withValues(alpha: 0.3) : IOSColors.lightSurface,
        ),
        child: Row(
          children: [
            // Visibility toggle (Solid vs Transparent)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(24, 24),
              onPressed: onToggleVisibility,
              child: Icon(
                isTrans ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                size: 16,
                color: isTrans
                    ? IOSColors.systemGray
                    : IOSColors.brandPrimary,
              ),
            ),
            const SizedBox(width: 8),

            // Background Color Preview Swatch
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTrans ? Colors.transparent : bgColor,
                border: Border.all(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
              child: isTrans
                  ? const Icon(CupertinoIcons.square_grid_2x2, size: 12, color: Colors.blueGrey)
                  : null,
            ),
            const SizedBox(width: 10),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Canvas Background',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    presetName,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? IOSColors.systemGray : IOSColors.systemGray2,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: isDark ? IOSColors.systemGray : IOSColors.systemGray3,
            ),
          ],
        ),
      ),
    );
  }
}
