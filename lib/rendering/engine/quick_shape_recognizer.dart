import 'dart:math';
import 'dart:ui';
import '../../features/canvas/models/stroke.dart';

/// Recognized geometric shape result from user's freehand stroke.
class QuickShapeResult {
  const QuickShapeResult({
    required this.shapeType,
    required this.points,
    required this.bounds,
    required this.confidence,
    this.isClosed = false,
  });

  final ShapeType shapeType;
  final List<StrokePoint> points;
  final Rect bounds;
  final double confidence; // 0.0 to 1.0
  final bool isClosed;
}

/// Advanced geometric shape recognizer that detects user intent when holding
/// a stroke still at the end ("Draw and Hold" / QuickShape).
///
/// Recognizes:
/// - Straight Line (Horizontal, Vertical, Diagonal)
/// - Circle (Equidistant closed contour)
/// - Ellipse (Smooth oval contour)
/// - Rectangle / Square (4 corners, perpendicular edges)
/// - Triangle (3 vertices)
/// - Star (5-pointed star)
class QuickShapeRecognizer {
  QuickShapeRecognizer._();

  /// Attempt to recognize a shape from a list of stroke points.
  /// Returns `null` if no geometric shape matches with sufficient confidence.
  static QuickShapeResult? recognize(List<StrokePoint> rawPoints) {
    if (rawPoints.length < 5) return null;

    final points = _resamplePoints(rawPoints, 40);
    if (points.length < 5) return null;

    final first = points.first;
    final last = points.last;
    final directDist = (Offset(last.x, last.y) - Offset(first.x, first.y)).distance;

    double totalLength = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalLength += (Offset(points[i + 1].x, points[i + 1].y) -
              Offset(points[i].x, points[i].y))
          .distance;
    }

    if (totalLength < 15.0) return null;

    // 1. Check for Straight Line
    final lineResult = _checkLine(points, first, last, directDist, totalLength);
    if (lineResult != null) return lineResult;

    // Compute bounding box
    double minX = points.first.x, maxX = points.first.x;
    double minY = points.first.y, maxY = points.first.y;
    for (final p in points) {
      minX = min(minX, p.x);
      maxX = max(maxX, p.x);
      minY = min(minY, p.y);
      maxY = max(maxY, p.y);
    }
    final bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
    final center = bounds.center;

    final isClosed = directDist < 50.0 || (directDist / totalLength < 0.25);

    // 2. If closed or near-closed, check Circle, Ellipse, Triangle, Rectangle, Star
    if (isClosed) {
      // Check Circle
      final circleResult = _checkCircle(points, center, bounds);
      if (circleResult != null) return circleResult;

      // Check Rectangle
      final rectResult = _checkRectangle(points, bounds);
      if (rectResult != null) return rectResult;

      // Check Triangle
      final triResult = _checkTriangle(points, bounds);
      if (triResult != null) return triResult;

      // Check Star
      final starResult = _checkStar(points, bounds);
      if (starResult != null) return starResult;

      // Check Ellipse
      final ellipseResult = _checkEllipse(points, center, bounds);
      if (ellipseResult != null) return ellipseResult;
    }

    return null;
  }

  /// Line detector: checks if all points lie close to chord connecting endpoints.
  static QuickShapeResult? _checkLine(
    List<StrokePoint> points,
    StrokePoint start,
    StrokePoint end,
    double directDist,
    double totalLength,
  ) {
    if (directDist < 25.0) return null;

    // Chord ratio: total length along path should be close to direct distance
    final ratio = totalLength / directDist;
    if (ratio > 1.25) return null;

    // Max perpendicular distance
    double maxPerpDist = 0;
    final p1 = Offset(start.x, start.y);
    final p2 = Offset(end.x, end.y);
    final lineVec = p2 - p1;
    final lineLenSq = lineVec.dx * lineVec.dx + lineVec.dy * lineVec.dy;

    for (final p in points) {
      final pt = Offset(p.x, p.y);
      final t = lineLenSq == 0 ? 0.0 : ((pt - p1).dx * lineVec.dx + (pt - p1).dy * lineVec.dy) / lineLenSq;
      final projection = p1 + lineVec * t.clamp(0.0, 1.0);
      final perpDist = (pt - projection).distance;
      maxPerpDist = max(maxPerpDist, perpDist);
    }

    if (maxPerpDist / directDist < 0.08) {
      // Snap to perfectly straight line
      final ts = DateTime.now().millisecondsSinceEpoch;
      return QuickShapeResult(
        shapeType: ShapeType.line,
        points: [
          StrokePoint(x: start.x, y: start.y, pressure: start.pressure, timestamp: ts),
          StrokePoint(x: end.x, y: end.y, pressure: end.pressure, timestamp: ts),
        ],
        bounds: Rect.fromPoints(p1, p2),
        confidence: (1.0 - (maxPerpDist / directDist)).clamp(0.7, 0.99),
        isClosed: false,
      );
    }
    return null;
  }

  /// Circle detector: radial distance variance from center of mass is minimal.
  static QuickShapeResult? _checkCircle(
    List<StrokePoint> points,
    Offset center,
    Rect bounds,
  ) {
    if (bounds.width < 15 || bounds.height < 15) return null;
    final aspect = bounds.width / bounds.height;
    if (aspect < 0.75 || aspect > 1.35) return null;

    final radii = points.map((p) => (Offset(p.x, p.y) - center).distance).toList();
    final meanRadius = radii.reduce((a, b) => a + b) / radii.length;

    double variance = 0;
    for (final r in radii) {
      variance += (r - meanRadius) * (r - meanRadius);
    }
    final stdDev = sqrt(variance / radii.length);
    final relativeStdDev = stdDev / meanRadius;

    if (relativeStdDev < 0.16) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final avgP = points.map((p) => p.pressure).reduce((a, b) => a + b) / points.length;
      final circleBounds = Rect.fromCircle(center: center, radius: meanRadius);

      return QuickShapeResult(
        shapeType: ShapeType.circle,
        points: [
          StrokePoint(x: circleBounds.left, y: circleBounds.top, pressure: avgP, timestamp: ts),
          StrokePoint(x: circleBounds.right, y: circleBounds.bottom, pressure: avgP, timestamp: ts),
        ],
        bounds: circleBounds,
        confidence: (1.0 - relativeStdDev).clamp(0.8, 0.99),
        isClosed: true,
      );
    }
    return null;
  }

  /// Ellipse detector.
  static QuickShapeResult? _checkEllipse(
    List<StrokePoint> points,
    Offset center,
    Rect bounds,
  ) {
    if (bounds.width < 20 || bounds.height < 20) return null;

    final rx = bounds.width / 2.0;
    final ry = bounds.height / 2.0;
    if (rx == 0 || ry == 0) return null;

    double errorSum = 0;
    for (final p in points) {
      final dx = (p.x - center.dx) / rx;
      final dy = (p.y - center.dy) / ry;
      final distFrom1 = (sqrt(dx * dx + dy * dy) - 1.0).abs();
      errorSum += distFrom1;
    }
    final avgError = errorSum / points.length;

    if (avgError < 0.20) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final avgP = points.map((p) => p.pressure).reduce((a, b) => a + b) / points.length;
      return QuickShapeResult(
        shapeType: ShapeType.circle,
        points: [
          StrokePoint(x: bounds.left, y: bounds.top, pressure: avgP, timestamp: ts),
          StrokePoint(x: bounds.right, y: bounds.bottom, pressure: avgP, timestamp: ts),
        ],
        bounds: bounds,
        confidence: (1.0 - avgError).clamp(0.7, 0.95),
        isClosed: true,
      );
    }
    return null;
  }

  /// Rectangle detector: 4 distinct corner turns ~90°.
  static QuickShapeResult? _checkRectangle(
    List<StrokePoint> points,
    Rect bounds,
  ) {
    if (bounds.width < 20 || bounds.height < 20) return null;

    // Count sharp corners (angle change between consecutive segment vectors > 55°)
    final corners = _detectCorners(points, 55.0 * (pi / 180.0));
    if (corners.length >= 3 && corners.length <= 5) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final avgP = points.map((p) => p.pressure).reduce((a, b) => a + b) / points.length;
      return QuickShapeResult(
        shapeType: ShapeType.rectangle,
        points: [
          StrokePoint(x: bounds.left, y: bounds.top, pressure: avgP, timestamp: ts),
          StrokePoint(x: bounds.right, y: bounds.bottom, pressure: avgP, timestamp: ts),
        ],
        bounds: bounds,
        confidence: 0.88,
        isClosed: true,
      );
    }
    return null;
  }

  /// Triangle detector: 3 sharp corner turns.
  static QuickShapeResult? _checkTriangle(
    List<StrokePoint> points,
    Rect bounds,
  ) {
    if (bounds.width < 20 || bounds.height < 20) return null;

    final corners = _detectCorners(points, 50.0 * (pi / 180.0));
    if (corners.length == 3) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final avgP = points.map((p) => p.pressure).reduce((a, b) => a + b) / points.length;
      return QuickShapeResult(
        shapeType: ShapeType.triangle,
        points: [
          StrokePoint(x: bounds.left, y: bounds.top, pressure: avgP, timestamp: ts),
          StrokePoint(x: bounds.right, y: bounds.bottom, pressure: avgP, timestamp: ts),
        ],
        bounds: bounds,
        confidence: 0.90,
        isClosed: true,
      );
    }
    return null;
  }

  /// Star detector: 5 distinct outer points.
  static QuickShapeResult? _checkStar(
    List<StrokePoint> points,
    Rect bounds,
  ) {
    if (bounds.width < 30 || bounds.height < 30) return null;

    final corners = _detectCorners(points, 45.0 * (pi / 180.0));
    if (corners.length >= 5 && corners.length <= 10) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final avgP = points.map((p) => p.pressure).reduce((a, b) => a + b) / points.length;
      return QuickShapeResult(
        shapeType: ShapeType.star,
        points: [
          StrokePoint(x: bounds.left, y: bounds.top, pressure: avgP, timestamp: ts),
          StrokePoint(x: bounds.right, y: bounds.bottom, pressure: avgP, timestamp: ts),
        ],
        bounds: bounds,
        confidence: 0.85,
        isClosed: true,
      );
    }
    return null;
  }

  /// Detect indices of sharp directional corner changes along the path.
  static List<int> _detectCorners(List<StrokePoint> points, double minAngleRads) {
    final corners = <int>[];
    const lookahead = 3;
    if (points.length < lookahead * 2 + 1) return corners;

    for (int i = lookahead; i < points.length - lookahead; i++) {
      final pPrev = Offset(points[i - lookahead].x, points[i - lookahead].y);
      final pCurr = Offset(points[i].x, points[i].y);
      final pNext = Offset(points[i + lookahead].x, points[i + lookahead].y);

      final v1 = pCurr - pPrev;
      final v2 = pNext - pCurr;

      final len1 = v1.distance;
      final len2 = v2.distance;
      if (len1 == 0 || len2 == 0) continue;

      final dot = (v1.dx * v2.dx + v1.dy * v2.dy) / (len1 * len2);
      final angle = acos(dot.clamp(-1.0, 1.0));

      if (angle > minAngleRads) {
        // Enforce spacing between detected corners
        if (corners.isEmpty || (i - corners.last) > lookahead * 2) {
          corners.add(i);
        }
      }
    }
    return corners;
  }

  /// Resample raw stroke points into N evenly spaced points.
  static List<StrokePoint> _resamplePoints(List<StrokePoint> points, int targetCount) {
    if (points.length < 2) return points;

    double totalLength = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalLength += (Offset(points[i + 1].x, points[i + 1].y) -
              Offset(points[i].x, points[i].y))
          .distance;
    }
    if (totalLength == 0) return points;

    final interval = totalLength / (targetCount - 1);
    final resampled = <StrokePoint>[points.first];

    double currentDist = 0;
    int segIdx = 0;

    for (int i = 1; i < targetCount - 1; i++) {
      final targetDist = i * interval;

      while (segIdx < points.length - 1) {
        final p1 = points[segIdx];
        final p2 = points[segIdx + 1];
        final segLen = (Offset(p2.x, p2.y) - Offset(p1.x, p1.y)).distance;

        if (currentDist + segLen >= targetDist) {
          final t = (targetDist - currentDist) / (segLen > 0 ? segLen : 1.0);
          resampled.add(
            StrokePoint(
              x: p1.x + (p2.x - p1.x) * t,
              y: p1.y + (p2.y - p1.y) * t,
              pressure: p1.pressure + (p2.pressure - p1.pressure) * t,
              tilt: p1.tilt + (p2.tilt - p1.tilt) * t,
              timestamp: p1.timestamp,
            ),
          );
          break;
        } else {
          currentDist += segLen;
          segIdx++;
        }
      }
    }

    resampled.add(points.last);
    return resampled;
  }
}
