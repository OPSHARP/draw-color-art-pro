import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../features/canvas/models/canvas_document.dart';
import '../../features/canvas/models/stroke.dart';
import '../../features/canvas/widgets/canvas_painter.dart';

/// Service that computes 4-way scanline flood fills for coloring and canvas artwork.
class FloodFillService {
  FloodFillService._();
  static final FloodFillService instance = FloodFillService._();

  /// Computes a flood fill from `seedPoint` on the document and returns a fill Stroke.
  Future<Stroke?> computeFill({
    required CanvasDocument document,
    required Offset seedPoint,
    required Color fillColor,
    int tolerance = 35,
  }) async {
    // Determine offscreen raster scale for high performance
    const maxDim = 600.0;
    final scale = min(maxDim / document.width, maxDim / document.height).clamp(0.1, 1.0);
    final w = (document.width * scale).round();
    final h = (document.height * scale).round();

    if (w <= 0 || h <= 0) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);

    final painter = CanvasPainter(document: document);
    painter.paint(canvas, Size(document.width.toDouble(), document.height.toDouble()));

    final picture = recorder.endRecording();
    ui.Image? image;
    ByteData? byteData;
    try {
      image = await picture.toImage(w, h);
      byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    } finally {
      picture.dispose();
      image?.dispose();
    }

    if (byteData == null) return null;

    final seedX = (seedPoint.dx * scale).round().clamp(0, w - 1);
    final seedY = (seedPoint.dy * scale).round().clamp(0, h - 1);

    final seedIdx = (seedY * w + seedX) * 4;
    final targetR = byteData.getUint8(seedIdx);
    final targetG = byteData.getUint8(seedIdx + 1);
    final targetB = byteData.getUint8(seedIdx + 2);
    final targetA = byteData.getUint8(seedIdx + 3);

    // If target color is already almost identical to fill color, skip
    final fillR = (fillColor.r * 255).round();
    final fillG = (fillColor.g * 255).round();
    final fillB = (fillColor.b * 255).round();
    final fillA = (fillColor.a * 255).round();

    if (_colorDistSq(targetR, targetG, targetB, targetA, fillR, fillG, fillB, fillA) < 100) {
      return null;
    }

    final tolSq = tolerance * tolerance * 3;
    final visited = Uint8List(w * h);

    // Breadth-first search queue
    final queue = Int32List(w * h * 2);
    int qHead = 0;
    int qTail = 0;

    queue[qTail++] = seedX;
    queue[qTail++] = seedY;
    visited[seedY * w + seedX] = 1;

    while (qHead < qTail) {
      final cx = queue[qHead++];
      final cy = queue[qHead++];

      // Check 4 neighbors
      final neighbors = [
        (cx - 1, cy),
        (cx + 1, cy),
        (cx, cy - 1),
        (cx, cy + 1),
      ];

      for (final (nx, ny) in neighbors) {
        if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
        final nIdx = ny * w + nx;
        if (visited[nIdx] == 1) continue;

        final byteIdx = nIdx * 4;
        final nr = byteData.getUint8(byteIdx);
        final ng = byteData.getUint8(byteIdx + 1);
        final nb = byteData.getUint8(byteIdx + 2);
        final na = byteData.getUint8(byteIdx + 3);

        if (_colorDistSq(targetR, targetG, targetB, targetA, nr, ng, nb, na) <= tolSq) {
          visited[nIdx] = 1;
          queue[qTail++] = nx;
          queue[qTail++] = ny;
        }
      }
    }

    // Convert visited mask into horizontal scanline spans
    final spanPoints = <StrokePoint>[];
    final stepSize = 1.0 / scale;

    for (int y = 0; y < h; y++) {
      int? spanStart;
      for (int x = 0; x < w; x++) {
        final isFilled = visited[y * w + x] == 1;
        if (isFilled && spanStart == null) {
          spanStart = x;
        } else if (!isFilled && spanStart != null) {
          // Span ended
          spanPoints.add(StrokePoint(x: spanStart / scale, y: y / scale));
          spanPoints.add(StrokePoint(x: (x - 1) / scale, y: y / scale));
          spanStart = null;
        }
      }
      if (spanStart != null) {
        spanPoints.add(StrokePoint(x: spanStart / scale, y: y / scale));
        spanPoints.add(StrokePoint(x: (w - 1) / scale, y: y / scale));
      }
    }

    if (spanPoints.isEmpty) return null;

    final fillBrush = BrushPreset(
      name: 'Flood Fill',
      category: BrushCategory.basic,
      size: stepSize,
      opacity: 1.0,
      hardness: 1.0,
    );

    return Stroke(
      points: spanPoints,
      color: fillColor,
      brush: fillBrush,
      shapeType: ShapeType.floodFill,
      isFilled: true,
    );
  }

  int _colorDistSq(int r1, int g1, int b1, int a1, int r2, int g2, int b2, int a2) {
    final dr = r1 - r2;
    final dg = g1 - g2;
    final db = b1 - b2;
    final da = a1 - a2;
    return dr * dr + dg * dg + db * db + da * da;
  }
}
