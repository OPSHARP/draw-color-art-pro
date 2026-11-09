import 'dart:math';
import 'package:flutter/material.dart';
import '../../canvas/models/stroke.dart';
import '../models/coloring_template.dart';

/// High-performance vector thumbnail widget that renders the actual vector lines
/// of any [ColoringTemplate] scaled into any thumbnail dimensions with hardware-accelerated path caching.
class TemplateThumbnailWidget extends StatelessWidget {
  const TemplateThumbnailWidget({
    super.key,
    required this.template,
    this.width,
    this.height,
    this.backgroundColor,
    this.showBorderAndShadow = true,
    this.showColoredPreview = false,
    this.inkColor,
  });

  final ColoringTemplate template;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final bool showBorderAndShadow;
  final bool showColoredPreview;
  final Color? inkColor;

  static final Map<String, List<Stroke>> _strokesCache = {};
  static final Map<String, Path> _pathCache = {};

  /// Retrieves or compiles the combined [Path] for a template from its strokes.
  static Path getCompiledPath(ColoringTemplate template) {
    return _pathCache.putIfAbsent(template.id, () {
      final strokes = _strokesCache.putIfAbsent(
        template.id,
        () => template.strokeGenerator(1000, 1000),
      );

      final path = Path();
      for (final stroke in strokes) {
        final pts = stroke.points;
        if (pts.isEmpty) continue;
        if (pts.length == 1) {
          path.addOval(Rect.fromCircle(
            center: pts[0].offset,
            radius: max(1.0, stroke.brush.size / 2),
          ));
          continue;
        }

        path.moveTo(pts[0].x, pts[0].y);
        for (int i = 1; i < pts.length; i++) {
          path.lineTo(pts[i].x, pts[i].y);
        }
      }
      return path;
    });
  }

  @override
  Widget build(BuildContext context) {
    final compiledPath = getCompiledPath(template);

    // Authentic coloring book page presentation: pristine white/paper background
    final baseBgColor = backgroundColor ?? Colors.white;

    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseBgColor,
          gradient: showColoredPreview
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    template.gradient.first.withValues(alpha: 0.14),
                    template.gradient.last.withValues(alpha: 0.08),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(showBorderAndShadow ? 10 : 0),
          border: showBorderAndShadow
              ? Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.0,
                )
              : null,
          boxShadow: showBorderAndShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : 80.0);
            final h = height ?? (constraints.hasBoundedHeight ? constraints.maxHeight : 80.0);
            return CustomPaint(
              size: Size(w, h),
              painter: _ThumbnailVectorPainter(
                path: compiledPath,
                inkColor: inkColor ?? (showColoredPreview ? template.gradient.first : const Color(0xFF1E293B)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThumbnailVectorPainter extends CustomPainter {
  const _ThumbnailVectorPainter({
    required this.path,
    required this.inkColor,
  });

  final Path path;
  final Color inkColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Subtle 3.5% inset padding so borders don't touch thumbnail edges
    final padX = size.width * 0.035;
    final padY = size.height * 0.035;
    final targetW = max(1.0, size.width - padX * 2);
    final targetH = max(1.0, size.height - padY * 2);

    final scaleX = targetW / 1000.0;
    final scaleY = targetH / 1000.0;
    final fitScale = scaleX < scaleY ? scaleX : scaleY;

    canvas.save();
    // Center the artwork within the padded thumbnail
    final offsetX = padX + (targetW - 1000.0 * fitScale) / 2;
    final offsetY = padY + (targetH - 1000.0 * fitScale) / 2;
    canvas.translate(offsetX, offsetY);
    canvas.scale(fitScale, fitScale);

    // Target crisp ~1.8 physical pixels stroke width on screen
    final strokeWidthInArtSpace = max(2.5, 1.8 / fitScale);

    final paint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidthInArtSpace
      ..isAntiAlias = true;

    // Single hardware-accelerated draw call for the entire template!
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ThumbnailVectorPainter oldDelegate) =>
      oldDelegate.path != path || oldDelegate.inkColor != inkColor;
}
