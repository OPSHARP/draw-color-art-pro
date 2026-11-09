import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/stroke.dart';
import '../models/canvas_document.dart';

/// Performance-critical image caching and persistence service for canvas rendering.
///
/// Because `CustomPainter.paint` is synchronous, images placed on canvas must be
/// pre-decoded into `ui.Image` objects and accessible synchronously via `getImageSync(path)`.
class ImageCacheService {
  ImageCacheService._();
  static final ImageCacheService instance = ImageCacheService._();

  final Map<String, ui.Image> _cache = {};

  /// Synchronously retrieve a cached `ui.Image`.
  ui.Image? getImageSync(String path) => _cache[path];

  /// Check if an image is already in memory.
  bool contains(String path) => _cache.containsKey(path);

  /// Directly store a decoded image in the cache (e.g. for testing or memory-backed images).
  void putImage(String path, ui.Image image) {
    _cache[path] = image;
  }

  /// Asynchronously load and decode an image from a file path or asset, caching the result.
  Future<ui.Image?> loadImage(String path) async {
    if (_cache.containsKey(path)) {
      return _cache[path];
    }

    try {
      Uint8List bytes;
      final file = File(path);
      if (await file.exists()) {
        bytes = await file.readAsBytes();
      } else {
        // Fallback: try loading as Flutter asset
        final byteData = await rootBundle.load(path);
        bytes = byteData.buffer.asUint8List();
      }

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _cache[path] = frame.image;
      return frame.image;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ImageCacheService: Failed to load image at $path: $e');
      }
      return null;
    }
  }

  /// Persist a picked temporary image file to the app's documents directory
  /// so it persists across app restarts and cache purges.
  ///
  /// Automatically preloads and caches the decoded image before returning the permanent path.
  Future<String> persistPickedImage(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/DrawColorArt/imported_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final sourceFile = File(sourcePath);
      final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
      final fileName = 'img_${const Uuid().v4()}.$ext';
      final persistentFile = File('${imagesDir.path}/$fileName');

      if (await sourceFile.exists()) {
        await sourceFile.copy(persistentFile.path);
      } else {
        // If file doesn't exist at source, return original path
        return sourcePath;
      }

      final persistentPath = persistentFile.path;
      await loadImage(persistentPath);
      return persistentPath;
    } catch (e) {
      debugPrint('ImageCacheService: Failed to persist picked image: $e');
      // If error during copy, attempt to preload original path directly
      await loadImage(sourcePath);
      return sourcePath;
    }
  }

  /// Preload all image strokes in a list of strokes so they render immediately without lag.
  Future<void> preloadStrokes(List<Stroke> strokes) async {
    final futures = <Future<ui.Image?>>[];
    for (final stroke in strokes) {
      if (stroke.shapeType == ShapeType.image && stroke.imagePath != null) {
        if (!_cache.containsKey(stroke.imagePath!)) {
          futures.add(loadImage(stroke.imagePath!));
        }
      }
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  /// Preload all image strokes across all layers in a document.
  Future<void> preloadDocument(CanvasDocument doc) async {
    final allStrokes = <Stroke>[];
    for (final layer in doc.layers) {
      allStrokes.addAll(layer.strokes);
    }
    await preloadStrokes(allStrokes);
  }

  /// Clear in-memory cache.
  void clear() {
    _cache.clear();
  }
}
