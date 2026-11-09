import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tools.dart';
import '../providers/canvas_providers.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Interactive high-speed radial pie menu for digital artists.
///
/// Provides rapid access to 8 essential workflow actions arranged circular:
/// 1. Undo
/// 2. Redo
/// 3. Color Picker
/// 4. Eyedropper
/// 5. Flip Layer Horizontal
/// 6. Clear Layer
/// 7. Fit to Screen
/// 8. Flipbook Animation
class RadialQuickMenu extends ConsumerWidget {
  const RadialQuickMenu({
    super.key,
    required this.onClose,
    this.onOpenColorPicker,
    this.onOpenAnimationTimeline,
  });

  final VoidCallback onClose;
  final VoidCallback? onOpenColorPicker;
  final VoidCallback? onOpenAnimationTimeline;

  static void show(
    BuildContext context, {
    VoidCallback? onOpenColorPicker,
    VoidCallback? onOpenAnimationTimeline,
  }) {
    HapticFeedback.mediumImpact();
    SoundEffectService.instance.playPop();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'QuickMenu',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) {
        return RadialQuickMenu(
          onClose: () => Navigator.of(context).pop(),
          onOpenColorPicker: onOpenColorPicker,
          onOpenAnimationTimeline: onOpenAnimationTimeline,
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final undoRedo = ref.watch(undoRedoProvider);

    final actions = [
      (
        icon: CupertinoIcons.arrow_uturn_left,
        label: 'Undo',
        enabled: undoRedo.canUndo,
        onTap: () {
          ref.read(undoRedoProvider.notifier).undo();
          SoundEffectService.instance.playPop();
        },
      ),
      (
        icon: CupertinoIcons.arrow_uturn_right,
        label: 'Redo',
        enabled: undoRedo.canRedo,
        onTap: () {
          ref.read(undoRedoProvider.notifier).redo();
          SoundEffectService.instance.playPop();
        },
      ),
      (
        icon: CupertinoIcons.color_filter,
        label: 'Color',
        enabled: true,
        onTap: () {
          onClose();
          onOpenColorPicker?.call();
        },
      ),
      (
        icon: CupertinoIcons.eyedropper,
        label: 'Picker',
        enabled: true,
        onTap: () {
          ref.read(activeToolProvider.notifier).selectTool(DrawingTool.eyedropper);
          SoundEffectService.instance.playPop();
          onClose();
        },
      ),
      (
        icon: CupertinoIcons.arrow_left_right,
        label: 'Flip',
        enabled: true,
        onTap: () {
          ref.read(canvasDocumentProvider.notifier).flipActiveLayerHorizontal();
          SoundEffectService.instance.playWhoosh();
          onClose();
        },
      ),
      (
        icon: CupertinoIcons.trash,
        label: 'Clear',
        enabled: true,
        onTap: () {
          ref.read(canvasDocumentProvider.notifier).clearActiveLayer();
          SoundEffectService.instance.playEraser();
          onClose();
        },
      ),
      (
        icon: CupertinoIcons.viewfinder,
        label: 'Fit',
        enabled: true,
        onTap: () {
          ref.read(autoFitToScreenProvider.notifier).state = true;
          SoundEffectService.instance.playPop();
          onClose();
        },
      ),
      (
        icon: CupertinoIcons.play_circle,
        label: 'Animate',
        enabled: true,
        onTap: () {
          onClose();
          onOpenAnimationTimeline?.call();
        },
      ),
    ];

    const radius = 108.0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Frosted Glass Circular Core ──
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xD91E1E2E)
                          : const Color(0xE6FFFFFF),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.16)
                            : Colors.black.withValues(alpha: 0.08),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
                          blurRadius: 28,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 8 Radial Action Nodes ──
              for (int i = 0; i < actions.length; i++) ...[
                Builder(
                  builder: (context) {
                    final item = actions[i];
                    // Angle starting from top (-pi/2) and moving clockwise
                    final angle = (-pi / 2) + (i * (2 * pi / actions.length));
                    final x = radius * cos(angle);
                    final y = radius * sin(angle);

                    return Transform.translate(
                      offset: Offset(x, y),
                      child: Tooltip(
                        message: item.label,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(46, 46),
                          onPressed: item.enabled
                              ? () {
                                  HapticFeedback.lightImpact();
                                  item.onTap();
                                }
                              : null,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF2A2A3E)
                                  : const Color(0xFFF1F1F6),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.06),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 19,
                                  color: item.enabled
                                      ? IOSColors.brandPrimary
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    color: item.enabled
                                        ? (isDark ? Colors.white70 : Colors.black87)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],

              // ── Center Dismiss Button ──
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onClose();
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        IOSColors.brandPrimary,
                        IOSColors.brandAccent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: IOSColors.brandPrimary.withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
