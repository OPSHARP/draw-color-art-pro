import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tools.dart';
import '../providers/canvas_providers.dart';
import 'symmetry_modal.dart';
import 'timelapse_replay_modal.dart';
import '../../ar_tracing/views/ar_tracing_screen.dart';
import '../../../core/constants/design_tokens.dart';
import 'drawing_guides_modal.dart';
import 'color_adjustments_modal.dart';
import 'inspiration_modal.dart';
import 'image_source_modal.dart';
import '../../../core/audio/ambient_audio_sheet.dart';
import '../../../core/audio/ambient_sound_service.dart';
import '../../../app.dart';
import '../../../core/audio/sound_effect_service.dart';
import 'thumbnail_save_modal.dart';
import 'thumbnail_tools_modal.dart';

/// iOS-style frosted glass top bar for the drawing workspace matching the Feature Graphic.
class DrawingTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const DrawingTopBar({
    super.key,
    this.onBack,
    this.onExport,
    this.onToggleReference,
    this.onImportPhoto,
    this.onToggleLayerPanel,
    this.isLayerPanelOpen = false,
  });

  final VoidCallback? onBack;
  final VoidCallback? onExport;
  final VoidCallback? onToggleReference;
  final VoidCallback? onImportPhoto;
  final VoidCallback? onToggleLayerPanel;
  final bool isLayerPanelOpen;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(canvasDocumentProvider);
    final viewState = ref.watch(canvasViewProvider);
    final undoRedo = ref.watch(undoRedoProvider);
    final saveStatus = ref.watch(saveStatusProvider);
    final symmetry = ref.watch(symmetryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final media = MediaQuery.of(context);
    final topInset = max(max(media.padding.top, media.viewPadding.top), 14.0);
    final sideInset = max(media.padding.left, media.padding.right);

    return ClipRect(
      child: BackdropFilter(
        filter: AppBlur.toolbar,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? IOSColors.frostedDark
                : IOSColors.frostedLight,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? IOSColors.darkSeparator
                    : IOSColors.lightSeparator,
                width: 0.5,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: topInset,
            bottom: 6,
            left: max(8.0, sideInset),
            right: max(8.0, sideInset),
          ),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                // ── 1. Home Button (Clean Rounded House Icon from Feature Graphic) ──
                Tooltip(
                  message: 'Back',
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(36, 36),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      SoundEffectService.instance.playPop();
                      onBack?.call();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? IOSColors.darkElevated
                            : IOSColors.systemGray6,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.house_fill,
                        size: 19,
                        color: IOSColors.brandPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // ── 2. Undo ──
                Tooltip(
                  message: 'Undo',
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(34, 34),
                    onPressed: undoRedo.canUndo
                        ? () {
                            HapticFeedback.mediumImpact();
                            SoundEffectService.instance.playWhoosh();
                            ref.read(undoRedoProvider.notifier).undo();
                          }
                        : null,
                    child: Icon(
                      CupertinoIcons.arrow_uturn_left,
                      size: 20,
                      color: undoRedo.canUndo
                          ? IOSColors.brandPrimary
                          : (isDark
                              ? IOSColors.darkElevated
                              : IOSColors.systemGray4),
                    ),
                  ),
                ),

                // ── 3. Redo ──
                Tooltip(
                  message: 'Redo',
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(34, 34),
                    onPressed: undoRedo.canRedo
                        ? () {
                            HapticFeedback.mediumImpact();
                            SoundEffectService.instance.playPop();
                            ref.read(undoRedoProvider.notifier).redo();
                          }
                        : null,
                    child: Icon(
                      CupertinoIcons.arrow_uturn_right,
                      size: 20,
                      color: undoRedo.canRedo
                          ? IOSColors.brandPrimary
                          : (isDark
                              ? IOSColors.darkElevated
                              : IOSColors.systemGray4),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // ── 4. Project Name & Zoom Indicator ──
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showZoomMenu(context, ref, viewState, document);
                    },
                    child: Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              document.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _IOSSaveIndicator(status: saveStatus, isDark: isDark),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? IOSColors.darkElevated
                                  : IOSColors.systemGray6,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${viewState.zoomPercent}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? IOSColors.systemGray2
                                    : IOSColors.systemGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                if (document.isThumbnail || document.name.toLowerCase().contains('thumbnail')) ...[
                  // ── Thumbnail Pro Suite Button (Palettes & Badges) ──
                  Tooltip(
                    message: 'Thumbnail Pro Suite (Palettes & Badges)',
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(36, 36),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        SoundEffectService.instance.playPop();
                        ThumbnailToolsModal.show(context);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF2A6D),
                              Color(0xFF9B51E0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2A6D).withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                // ── 5. Direct Save to Phone Gallery Button (JPG / PNG) ──
                Tooltip(
                  message: 'Save to Gallery (JPG / PNG)',
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(36, 36),
                    onPressed: () => _saveDirectToGallery(context, ref),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            IOSColors.brandPrimary,
                            IOSColors.brandSecondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: IOSColors.brandPrimary.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_down_to_line,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // ── 6. Layers Toggle Button (from Graphic) ──
                Tooltip(
                  message: 'Layers',
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(36, 36),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      SoundEffectService.instance.playPop();
                      onToggleLayerPanel?.call();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isLayerPanelOpen
                            ? IOSColors.brandPrimary.withValues(alpha: 0.15)
                            : (isDark ? IOSColors.darkElevated : IOSColors.systemGray6),
                        borderRadius: BorderRadius.circular(10),
                        border: isLayerPanelOpen
                            ? Border.all(color: IOSColors.brandPrimary, width: 1.5)
                            : null,
                      ),
                      child: Icon(
                        CupertinoIcons.square_stack_3d_up,
                        size: 19,
                        color: isLayerPanelOpen
                            ? IOSColors.brandPrimary
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 2),

                // ── 7. Creative Tools Overflow (•••) ──
                Tooltip(
                  message: 'Tools & Options',
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(36, 36),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showToolsMenu(context, ref, document, symmetry);
                    },
                    child: Icon(
                      CupertinoIcons.ellipsis_vertical,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Saves the current drawing directly into the user's phone gallery (Photos)
  /// allowing choice between JPG and PNG with scale options.
  Future<void> _saveDirectToGallery(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    SoundEffectService.instance.playWhoosh();
    final doc = ref.read(canvasDocumentProvider);
    ThumbnailSaveModal.show(context, doc);
  }

  void _showZoomMenu(BuildContext context, WidgetRef ref, dynamic viewState, dynamic document) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Canvas Zoom: ${viewState.zoomPercent}%'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(canvasViewProvider.notifier).zoomIn();
            },
            child: const Text('Zoom In (+25%)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(canvasViewProvider.notifier).zoomOut();
            },
            child: const Text('Zoom Out (-20%)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(canvasViewProvider.notifier).setZoom(1.0);
            },
            child: const Text('Actual Size (100%)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(canvasViewProvider.notifier).fitToScreen(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height - 120,
                    document.width,
                    document.height,
                  );
            },
            child: const Text('Fit to Screen'),
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

  Widget _sheetActionRow(Widget icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showToolsMenu(BuildContext context, WidgetRef ref, dynamic document, dynamic symmetry) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Creative Tools'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              ThumbnailToolsModal.show(context);
            },
            child: _sheetActionRow(
              const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFFFF2A6D)),
              'Thumbnail Pro Suite',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onImportPhoto != null
                  ? onImportPhoto!()
                  : ImageSourceModal.show(context, ref);
            },
            child: _sheetActionRow(
              const Icon(CupertinoIcons.photo_on_rectangle, size: 18, color: IOSColors.brandPrimary),
              'Insert Photo / Image...',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onToggleReference?.call();
            },
            child: _sheetActionRow(
              const Icon(CupertinoIcons.photo, size: 18),
              'Reference Image',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              ColorAdjustmentsModal.show(context);
            },
            child: _sheetActionRow(
              const Icon(CupertinoIcons.slider_horizontal_3, size: 18),
              'Color Adjustments & Filters',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              InspirationModal.show(context);
            },
            child: _sheetActionRow(
              const Icon(CupertinoIcons.lightbulb_fill, size: 18, color: IOSColors.systemYellow),
              'Inspiration Studio & Prompts',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              DrawingGuidesModal.show(context);
            },
            child: _sheetActionRow(
              const Icon(CupertinoIcons.grid, size: 18),
              'Perspective & Grid Guides',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              AmbientAudioSheet.show(context);
            },
            child: _sheetActionRow(
              ValueListenableBuilder<bool>(
                valueListenable: AmbientSoundService.instance.isPlayingNotifier,
                builder: (_, isPlaying, __) => Icon(
                  CupertinoIcons.headphones,
                  size: 18,
                  color: isPlaying ? IOSColors.systemOrange : null,
                ),
              ),
              'Ambient Soundscapes',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              SymmetryModal.show(context);
            },
            child: _sheetActionRow(
              Icon(
                CupertinoIcons.circle_grid_hex,
                size: 18,
                color: symmetry.isEnabled ? IOSColors.brandPrimary : null,
              ),
              symmetry.isEnabled
                  ? 'Symmetry (${symmetry.mode.label})'
                  : 'Symmetry Studio',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              TimelapseReplayModal.show(context, document);
            },
            child: _sheetActionRow(
              const Icon(CupertinoIcons.film, size: 18),
              'Timelapse Replay',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              final allStrokes =
                  document.layers.expand((l) => l.strokes).toList();
              Navigator.of(context).push(
                IOSPageRoute(
                  builder: (_) => ArTracingScreen(
                    customStrokes:
                        allStrokes.isNotEmpty ? allStrokes : null,
                    templateTitle: document.name,
                  ),
                ),
              );
            },
            child: _sheetActionRow(
              const Icon(CupertinoIcons.camera, size: 18),
              'AR Tracing',
            ),
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

/// iOS-style save status indicator.
class _IOSSaveIndicator extends StatelessWidget {
  const _IOSSaveIndicator({required this.status, required this.isDark});
  final SaveStatus status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      SaveStatus.saved => (CupertinoIcons.checkmark_circle_fill, IOSColors.systemGreen),
      SaveStatus.saving => (CupertinoIcons.arrow_2_circlepath, IOSColors.brandPrimary),
      SaveStatus.offline => (Icons.cloud_off, IOSColors.systemOrange),
      SaveStatus.syncing => (CupertinoIcons.cloud, IOSColors.brandPrimary),
      SaveStatus.error => (CupertinoIcons.exclamationmark_circle, IOSColors.systemRed),
    };

    return Tooltip(
      message: status.label,
      child: Icon(icon, size: 16, color: color),
    );
  }
}
