import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/canvas_providers.dart';
import '../providers/image_import_providers.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Interactive on-canvas placement overlay for imported photos.
///
/// Features Apple HIG frosted glass control pill, intuitive multi-touch transform,
/// 4-corner scale handles, rotation knob with angle snapping, live opacity adjustment,
/// blend mode switching, and 1-tap layer committing.
class ImagePlacementOverlay extends ConsumerStatefulWidget {
  const ImagePlacementOverlay({super.key});

  @override
  ConsumerState<ImagePlacementOverlay> createState() => _ImagePlacementOverlayState();
}

class _ImagePlacementOverlayState extends ConsumerState<ImagePlacementOverlay> {
  Offset _dragStartScreenPos = Offset.zero;
  Offset _initialPlacedPos = Offset.zero;
  Size _initialPlacedSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    final placed = ref.watch(placedImageProvider);
    if (placed == null) return const SizedBox.shrink();

    final canvasView = ref.watch(canvasViewProvider);
    final zoom = canvasView.zoom;
    final pan = Offset(canvasView.panX, canvasView.panY);
    final doc = ref.watch(canvasDocumentProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Convert document coordinates to screen coordinates
    final screenLeft = placed.position.dx * zoom + pan.dx;
    final screenTop = placed.position.dy * zoom + pan.dy;
    final screenWidth = placed.size.width * zoom;
    final screenHeight = placed.size.height * zoom;
    final screenCenter = Offset(
      screenLeft + screenWidth / 2,
      screenTop + screenHeight / 2,
    );

    const handleRadius = 14.0;

    return Stack(
      children: [
        // ── 1. Interactive Image Bounding Box ──
        Positioned(
          left: screenLeft - 20,
          top: screenTop - 50,
          width: screenWidth + 40,
          height: screenHeight + 70,
          child: Transform.rotate(
            angle: placed.rotation,
            alignment: Alignment(
              (screenCenter.dx - (screenLeft - 20)) / (screenWidth + 40) * 2 - 1,
              (screenCenter.dy - (screenTop - 50)) / (screenHeight + 70) * 2 - 1,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Image Bounding Frame
                Positioned(
                  left: 20,
                  top: 50,
                  width: screenWidth,
                  height: screenHeight,
                  child: GestureDetector(
                    onPanStart: (d) {
                      setState(() {
                        _dragStartScreenPos = d.globalPosition;
                        _initialPlacedPos = placed.position;
                      });
                    },
                    onPanUpdate: (d) {
                      final deltaScreen = d.globalPosition - _dragStartScreenPos;
                      final deltaDoc = deltaScreen / zoom;
                      ref.read(placedImageProvider.notifier).state = placed.copyWith(
                        position: _initialPlacedPos + deltaDoc,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: IOSColors.brandPrimary,
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: IOSColors.brandPrimary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Opacity(
                        opacity: placed.opacity,
                        child: RawImage(
                          image: placed.image,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                ),

                // Rotation Stem Line
                Positioned(
                  left: 20 + screenWidth / 2 - 1,
                  top: 15,
                  width: 2,
                  height: 35,
                  child: Container(color: IOSColors.brandPrimary),
                ),

                // Rotation Knob Handle
                Positioned(
                  left: 20 + screenWidth / 2 - handleRadius,
                  top: 15 - handleRadius,
                  child: GestureDetector(
                    onPanStart: (d) {
                      setState(() {
                        _dragStartScreenPos = d.globalPosition;
                      });
                    },
                    onPanUpdate: (d) {
                      final currentPos = d.globalPosition;
                      final center = screenCenter;
                      final angle = atan2(currentPos.dy - center.dy, currentPos.dx - center.dx) + (pi / 2);

                      // Snap to 0, 90, 180, 270 degrees within 6 degrees tolerance
                      double finalAngle = angle;
                      final degrees = (finalAngle * 180 / pi) % 360;
                      for (final snapDeg in [0, 90, 180, 270, 360]) {
                        if ((degrees - snapDeg).abs() < 5.0) {
                          finalAngle = snapDeg * pi / 180;
                          HapticFeedback.selectionClick();
                          break;
                        }
                      }

                      ref.read(placedImageProvider.notifier).state = placed.copyWith(
                        rotation: finalAngle,
                      );
                    },
                    child: _buildHandle(
                      icon: CupertinoIcons.arrow_2_circlepath,
                      color: IOSColors.brandPrimary,
                    ),
                  ),
                ),

                // 4 Corner Scale Handles
                // Top-Left (0)
                Positioned(
                  left: 20 - handleRadius,
                  top: 50 - handleRadius,
                  child: _buildCornerHandle(placed, zoom, 0),
                ),
                // Top-Right (1)
                Positioned(
                  left: 20 + screenWidth - handleRadius,
                  top: 50 - handleRadius,
                  child: _buildCornerHandle(placed, zoom, 1),
                ),
                // Bottom-Right (2)
                Positioned(
                  left: 20 + screenWidth - handleRadius,
                  top: 50 + screenHeight - handleRadius,
                  child: _buildCornerHandle(placed, zoom, 2),
                ),
                // Bottom-Left (3)
                Positioned(
                  left: 20 - handleRadius,
                  top: 50 + screenHeight - handleRadius,
                  child: _buildCornerHandle(placed, zoom, 3),
                ),
              ],
            ),
          ),
        ),

        // ── 2. Floating Control Pill Toolbar (Apple Frosted Glass) ──
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: AppBlur.sheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? IOSColors.frostedDark : IOSColors.frostedLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? IOSColors.darkSeparator : IOSColors.lightSeparator,
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Opacity & Fit Quick Preset
                    Row(
                      children: [
                        const Icon(CupertinoIcons.circle_lefthalf_fill, size: 16, color: IOSColors.brandPrimary),
                        const SizedBox(width: 8),
                        Text(
                          '${(placed.opacity * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Expanded(
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
                        // Fit to Canvas
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(28, 28),
                          color: isDark ? IOSColors.darkElevated : IOSColors.systemGray5,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: () => _fitToCanvas(placed, doc),
                          child: Text(
                            'Fit Canvas',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Reset Rotation
                        if (placed.rotation != 0.0)
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            minimumSize: const Size(28, 28),
                            color: isDark ? IOSColors.darkElevated : IOSColors.systemGray5,
                            borderRadius: BorderRadius.circular(8),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              ref.read(placedImageProvider.notifier).state = placed.copyWith(rotation: 0.0);
                            },
                            child: const Icon(CupertinoIcons.arrow_counterclockwise, size: 13),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Bottom Row: Actions (Cancel, Place on Layer, Add as New Layer)
                    Row(
                      children: [
                        // Cancel
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(32, 32),
                          color: isDark ? IOSColors.darkElevated : IOSColors.systemGray5,
                          borderRadius: BorderRadius.circular(10),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            SoundEffectService.instance.playWhoosh();
                            ImagePlacementController.cancel(ref);
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: IOSColors.systemRed),
                          ),
                        ),

                        const Spacer(),

                        // Add as New Layer
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(32, 32),
                          color: isDark ? IOSColors.darkElevated : IOSColors.systemGray5,
                          borderRadius: BorderRadius.circular(10),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            SoundEffectService.instance.playCelebration();
                            ImagePlacementController.commit(ref, asNewLayer: true);
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.square_stack_3d_up, size: 14),
                              SizedBox(width: 5),
                              Text('New Layer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Place on Current Layer (Primary CTA)
                        CupertinoButton.filled(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          borderRadius: BorderRadius.circular(10),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            SoundEffectService.instance.playCelebration();
                            ImagePlacementController.commit(ref, asNewLayer: false);
                          },
                          child: Text(
                            placed.isTracingMode ? 'Start Tracing' : 'Place Image',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerHandle(PlacedImageData placed, double zoom, int corner) {
    return GestureDetector(
      onPanStart: (d) {
        setState(() {
          _dragStartScreenPos = d.globalPosition;
          _initialPlacedPos = placed.position;
          _initialPlacedSize = placed.size;
        });
      },
      onPanUpdate: (d) {
        final deltaDoc = (d.globalPosition - _dragStartScreenPos) / zoom;
        final aspect = placed.aspectRatio;

        double newWidth = _initialPlacedSize.width;
        double newHeight = _initialPlacedSize.height;
        Offset newPos = _initialPlacedPos;

        switch (corner) {
          case 2: // Bottom-Right
            newWidth = max(50.0, _initialPlacedSize.width + deltaDoc.dx);
            newHeight = newWidth / aspect;
            break;
          case 1: // Top-Right
            newWidth = max(50.0, _initialPlacedSize.width + deltaDoc.dx);
            newHeight = newWidth / aspect;
            newPos = Offset(_initialPlacedPos.dx, _initialPlacedPos.dy + (_initialPlacedSize.height - newHeight));
            break;
          case 0: // Top-Left
            newWidth = max(50.0, _initialPlacedSize.width - deltaDoc.dx);
            newHeight = newWidth / aspect;
            newPos = Offset(
              _initialPlacedPos.dx + (_initialPlacedSize.width - newWidth),
              _initialPlacedPos.dy + (_initialPlacedSize.height - newHeight),
            );
            break;
          case 3: // Bottom-Left
            newWidth = max(50.0, _initialPlacedSize.width - deltaDoc.dx);
            newHeight = newWidth / aspect;
            newPos = Offset(
              _initialPlacedPos.dx + (_initialPlacedSize.width - newWidth),
              _initialPlacedPos.dy,
            );
            break;
        }

        ref.read(placedImageProvider.notifier).state = placed.copyWith(
          position: newPos,
          size: Size(newWidth, newHeight),
        );
      },
      child: _buildHandle(
        color: Colors.white,
        borderColor: IOSColors.brandPrimary,
      ),
    );
  }

  Widget _buildHandle({
    IconData? icon,
    Color color = Colors.white,
    Color borderColor = Colors.white,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: icon != null
          ? Center(child: Icon(icon, size: 14, color: Colors.white))
          : null,
    );
  }

  void _fitToCanvas(PlacedImageData placed, dynamic doc) {
    HapticFeedback.selectionClick();
    SoundEffectService.instance.playPop();

    final aspect = placed.aspectRatio;
    double targetW = doc.width.toDouble();
    double targetH = targetW / aspect;

    if (targetH > doc.height.toDouble()) {
      targetH = doc.height.toDouble();
      targetW = targetH * aspect;
    }

    final pos = Offset(
      (doc.width.toDouble() - targetW) / 2,
      (doc.height.toDouble() - targetH) / 2,
    );

    ref.read(placedImageProvider.notifier).state = placed.copyWith(
      position: pos,
      size: Size(targetW, targetH),
      rotation: 0.0,
    );
  }
}
