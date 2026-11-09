import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../canvas/models/canvas_document.dart';
import '../../canvas/services/image_cache_service.dart';
import '../../canvas/widgets/canvas_painter.dart';

enum ExportFormat {
  png('PNG', '.png', 'Lossless with transparency support'),
  jpeg('JPEG', '.jpg', 'Best for sharing photographs and paintings'),
  webp('WebP', '.webp', 'Modern compact format with high quality');

  const ExportFormat(this.label, this.extension, this.description);
  final String label;
  final String extension;
  final String description;
}

class ExportConfig {
  const ExportConfig({
    this.format = ExportFormat.png,
    this.scale = 1.0,
    this.quality = 90,
    this.includeBackground = true,
  });

  final ExportFormat format;
  final double scale;
  final int quality;
  final bool includeBackground;
}

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  /// Render document to bytes according to config.
  Future<Uint8List> renderToBytes(
    CanvasDocument document,
    ExportConfig config,
  ) async {
    final exportWidth = (document.width * config.scale).round();
    final exportHeight = (document.height * config.scale).round();

    // Ensure all placed image strokes are pre-decoded into memory before painting
    await ImageCacheService.instance.preloadDocument(document);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Apply scaling
    canvas.scale(config.scale, config.scale);

    // Override background transparency if requested
    final effectiveDoc = document.copyWith(
      isTransparentBackground: !config.includeBackground,
    );

    final painter = CanvasPainter(document: effectiveDoc, isThumbnail: true);
    painter.paint(
      canvas,
      Size(document.width.toDouble(), document.height.toDouble()),
    );

    final picture = recorder.endRecording();
    ui.Image? uiImage;
    try {
      uiImage = await picture.toImage(exportWidth, exportHeight);

      switch (config.format) {
        case ExportFormat.png:
        case ExportFormat.webp:
          // Direct PNG encoding from flutter engine is ultra fast and lossless
          final pngData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
          if (pngData == null) {
            throw StateError('Failed to encode image bytes.');
          }
          return pngData.buffer.asUint8List();

        case ExportFormat.jpeg:
          final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
          if (byteData == null) {
            throw StateError('Failed to extract raw image bytes.');
          }
          final rawBytes = byteData.buffer.asUint8List();
          final image = img.Image.fromBytes(
            width: exportWidth,
            height: exportHeight,
            bytes: rawBytes.buffer,
            order: img.ChannelOrder.rgba,
          );
          return Uint8List.fromList(img.encodeJpg(image, quality: config.quality));
      }
    } finally {
      picture.dispose();
      uiImage?.dispose();
    }
  }

  /// Export document to a file and open the native share sheet.
  Future<String> exportAndShare(
    CanvasDocument document,
    ExportConfig config,
  ) async {
    final bytes = await renderToBytes(document, config);
    final tempDir = await getTemporaryDirectory();
    final sanitizedName = document.name.replaceAll(RegExp(r'[^\w\s\-]'), '_');
    final fileName = '$sanitizedName${config.format.extension}';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/${config.format.name}')],
      subject: document.name,
      text: 'Exported from Draw Color Art Pro',
    );

    return file.path;
  }

  /// Save artwork directly to phone storage (Pictures / Downloads folder).
  Future<String> saveToPhoneStorage(
    CanvasDocument document,
    ExportConfig config, {
    Directory? targetDirectory,
  }) async {
    final bytes = await renderToBytes(document, config);

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final sanitizedName =
        document.name.replaceAll(RegExp(r'[^\w\s\-]'), '_').trim();
    final baseName = sanitizedName.isEmpty ? 'Artwork' : sanitizedName;
    final fileName = '${baseName}_$timestamp${config.format.extension}';

    // Build prioritized list of candidate target directories
    final candidateDirs = <Directory>[];

    if (targetDirectory != null) {
      candidateDirs.add(targetDirectory);
    } else if (Platform.isAndroid) {
      // 1. Standard public Pictures directory (visible in Google Photos & Gallery app)
      candidateDirs.add(Directory('/storage/emulated/0/Pictures/DrawColorArtPro'));
      candidateDirs.add(Directory('/storage/emulated/0/Pictures/Draw Color Art Pro'));
      // 2. DCIM public directory
      candidateDirs.add(Directory('/storage/emulated/0/DCIM/DrawColorArtPro'));
      candidateDirs.add(Directory('/storage/emulated/0/DCIM/Draw Color Art Pro'));
      // 3. App-specific external pictures directory
      try {
        final picturesDirs = await getExternalStorageDirectories(
          type: StorageDirectory.pictures,
        );
        if (picturesDirs != null && picturesDirs.isNotEmpty) {
          candidateDirs.add(Directory('${picturesDirs.first.path}/DrawColorArtPro'));
        }
      } catch (_) {}
      // 4. Downloads folder fallback
      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) {
          candidateDirs.add(Directory('${downloads.path}/DrawColorArtPro'));
        }
      } catch (_) {}
    } else if (Platform.isIOS) {
      // On iOS, ApplicationDocumentsDirectory makes it visible in the Files app
      try {
        candidateDirs.add(await getApplicationDocumentsDirectory());
      } catch (_) {}
    } else {
      // Windows / macOS / Linux
      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) {
          candidateDirs.add(Directory('${downloads.path}/DrawColorArtPro'));
        }
      } catch (_) {}
    }

    // Always ensure internal app documents directory is included as safe final fallback
    try {
      final appDoc = await getApplicationDocumentsDirectory();
      if (!candidateDirs.any((d) => d.path == appDoc.path)) {
        candidateDirs.add(Directory('${appDoc.path}/DrawColorArtPro'));
      }
    } catch (_) {}

    Object? lastError;
    for (final dir in candidateDirs) {
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      } catch (e) {
        lastError = e;
        // Continue to the next fallback location seamlessly
        continue;
      }
    }

    throw StateError('Unable to write artwork to any storage location: $lastError');
  }

  static const MethodChannel _galleryChannel = MethodChannel('com.drawcolor.artpro/gallery');

  /// Save artwork directly into the device's Gallery / Photos album.
  ///
  /// On Android, writes to public Pictures/DrawColorArtPro and triggers
  /// MediaScannerConnection so the image immediately shows up in Google Photos and Gallery apps.
  Future<String> saveToGallery(
    CanvasDocument document, {
    ExportConfig config = const ExportConfig(
      format: ExportFormat.png,
      scale: 2.0,
      includeBackground: true,
    ),
  }) async {
    final filePath = await saveToPhoneStorage(document, config);

    if (Platform.isAndroid) {
      try {
        await _galleryChannel.invokeMethod('scanFile', {'path': filePath});
      } catch (_) {
        // Fallback silently if method channel is unavailable in tests
      }
    }

    return filePath;
  }
}
