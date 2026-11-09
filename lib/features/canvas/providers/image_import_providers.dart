import 'dart:io';
import 'dart:ui' as ui;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/canvas_document.dart';
import '../models/stroke.dart';
import '../models/tools.dart';
import '../../brushes/default_brushes.dart';
import 'canvas_providers.dart';

/// State of an image currently being positioned and transformed on the canvas.
class PlacedImageData extends Equatable {
  const PlacedImageData({
    required this.file,
    required this.path,
    required this.image,
    required this.position,
    required this.size,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.blendMode = DrawBlendMode.normal,
    this.isTracingMode = false,
  });

  final File file;
  final String path;
  final ui.Image image;
  final Offset position;
  final Size size;
  final double rotation;
  final double opacity;
  final DrawBlendMode blendMode;
  final bool isTracingMode;

  double get aspectRatio => image.width / image.height;

  PlacedImageData copyWith({
    File? file,
    String? path,
    ui.Image? image,
    Offset? position,
    Size? size,
    double? rotation,
    double? opacity,
    DrawBlendMode? blendMode,
    bool? isTracingMode,
  }) {
    return PlacedImageData(
      file: file ?? this.file,
      path: path ?? this.path,
      image: image ?? this.image,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      isTracingMode: isTracingMode ?? this.isTracingMode,
    );
  }

  @override
  List<Object?> get props => [
    path,
    position,
    size,
    rotation,
    opacity,
    blendMode,
    isTracingMode,
  ];
}

/// Active placed image waiting to be stamped or committed into layers.
final placedImageProvider = StateProvider<PlacedImageData?>((ref) => null);

/// Helper methods for committing placed images into the canvas document.
class ImagePlacementController {
  ImagePlacementController._();

  /// Commit the active placed image into the canvas.
  ///
  /// - If [asNewLayer] is true or [placed.isTracingMode] is true:
  ///   creates a new layer with the image.
  /// - If [placed.isTracingMode] is true:
  ///   locks the image layer at 35% opacity and adds an active sketch layer on top.
  /// - Otherwise stamps onto the active layer.
  static void commit(WidgetRef ref, {bool asNewLayer = false}) {
    final placed = ref.read(placedImageProvider);
    if (placed == null) return;

    final docNotifier = ref.read(canvasDocumentProvider.notifier);
    final undoNotifier = ref.read(undoRedoProvider.notifier);
    final doc = ref.read(canvasDocumentProvider);

    final p1 = StrokePoint(
      x: placed.position.dx,
      y: placed.position.dy,
      pressure: 1.0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    final p2 = StrokePoint(
      x: placed.position.dx + placed.size.width,
      y: placed.position.dy + placed.size.height,
      pressure: 1.0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final brush = DefaultBrushes.hardBrush.copyWith(
      opacity: placed.opacity,
      size: 1.0,
    );

    final stroke = Stroke(
      points: [p1, p2],
      color: Colors.white,
      brush: brush,
      blendMode: placed.blendMode,
      shapeType: ShapeType.image,
      imagePath: placed.path,
      imageRotation: placed.rotation,
    );

    if (placed.isTracingMode) {
      // 1. Create photo reference layer (locked, 35% opacity)
      final refLayer = LayerModel(
        name: 'Photo Reference (Tracing)',
        type: LayerType.image,
        opacity: 0.35,
        isLocked: true,
        strokes: [stroke],
      );
      docNotifier.insertLayer(refLayer);

      // 2. Create active sketch layer on top
      final sketchLayer = LayerModel(
        name: 'Sketch Layer',
        type: LayerType.sketch,
        opacity: 1.0,
      );
      docNotifier.insertLayer(sketchLayer);
    } else if (asNewLayer) {
      // Create dedicated image layer
      final layerIndex = doc.layers.length + 1;
      final imageLayer = LayerModel(
        name: 'Photo $layerIndex',
        type: LayerType.image,
        opacity: placed.opacity,
        blendMode: placed.blendMode,
        strokes: [stroke],
      );
      docNotifier.insertLayer(imageLayer);
    } else {
      // Stamp directly on the active layer
      docNotifier.addStroke(stroke);
      undoNotifier.pushAction(
        StrokeAction(documentNotifier: docNotifier, stroke: stroke),
      );
    }

    // Dismiss placement mode and revert to brush tool
    ref.read(placedImageProvider.notifier).state = null;
    ref.read(activeToolProvider.notifier).selectTool(DrawingTool.brush);
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
  }

  /// Discard the active placement.
  static void cancel(WidgetRef ref) {
    ref.read(placedImageProvider.notifier).state = null;
    ref.read(activeToolProvider.notifier).selectTool(DrawingTool.brush);
  }
}
