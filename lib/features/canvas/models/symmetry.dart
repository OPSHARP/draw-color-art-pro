import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'stroke.dart';

/// Symmetry modes for kaleidoscope, mandala, and mirror drawing.
enum SymmetryMode {
  off('Off'),
  vertical('Vertical Mirror'),
  horizontal('Horizontal Mirror'),
  dual('4-Way Cross'),
  radial('Radial Mandala');

  const SymmetryMode(this.label);
  final String label;
}

class SymmetryConfig extends Equatable {
  const SymmetryConfig({
    this.mode = SymmetryMode.off,
    this.segments = 8,
    this.showGuides = true,
  });

  final SymmetryMode mode;
  final int segments; // Used for radial mandala (e.g. 4, 8, 12)
  final bool showGuides;

  bool get isEnabled => mode != SymmetryMode.off;

  SymmetryConfig copyWith({
    SymmetryMode? mode,
    int? segments,
    bool? showGuides,
  }) {
    return SymmetryConfig(
      mode: mode ?? this.mode,
      segments: segments ?? this.segments,
      showGuides: showGuides ?? this.showGuides,
    );
  }

  /// Calculates all symmetric reflections/rotations of a point around (centerX, centerY).
  List<StrokePoint> getSymmetricPoints(
    StrokePoint point,
    double centerX,
    double centerY,
  ) {
    if (!isEnabled) return [point];

    final results = <StrokePoint>[point];
    final dx = point.x - centerX;
    final dy = point.y - centerY;

    switch (mode) {
      case SymmetryMode.off:
        return [point];

      case SymmetryMode.vertical:
        // Reflect across vertical center axis
        results.add(point.copyWith(x: centerX - dx, y: point.y));
        break;

      case SymmetryMode.horizontal:
        // Reflect across horizontal center axis
        results.add(point.copyWith(x: point.x, y: centerY - dy));
        break;

      case SymmetryMode.dual:
        // 4-way cross reflection
        results.add(point.copyWith(x: centerX - dx, y: point.y));
        results.add(point.copyWith(x: point.x, y: centerY - dy));
        results.add(point.copyWith(x: centerX - dx, y: centerY - dy));
        break;

      case SymmetryMode.radial:
        // Radial rotational & mirror symmetry (Mandala)
        final angleStep = (2 * pi) / segments;
        final radius = sqrt(dx * dx + dy * dy);
        final baseAngle = atan2(dy, dx);

        for (int i = 1; i < segments; i++) {
          final theta = baseAngle + i * angleStep;
          results.add(
            point.copyWith(
              x: centerX + radius * cos(theta),
              y: centerY + radius * sin(theta),
            ),
          );
        }
        break;
    }

    return results;
  }

  /// Expands a single stroke into all its symmetric stroke copies.
  List<Stroke> generateSymmetricStrokes(
    Stroke stroke,
    double canvasWidth,
    double canvasHeight,
  ) {
    if (!isEnabled || stroke.points.isEmpty) return [stroke];

    final centerX = canvasWidth / 2;
    final centerY = canvasHeight / 2;

    // First, compute how many copies will be generated per point
    final firstPointSym = getSymmetricPoints(stroke.points.first, centerX, centerY);
    final count = firstPointSym.length;
    if (count <= 1) return [stroke];

    final strokePointLists = List.generate(count, (_) => <StrokePoint>[]);

    for (final pt in stroke.points) {
      final syms = getSymmetricPoints(pt, centerX, centerY);
      for (int i = 0; i < count; i++) {
        strokePointLists[i].add(syms[i]);
      }
    }

    return strokePointLists.asMap().entries.map((entry) {
      final index = entry.key;
      final pts = entry.value;
      return stroke.copyWith(
        id: index == 0 ? stroke.id : const Uuid().v4(),
        points: pts,
      );
    }).toList();
  }

  @override
  List<Object?> get props => [mode, segments, showGuides];
}
