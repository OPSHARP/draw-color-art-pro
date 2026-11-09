import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../models/stroke.dart';
import '../models/tools.dart';
import '../providers/canvas_providers.dart';
import '../providers/image_import_providers.dart';
import '../services/image_cache_service.dart';
import 'floating_reference_companion.dart';
import 'image_search_modal.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Apple HIG Cupertino modal sheet for importing photos from the device gallery or camera.
class ImageSourceModal {
  ImageSourceModal._();

  static final ImagePicker _picker = ImagePicker();

  /// Present the iOS-styled image source action sheet.
  static void show(
    BuildContext context,
    WidgetRef ref, {
    VoidCallback? onOpenReferenceCompanion,
  }) {
    HapticFeedback.lightImpact();
    SoundEffectService.instance.playPop();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text(
          'Insert Photo / Image',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        message: const Text(
          'Select a photo from your gallery or capture one with your camera to draw and design on canvas.',
        ),
        actions: [
          // 1. Photo Gallery
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickAndPlaceImage(
                context,
                ref,
                source: ImageSource.gallery,
                isTracing: false,
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo_on_rectangle, size: 20, color: IOSColors.brandPrimary),
                SizedBox(width: 10),
                Text('Choose from Photo Gallery'),
              ],
            ),
          ),

          // 2. Camera
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickAndPlaceImage(
                context,
                ref,
                source: ImageSource.camera,
                isTracing: false,
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, size: 20, color: IOSColors.systemGreen),
                SizedBox(width: 10),
                Text('Take Photo with Camera'),
              ],
            ),
          ),

          // 3. Trace & Sketch Mode
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickAndPlaceImage(
                context,
                ref,
                source: ImageSource.gallery,
                isTracing: true,
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.pencil_outline, size: 20, color: IOSColors.systemIndigo),
                SizedBox(width: 10),
                Text('Trace & Sketch Mode (35% Opacity)'),
              ],
            ),
          ),

          // 4. Extract Color Palette
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _extractPaletteFromPhoto(context, ref);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.eyedropper_halffull, size: 20, color: IOSColors.systemOrange),
                SizedBox(width: 10),
                Text('Extract Color Palette from Photo'),
              ],
            ),
          ),

          // 5. Open in Floating Reference Window
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _openInReferenceCompanion(context, ref, onOpenReferenceCompanion);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.rectangle_on_rectangle_angled, size: 20, color: IOSColors.systemPink),
                SizedBox(width: 10),
                Text('Open as Floating Reference Photo'),
              ],
            ),
          ),

          // 6. Search Free Stock Photos
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              ImageSearchModal.show(context);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.search, size: 20, color: Color(0xFF00B894)),
                SizedBox(width: 10),
                Text('Search Free Stock Photos'),
              ],
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

  /// Pick an image and initialize placement on the canvas.
  static Future<void> _pickAndPlaceImage(
    BuildContext context,
    WidgetRef ref, {
    required ImageSource source,
    required bool isTracing,
  }) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 2560,
        maxHeight: 2560,
        imageQuality: 92,
      );
      if (xFile == null) return;

      final persistentPath = await ImageCacheService.instance.persistPickedImage(xFile.path);
      final uiImage = await ImageCacheService.instance.loadImage(persistentPath);
      if (uiImage == null) {
        if (context.mounted) {
          _showErrorBanner(context, 'Could not decode image format.');
        }
        return;
      }

      final doc = ref.read(canvasDocumentProvider);

      // Compute initial placement size: fit into 70% of canvas dimensions
      final imgAspect = uiImage.width / max(1, uiImage.height);
      double targetW = doc.width * 0.70;
      double targetH = targetW / imgAspect;

      if (targetH > doc.height * 0.70) {
        targetH = doc.height * 0.70;
        targetW = targetH * imgAspect;
      }

      final initialPos = Offset(
        (doc.width - targetW) / 2,
        (doc.height - targetH) / 2,
      );

      ref.read(placedImageProvider.notifier).state = PlacedImageData(
        file: File(persistentPath),
        path: persistentPath,
        image: uiImage,
        position: initialPos,
        size: Size(targetW, targetH),
        opacity: isTracing ? 0.35 : 1.0,
        blendMode: DrawBlendMode.normal,
        isTracingMode: isTracing,
      );

      ref.read(activeToolProvider.notifier).selectTool(DrawingTool.image);
      HapticFeedback.mediumImpact();
      SoundEffectService.instance.playCelebration();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ImageSourceModal: pickAndPlaceImage failed: $e');
      }
      if (context.mounted) {
        _showErrorBanner(context, 'Failed to import image: $e');
      }
    }
  }

  /// Extract dominant harmonious colors from photo and add them to recent colors.
  static Future<void> _extractPaletteFromPhoto(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      if (xFile == null) return;

      final bytes = await File(xFile.path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      // Extract colors by quantizing or sampling grid
      final sampleColors = <Color>[];
      final stepX = max(1, decoded.width ~/ 8);
      final stepY = max(1, decoded.height ~/ 8);

      for (int y = 0; y < decoded.height; y += stepY) {
        for (int x = 0; x < decoded.width; x += stepX) {
          final pixel = decoded.getPixel(x, y);
          final c = Color.fromARGB(
            255,
            pixel.r.toInt(),
            pixel.g.toInt(),
            pixel.b.toInt(),
          );
          // Avoid duplicate or near-duplicate shades
          final isDuplicate = sampleColors.any((sc) {
            final dr = (sc.r * 255 - c.r * 255).abs();
            final dg = (sc.g * 255 - c.g * 255).abs();
            final db = (sc.b * 255 - c.b * 255).abs();
            return dr + dg + db < 70;
          });
          if (!isDuplicate) {
            sampleColors.add(c);
          }
          if (sampleColors.length >= 8) break;
        }
        if (sampleColors.length >= 8) break;
      }

      if (sampleColors.isNotEmpty) {
        for (final col in sampleColors) {
          ref.read(activeColorProvider.notifier).addHistoryColor(col);
        }
        ref.read(activeColorProvider.notifier).setColor(sampleColors.first);
        HapticFeedback.mediumImpact();
        SoundEffectService.instance.playCelebration();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(CupertinoIcons.eyedropper_halffull, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Extracted ${sampleColors.length} colors into your palette!'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: IOSColors.brandPrimary,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ImageSourceModal: extract palette failed: $e');
      }
    }
  }

  /// Open photo inside the floating reference companion.
  static Future<void> _openInReferenceCompanion(
    BuildContext context,
    WidgetRef ref,
    VoidCallback? onOpenReferenceCompanion,
  ) async {
    try {
      final xFile = await _picker.pickImage(source: ImageSource.gallery);
      if (xFile == null) return;

      final persistentPath = await ImageCacheService.instance.persistPickedImage(xFile.path);
      ref.read(referenceImageProvider.notifier).state = File(persistentPath);
      onOpenReferenceCompanion?.call();

      HapticFeedback.lightImpact();
      SoundEffectService.instance.playPop();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ImageSourceModal: openInReferenceCompanion failed: $e');
      }
    }
  }

  static void _showErrorBanner(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: IOSColors.systemRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
