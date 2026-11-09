import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../canvas/models/canvas_document.dart';
import '../../canvas/services/image_cache_service.dart';
import '../../canvas/widgets/canvas_painter.dart';
import '../models/project_entry.dart';

/// Local file system storage service for projects.
///
/// Saves canvas documents, metadata manifests, and generates thumbnails.
class ProjectStorageService {
  ProjectStorageService._();
  static final ProjectStorageService instance = ProjectStorageService._();

  static const String _projectsDirName = 'draw_color_art_projects';
  static const String _manifestFileName = 'projects_manifest.json';

  Future<Directory> _getProjectsDirectory() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docsDir.path}/$_projectsDirName');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      final tempDir = Directory.systemTemp;
      final dir = Directory('${tempDir.path}/$_projectsDirName');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }

  Future<Directory> _getCacheDirectory() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory('${tempDir.path}/draw_color_art_cache');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      final tempDir = Directory.systemTemp;
      final dir = Directory('${tempDir.path}/draw_color_art_cache');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
  }

  Future<File> _getManifestFile() async {
    final dir = await _getProjectsDirectory();
    return File('${dir.path}/$_manifestFileName');
  }

  /// Load all project metadata entries from manifest.
  Future<List<ProjectEntry>> listProjects({bool includeTrash = false}) async {
    try {
      final file = await _getManifestFile();
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
      final entries = jsonList
          .map((e) => ProjectEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!includeTrash) {
        return entries.where((p) => !p.isTrash).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
      return entries..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return [];
    }
  }

  /// Save or update a project document and its manifest entry.
  Future<ProjectEntry> saveProject(CanvasDocument doc) async {
    final dir = await _getProjectsDirectory();
    final projectDir = Directory('${dir.path}/${doc.id}');
    if (!await projectDir.exists()) {
      await projectDir.create(recursive: true);
    }

    // Save document JSON
    final docFile = File('${projectDir.path}/document.json');
    await docFile.writeAsString(jsonEncode(doc.toJson()));

    // Generate thumbnail
    String? thumbPath;
    try {
      thumbPath = await _generateThumbnail(doc, projectDir.path);
    } catch (_) {
      // Thumbnail generation skipped
    }

    // Total strokes count across all layers
    final totalStrokes = doc.layers.fold<int>(
      0,
      (sum, layer) => sum + layer.strokes.length,
    );

    // Update manifest
    final entries = await listProjects(includeTrash: true);
    final existingIndex = entries.indexWhere((p) => p.id == doc.id);

    final updatedEntry = ProjectEntry(
      id: doc.id,
      name: doc.name,
      width: doc.width,
      height: doc.height,
      layerCount: doc.layers.length,
      strokeCount: totalStrokes,
      thumbnailPath: thumbPath ?? (existingIndex != -1 ? entries[existingIndex].thumbnailPath : null),
      isFavorite: existingIndex != -1 ? entries[existingIndex].isFavorite : false,
      isTrash: false,
      createdAt: doc.createdAt,
      updatedAt: DateTime.now(),
    );

    if (existingIndex != -1) {
      entries[existingIndex] = updatedEntry;
    } else {
      entries.add(updatedEntry);
    }

    final manifestFile = await _getManifestFile();
    await manifestFile.writeAsString(
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );

    return updatedEntry;
  }

  /// Load a full CanvasDocument by ID.
  Future<CanvasDocument?> loadProject(String id) async {
    try {
      final dir = await _getProjectsDirectory();
      final docFile = File('${dir.path}/$id/document.json');
      if (!await docFile.exists()) {
        return null;
      }
      final content = await docFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return CanvasDocument.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Move project to trash (or delete permanently if permanent = true).
  Future<void> deleteProject(String id, {bool permanent = false}) async {
    final entries = await listProjects(includeTrash: true);
    final index = entries.indexWhere((p) => p.id == id);
    if (index == -1) return;

    if (permanent) {
      entries.removeAt(index);
      final dir = await _getProjectsDirectory();
      final projectDir = Directory('${dir.path}/$id');
      if (await projectDir.exists()) {
        await projectDir.delete(recursive: true);
      }
    } else {
      entries[index] = entries[index].copyWith(isTrash: true);
    }

    final manifestFile = await _getManifestFile();
    await manifestFile.writeAsString(
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  /// Restore a trashed project.
  Future<void> restoreProject(String id) async {
    final entries = await listProjects(includeTrash: true);
    final index = entries.indexWhere((p) => p.id == id);
    if (index == -1) return;

    entries[index] = entries[index].copyWith(isTrash: false);

    final manifestFile = await _getManifestFile();
    await manifestFile.writeAsString(
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  /// Toggle favorite status of a project.
  Future<void> toggleFavorite(String id) async {
    final entries = await listProjects(includeTrash: true);
    final index = entries.indexWhere((p) => p.id == id);
    if (index == -1) return;

    entries[index] = entries[index].copyWith(
      isFavorite: !entries[index].isFavorite,
    );

    final manifestFile = await _getManifestFile();
    await manifestFile.writeAsString(
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  /// Generate a thumbnail PNG on disk and return its path.
  Future<String?> _generateThumbnail(
    CanvasDocument doc,
    String projectDirPath,
  ) async {
    final validDocWidth = doc.width > 0 ? doc.width : 1080;
    final validDocHeight = doc.height > 0 ? doc.height : 1080;

    const thumbWidth = 256;
    final thumbHeight = ((validDocHeight / validDocWidth) * thumbWidth).round().clamp(64, 1024);

    // Preload placed images so they are not omitted from the thumbnail
    await ImageCacheService.instance.preloadDocument(doc);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Scale canvas to fit thumbnail
    final scale = thumbWidth / validDocWidth;
    canvas.scale(scale, scale);

    final painter = CanvasPainter(document: doc, isThumbnail: true);
    painter.paint(
      canvas,
      Size(validDocWidth.toDouble(), validDocHeight.toDouble()),
    );

    final picture = recorder.endRecording();
    ui.Image? image;
    try {
      image = await picture.toImage(thumbWidth, thumbHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final thumbFile = File('$projectDirPath/thumbnail.png');
      await thumbFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      // Evict stale cached image from Flutter's imageCache so UI reflects update immediately
      try {
        PaintingBinding.instance.imageCache.evict(FileImage(thumbFile));
      } catch (_) {
        // Safe fallback in test environments
      }

      return thumbFile.path;
    } finally {
      picture.dispose();
      image?.dispose();
    }
  }

  /// Calculates total bytes used by projects directory.
  Future<int> getProjectsStorageBytes() async {
    try {
      final dir = await _getProjectsDirectory();
      if (!await dir.exists()) return 0;
      int totalSize = 0;
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (_) {
      return 0;
    }
  }

  /// Calculates total bytes used by temporary cache directory.
  Future<int> getCacheBytes() async {
    try {
      final tempDir = await _getCacheDirectory();
      if (!await tempDir.exists()) return 0;
      int totalSize = 0;
      await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (_) {
      return 0;
    }
  }

  /// Clears temporary cache files and returns number of bytes freed.
  Future<int> clearCache() async {
    try {
      final tempDir = await _getCacheDirectory();
      if (!await tempDir.exists()) return 0;
      int freedBytes = 0;
      await for (final entity in tempDir.list(recursive: false, followLinks: false)) {
        try {
          if (entity is File) {
            freedBytes += await entity.length();
            await entity.delete();
          } else if (entity is Directory) {
            await for (final child in entity.list(recursive: true, followLinks: false)) {
              if (child is File) {
                freedBytes += await child.length();
              }
            }
            await entity.delete(recursive: true);
          }
        } catch (_) {
          // Skip unreadable entity
        }
      }
      return freedBytes;
    } catch (_) {
      return 0;
    }
  }

  /// Formats byte count into human-readable string (KB, MB, GB).
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
