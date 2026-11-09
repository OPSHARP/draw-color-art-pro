import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import '../../home/home_screen.dart';
import '../models/tools.dart';
import '../models/canvas_document.dart';
import '../widgets/canvas_widget.dart';
import '../widgets/drawing_top_bar.dart';
import '../widgets/floating_reference_companion.dart';
import '../widgets/horizontal_bottom_toolbar.dart';
import '../widgets/color_adjustments_modal.dart';
import '../widgets/inspiration_modal.dart';
import '../widgets/image_placement_overlay.dart';
import '../widgets/image_source_modal.dart';
import '../providers/canvas_providers.dart';
import '../../layers/layer_panel.dart';
import '../../colors/color_picker_panel.dart';
import '../../export/views/social_share_dialog.dart';
import '../../projects/services/project_storage_service.dart';
import '../../projects/providers/project_providers.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../widgets/radial_quick_menu.dart';
import '../widgets/animation_timeline_modal.dart';
import '../../../core/constants/design_tokens.dart';

/// The main drawing workspace screen.
class DrawingScreen extends ConsumerStatefulWidget {
  const DrawingScreen({super.key});

  @override
  ConsumerState<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends ConsumerState<DrawingScreen> with WidgetsBindingObserver {
  bool _showLayerPanel = false;
  bool _showColorPicker = false;
  bool _showReferenceCompanion = false;
  bool _isRightMenuMinimized = false;
  Timer? _autoSaveDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Edge-to-edge mode so navigation keys and notification bar never clip or cover tools
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveDebounceTimer?.cancel();
    _saveProjectImmediately();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _saveProjectImmediately();
    }
  }

  Future<void> _saveProjectImmediately() async {
    try {
      final doc = ref.read(canvasDocumentProvider);
      ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
      await ProjectStorageService.instance.saveProject(doc);
      if (mounted) {
        ref.read(saveStatusProvider.notifier).state = SaveStatus.saved;
        ref.read(projectListProvider.notifier).loadProjects();
      }
    } catch (_) {
      // Ignored in offline / test environments
    }
  }

  void _triggerDebouncedAutoSave() {
    _autoSaveDebounceTimer?.cancel();
    _autoSaveDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _saveProjectImmediately();
    });
  }

  void _handleBack() {
    try {
      final doc = ref.read(canvasDocumentProvider);
      unawaited(ProjectStorageService.instance.saveProject(doc).then((_) {
        try {
          ref.read(projectListProvider.notifier).loadProjects();
        } catch (_) {}
      }));
    } catch (_) {
      // Ignored in test / offline environments
    }
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for canvas document changes and automatically auto-save user work
    ref.listen<CanvasDocument>(canvasDocumentProvider, (prev, next) {
      if (prev != null &&
          (prev.layers != next.layers ||
           prev.name != next.name ||
           prev.backgroundColor != next.backgroundColor)) {
        _triggerDebouncedAutoSave();
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? const Color(0xFF18182E) : Colors.white,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _handleBack();
        },
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF16162A) : Colors.white,
          body: Container(
            color: isDark ? const Color(0xFF16162A) : Colors.white,
          child: Column(
            children: [
              // ── Top Bar ──
              DrawingTopBar(
                onBack: _handleBack,
                onToggleLayerPanel: () =>
                    setState(() => _showLayerPanel = !_showLayerPanel),
                isLayerPanelOpen: _showLayerPanel,
                onToggleReference: () =>
                    setState(() => _showReferenceCompanion = !_showReferenceCompanion),
                onImportPhoto: () => ImageSourceModal.show(
                  context,
                  ref,
                  onOpenReferenceCompanion: () =>
                      setState(() => _showReferenceCompanion = true),
                ),
                onExport: () {
                  final doc = ref.read(canvasDocumentProvider);
                  SocialShareDialog.show(context, doc);
                },
              ),

              // ── Full-Width Canvas Workspace ──
              Expanded(
                child: Stack(
                  children: [
                    const CanvasWidget(),

                    // ── Placed Photo Interactive Transform Overlay ──
                    const ImagePlacementOverlay(),

                    // ── Floating Right Tool Menu (Minimizable) ──
                    if (!_showLayerPanel)
                      Positioned(
                        right: _isRightMenuMinimized ? 0 : 14,
                        top: _isRightMenuMinimized ? 52 : 36,
                        child: _RightFloatingToolMenu(
                          ref: ref,
                          isColorPickerOpen: _showColorPicker,
                          onToggleColorPicker: () =>
                              setState(() => _showColorPicker = !_showColorPicker),
                          isMinimized: _isRightMenuMinimized,
                          onToggleMinimize: () =>
                              setState(() => _isRightMenuMinimized = !_isRightMenuMinimized),
                        ),
                      ),

                    // ── Color Picker Overlay ──
                    if (_showColorPicker)
                      Positioned(
                        left: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        top: AppSpacing.sm,
                        child: ColorPickerPanel(
                          onClose: () => setState(() => _showColorPicker = false),
                        ),
                      ),

                    // ── Layer Panel Overlay ──
                    if (_showLayerPanel)
                      const Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: LayerPanel(),
                      ),

                    // ── Floating Picture-in-Picture Reference Companion ──
                    if (_showReferenceCompanion)
                      FloatingReferenceCompanion(
                        onClose: () => setState(() => _showReferenceCompanion = false),
                      ),
                  ],
                ),
              ),

              // ── Horizontally Scrolling Toolbar Pinned to Bottom ──
              HorizontalBottomToolbar(
                isColorPickerOpen: _showColorPicker,
                isLayerPanelOpen: _showLayerPanel,
                onToggleColorPicker: () => setState(() => _showColorPicker = !_showColorPicker),
                onToggleLayerPanel: () => setState(() => _showLayerPanel = !_showLayerPanel),
                onShareArt: () {
                  final doc = ref.read(canvasDocumentProvider);
                  SocialShareDialog.show(context, doc);
                },
                onOpenAdjustments: () => ColorAdjustmentsModal.show(context),
                onOpenInspiration: () => InspirationModal.show(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

/// Floating vertical tool menu on the right side of the canvas.
///
/// Features Apple HIG frosted glass blur, elevation, and 6 core floating options:
/// 1. Draw (Unified Pen & Brush)
/// 2. Eraser
/// 3. Color Picker (Toggle palette panel)
/// 4. Fill
/// 5. Shapes (Shapes & Icons)
/// 6. Text (Typography & Fonts)
class _RightFloatingToolMenu extends StatelessWidget {
  const _RightFloatingToolMenu({
    required this.ref,
    required this.isColorPickerOpen,
    required this.onToggleColorPicker,
    required this.isMinimized,
    required this.onToggleMinimize,
  });

  final WidgetRef ref;
  final bool isColorPickerOpen;
  final VoidCallback onToggleColorPicker;
  final bool isMinimized;
  final VoidCallback onToggleMinimize;

  static const _drawCycle = [
    DrawingTool.pen,
    DrawingTool.brush,
    DrawingTool.pencil,
    DrawingTool.spray,
    DrawingTool.marker,
  ];

  IconData _getToolIcon(DrawingTool tool) {
    return switch (tool) {
      DrawingTool.brush ||
      DrawingTool.pen ||
      DrawingTool.pencil ||
      DrawingTool.marker ||
      DrawingTool.spray => CupertinoIcons.paintbrush,
      DrawingTool.eraser => CupertinoIcons.bandage,
      DrawingTool.fill => CupertinoIcons.drop_fill,
      DrawingTool.shape => CupertinoIcons.square_on_circle,
      DrawingTool.text => CupertinoIcons.textformat,
      DrawingTool.image => CupertinoIcons.photo,
      DrawingTool.eyedropper => CupertinoIcons.eyedropper,
      DrawingTool.selection => CupertinoIcons.selection_pin_in_out,
      DrawingTool.transform => CupertinoIcons.move,
      _ => CupertinoIcons.wrench_fill,
    };
  }

  @override
  Widget build(BuildContext context) {
    final activeTool = ref.watch(activeToolProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDrawActive = activeTool == DrawingTool.brush ||
        activeTool == DrawingTool.pen ||
        activeTool == DrawingTool.pencil ||
        activeTool == DrawingTool.marker ||
        activeTool == DrawingTool.spray;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isMinimized
          ? _buildMinimizedPill(context, isDark, activeTool)
          : _buildExpandedMenu(context, isDark, activeTool, isDrawActive),
    );
  }

  Widget _buildMinimizedPill(BuildContext context, bool isDark, DrawingTool activeTool) {
    return GestureDetector(
      key: const ValueKey('minimized_pill'),
      onTap: () {
        HapticFeedback.selectionClick();
        SoundEffectService.instance.playPop();
        onToggleMinimize();
      },
      child: Tooltip(
        message: 'Expand Tools',
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 48,
              padding: const EdgeInsets.only(left: 8, right: 6, top: 6, bottom: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xE61E1E2E) : const Color(0xF2FFFFFF),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.black.withValues(alpha: 0.10),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                    blurRadius: 14,
                    offset: const Offset(-2, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.chevron_left_2,
                    size: 13,
                    color: IOSColors.brandPrimary,
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: IOSColors.brandPrimary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getToolIcon(activeTool),
                      size: 15,
                      color: IOSColors.brandPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedMenu(
    BuildContext context,
    bool isDark,
    DrawingTool activeTool,
    bool isDrawActive,
  ) {
    return GestureDetector(
      key: const ValueKey('expanded_menu'),
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 80) {
          HapticFeedback.lightImpact();
          SoundEffectService.instance.playPop();
          onToggleMinimize();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xE61E1E2E)
                  : const Color(0xF2FFFFFF),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Minimize Toggle Button (Header) ──
                  Tooltip(
                    message: 'Minimize Tools',
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        SoundEffectService.instance.playPop();
                        onToggleMinimize();
                      },
                      child: Container(
                        height: 22,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.chevron_right_2,
                              size: 11,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Hide',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 1. Draw (cycles: Pen → Brush → Pencil → Airbrush → Marker)
                  _buildMenuItem(
                    icon: CupertinoIcons.paintbrush,
                    label: 'Draw',
                    isActive: isDrawActive,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      SoundEffectService.instance.playPop();
                      if (!isDrawActive) {
                        ref.read(activeToolProvider.notifier).selectTool(DrawingTool.brush);
                      } else {
                        final idx = _drawCycle.indexOf(activeTool);
                        final next = _drawCycle[(idx + 1) % _drawCycle.length];
                        ref.read(activeToolProvider.notifier).selectTool(next);
                      }
                    },
                  ),
                  const SizedBox(height: 4),

                  // 2. Eraser
                  _buildMenuItem(
                    icon: CupertinoIcons.bandage,
                    label: 'Eraser',
                    isActive: activeTool == DrawingTool.eraser,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      SoundEffectService.instance.playPop();
                      ref.read(activeToolProvider.notifier).selectTool(DrawingTool.eraser);
                    },
                  ),
                  const SizedBox(height: 4),

                  // 3. Quick Color
                  _buildMenuItem(
                    icon: CupertinoIcons.color_filter,
                    label: 'Quick Color',
                    isActive: isColorPickerOpen,
                    isDark: isDark,
                    customColor: IOSColors.brandPrimary,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      SoundEffectService.instance.playPop();
                      onToggleColorPicker();
                    },
                  ),
                  const SizedBox(height: 4),

                  // 4. Fill Bucket
                  _buildMenuItem(
                    icon: CupertinoIcons.drop_fill,
                    label: 'Fill',
                    isActive: activeTool == DrawingTool.fill,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      SoundEffectService.instance.playPop();
                      ref.read(activeToolProvider.notifier).selectTool(DrawingTool.fill);
                    },
                  ),
                  const SizedBox(height: 4),

                  // 5. Shapes & Icons (Instant tool switch, Library chip in options strip)
                  _buildMenuItem(
                    icon: CupertinoIcons.square_on_circle,
                    label: 'Shapes',
                    isActive: activeTool == DrawingTool.shape,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      SoundEffectService.instance.playPop();
                      ref.read(activeToolProvider.notifier).selectTool(DrawingTool.shape);
                    },
                  ),
                  const SizedBox(height: 4),

                  // 6. Text & Fonts (Instant tool switch, font picker pill in options strip)
                  _buildMenuItem(
                    icon: CupertinoIcons.textformat,
                    label: 'Text',
                    isActive: activeTool == DrawingTool.text,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      SoundEffectService.instance.playPop();
                      ref.read(activeToolProvider.notifier).selectTool(DrawingTool.text);
                    },
                  ),
                  const SizedBox(height: 4),

                  // 7. Radial QuickMenu
                  _buildMenuItem(
                    icon: CupertinoIcons.circle_grid_hex_fill,
                    label: 'QuickMenu',
                    isActive: false,
                    isDark: isDark,
                    customColor: const Color(0xFFFF9F0A),
                    onTap: () {
                      RadialQuickMenu.show(
                        context,
                        onOpenColorPicker: onToggleColorPicker,
                        onOpenAnimationTimeline: () => AnimationTimelineModal.show(context),
                      );
                    },
                  ),
                  const SizedBox(height: 4),

                  // 8. Animation Timeline
                  _buildMenuItem(
                    icon: CupertinoIcons.play_rectangle,
                    label: 'Flipbook',
                    isActive: false,
                    isDark: isDark,
                    customColor: const Color(0xFF30D158),
                    onTap: () {
                      AnimationTimelineModal.show(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isDark,
    Color? customColor,
    required VoidCallback onTap,
  }) {
    final activeColor = customColor ?? IOSColors.brandPrimary;

    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? (isDark
                    ? activeColor.withValues(alpha: 0.28)
                    : activeColor.withValues(alpha: 0.15))
                : Colors.transparent,
            border: isActive
                ? Border.all(
                    color: activeColor.withValues(alpha: isDark ? 0.7 : 0.5),
                    width: 1.2,
                  )
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: isDark ? 0.35 : 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isActive
                  ? (isDark ? const Color(0xFF64B5F6) : activeColor)
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
