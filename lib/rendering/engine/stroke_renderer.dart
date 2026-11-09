import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import '../../features/canvas/models/stroke.dart';
import '../../features/canvas/services/image_cache_service.dart';
import '../../features/text/services/font_catalog_service.dart';

/// Core stroke renderer that converts stroke data into canvas draw calls.
///
/// This is the performance-critical rendering path. It renders strokes using
/// optimized path building and paint configuration based on brush parameters.
class StrokeRenderer {
  StrokeRenderer._();

  /// Render a single stroke onto the canvas.
  static void renderStroke(Canvas canvas, Stroke stroke, {double layerOpacity = 1.0}) {
    if (stroke.points.isEmpty) return;

    // Handle geometric shapes and flood fills
    if (stroke.shapeType != ShapeType.none) {
      _renderShapeOrFill(canvas, stroke, layerOpacity);
      return;
    }

    // Highlighter tool rendering: translucent flat chisel nib with multiply blend
    if (stroke.brush.isHighlighter) {
      _renderHighlighterStroke(canvas, stroke, layerOpacity);
      return;
    }

    // Rainbow magical brush: dynamic chromatic color cycling along the stroke
    if (stroke.brush.isRainbow) {
      _renderRainbowStroke(canvas, stroke, layerOpacity);
      return;
    }

    // Airbrush / spray tool rendering
    if (stroke.brush.isSpray) {
      _renderSprayStroke(canvas, stroke, layerOpacity);
      return;
    }

    // Calligraphy pen: angle-dependent variable-width nib
    if (stroke.brush.isCalligraphy) {
      _renderCalligraphyStroke(canvas, stroke, layerOpacity);
      return;
    }

    // Crayon / Pastel: textured scattered particles
    if (stroke.brush.isCrayon) {
      _renderCrayonStroke(canvas, stroke, layerOpacity);
      return;
    }

    // Dotted Pen: evenly-spaced dots along path
    if (stroke.brush.isDotted) {
      _renderDottedStroke(canvas, stroke, layerOpacity);
      return;
    }

    // Pattern Stamp: repeating pattern shapes
    if (stroke.brush.isPatternStamp) {
      _renderPatternStampStroke(canvas, stroke, layerOpacity);
      return;
    }

    // Pixel Brush: snap-to-grid pixel art
    if (stroke.brush.isPixel) {
      _renderPixelStroke(canvas, stroke, layerOpacity);
      return;
    }

    // Glow neon tool: bloom outer glow first, mid bloom, and sharp luminous core filament
    if (stroke.brush.isGlow) {
      final glowSize = max(2.0, stroke.brush.size);
      // 1. Soft outer bloom
      final glowPaint = _buildPaint(stroke, layerOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, max(0.1, glowSize * 0.75))
        ..color = stroke.color.withValues(alpha: (0.65 * layerOpacity).clamp(0.0, 1.0));

      // 2. Saturated mid bloom
      final midPaint = _buildPaint(stroke, layerOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, max(0.1, glowSize * 0.25))
        ..color = stroke.color.withValues(alpha: (0.85 * layerOpacity).clamp(0.0, 1.0));

      // 3. Crisp luminous core filament
      final coreColor =
          Color.lerp(stroke.color, const Color(0xFFFFFFFF), 0.6) ??
          const Color(0xFFFFFFFF);
      final corePaint = _buildPaint(stroke, layerOpacity)
        ..maskFilter = null
        ..color = coreColor.withValues(alpha: (0.95 * layerOpacity).clamp(0.0, 1.0));

      if (stroke.points.length == 1) {
        final pt = stroke.points.first;
        canvas.drawCircle(pt.offset, glowSize * 1.2, glowPaint);
        canvas.drawCircle(pt.offset, glowSize * 0.6, midPaint);
        canvas.drawCircle(pt.offset, (glowSize * 0.25).clamp(1.5, 15.0), corePaint);
      } else {
        _renderSoftStroke(canvas, stroke, glowPaint, widthMultiplier: 2.4);
        _renderSoftStroke(canvas, stroke, midPaint, widthMultiplier: 1.2);
        _renderSoftStroke(canvas, stroke, corePaint, widthMultiplier: 0.45);
      }
      return;
    }

    final paint = _buildPaint(stroke, layerOpacity);

    if (stroke.points.length == 1) {
      // Single dot
      final point = stroke.points.first;
      final radius = max(0.5, stroke.brush.size * point.pressure / 2);
      canvas.drawCircle(point.offset, radius, paint);
      return;
    }

    if (stroke.brush.hardness >= 0.9 && !stroke.brush.isGlow) {
      // Hard brushes: use connected line segments for crisp edges
      _renderHardStroke(canvas, stroke, paint);
    } else {
      // Soft / glow brushes: use path with smoothing
      _renderSoftStroke(canvas, stroke, paint);
    }
  }

  /// Render geometric shapes (Line, Rect, Circle, Triangle, Star) or Flood Fill
  static void _renderShapeOrFill(Canvas canvas, Stroke stroke, double layerOpacity) {
    final strokePaint = _buildPaint(stroke, layerOpacity);
    final fillPaint = _buildPaint(stroke, layerOpacity)..style = PaintingStyle.fill;

    final p1 = stroke.points.first.offset;
    final p2 = stroke.points.last.offset;
    final rect = Rect.fromPoints(p1, p2);

    switch (stroke.shapeType) {
      case ShapeType.none:
        break;

      case ShapeType.line:
        canvas.drawLine(p1, p2, strokePaint);
        break;

      case ShapeType.rectangle:
        if (stroke.isFilled) {
          canvas.drawRect(rect, fillPaint);
        }
        canvas.drawRect(rect, strokePaint);
        break;

      case ShapeType.roundedRectangle:
        final cornerRadius = Radius.circular(min(rect.width.abs(), rect.height.abs()) * 0.18);
        final rrect = RRect.fromRectAndRadius(rect, cornerRadius);
        if (stroke.isFilled) {
          canvas.drawRRect(rrect, fillPaint);
        }
        canvas.drawRRect(rrect, strokePaint);
        break;

      case ShapeType.circle:
        if (stroke.isFilled) {
          canvas.drawOval(rect, fillPaint);
        }
        canvas.drawOval(rect, strokePaint);
        break;

      case ShapeType.triangle:
        final path = Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
        if (stroke.isFilled) {
          canvas.drawPath(path, fillPaint);
        }
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.star:
        final path = _buildStarPath(rect);
        if (stroke.isFilled) {
          canvas.drawPath(path, fillPaint);
        }
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.heart:
        final path = _buildHeartPath(rect);
        if (stroke.isFilled) {
          canvas.drawPath(path, fillPaint);
        }
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.hexagon:
        final path = _buildHexagonPath(rect);
        if (stroke.isFilled) {
          canvas.drawPath(path, fillPaint);
        }
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.diamond:
        final path = _buildDiamondPath(rect);
        if (stroke.isFilled) {
          canvas.drawPath(path, fillPaint);
        }
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.arrow:
        final path = _buildArrowPath(rect);
        if (stroke.isFilled) {
          canvas.drawPath(path, fillPaint);
        }
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.cloud:
        final path = _buildCloudPath(rect);
        if (stroke.isFilled) {
          canvas.drawPath(path, fillPaint);
        }
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.speechBubble:
        final path = _buildSpeechBubblePath(rect);
        if (stroke.isFilled) {
          canvas.drawPath(path, fillPaint);
        }
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.floodFill:
        if (stroke.points.length < 2) return;
        final path = Path();
        final spanHeight = max(stroke.brush.size, 2.0);
        for (int i = 0; i < stroke.points.length - 1; i += 2) {
          final p1 = stroke.points[i];
          final p2 = stroke.points[i + 1];
          final left = min(p1.x, p2.x);
          final right = max(p1.x, p2.x) + 1.0;
          path.addRect(Rect.fromLTRB(left, p1.y, right, p1.y + spanHeight));
        }
        canvas.drawPath(path, fillPaint);
        break;

      case ShapeType.gradientFill:
        _renderGradientFill(canvas, stroke, layerOpacity);
        break;

      case ShapeType.text:
        if (stroke.text == null || stroke.text!.isEmpty) return;
        final position = stroke.points.isNotEmpty ? stroke.points.first.offset : Offset.zero;
        final font = FontCatalogService.instance.getFontByName(stroke.fontFamily ?? 'Poppins');
        final effectiveAlpha = (stroke.brush.opacity * layerOpacity).clamp(0.0, 1.0);

        TextDecoration decoration = TextDecoration.none;
        if (stroke.textDecoration == 'underline') {
          decoration = TextDecoration.underline;
        } else if (stroke.textDecoration == 'strikethrough') {
          decoration = TextDecoration.lineThrough;
        }

        List<Shadow>? shadows;
        if (stroke.hasShadow) {
          shadows = [
            Shadow(
              color: const Color(0xFF000000).withValues(alpha: 0.6 * effectiveAlpha),
              offset: Offset(stroke.textShadowOffsetX, stroke.textShadowOffsetY),
              blurRadius: stroke.textShadowBlur,
            ),
          ];
        }

        final fontSize = max(8.0, stroke.fontSize ?? 32.0);

        final baseStyle = TextStyle(
          fontSize: fontSize,
          color: stroke.color.withValues(alpha: effectiveAlpha),
          fontWeight: stroke.isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: stroke.isItalic ? FontStyle.italic : FontStyle.normal,
          decoration: decoration,
          shadows: shadows,
          height: stroke.textLineHeight,
        );
        final styledText = font.applyStyle(baseStyle);

        TextAlign align = TextAlign.left;
        if (stroke.textAlign == 'center') {
          align = TextAlign.center;
        } else if (stroke.textAlign == 'right') {
          align = TextAlign.right;
        } else if (stroke.textAlign == 'justify') {
          align = TextAlign.justify;
        }

        final span = TextSpan(text: stroke.text, style: styledText);
        final tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          textAlign: align,
        );
        tp.layout();

        // 1. Draw optional background box / pill
        if (stroke.textBackgroundColor != null) {
          const padH = 12.0;
          const padV = 6.0;
          final bgRect = Rect.fromLTWH(
            position.dx - padH,
            position.dy - padV,
            tp.width + (padH * 2),
            tp.height + (padV * 2),
          );
          final bgPaint = Paint()
            ..color = stroke.textBackgroundColor!.withValues(alpha: effectiveAlpha)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(8.0)), bgPaint);
        }

        // 2. Draw high-contrast text stroke outline if specified
        final strokeW = stroke.textStrokeWidth ?? 0.0;
        if (strokeW > 0.0) {
          final strokeColor = (stroke.textStrokeColor ?? const Color(0xFF000000))
              .withValues(alpha: effectiveAlpha);
          final strokeStyle = font.applyStyle(TextStyle(
            fontSize: fontSize,
            fontWeight: stroke.isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: stroke.isItalic ? FontStyle.italic : FontStyle.normal,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeW
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
            height: stroke.textLineHeight,
          ));
          final strokeSpan = TextSpan(text: stroke.text, style: strokeStyle);
          final tpStroke = TextPainter(
            text: strokeSpan,
            textDirection: TextDirection.ltr,
            textAlign: align,
          );
          tpStroke.layout();
          tpStroke.paint(canvas, position);
          tpStroke.dispose();
        }

        // 3. Draw foreground filled text
        tp.paint(canvas, position);
        tp.dispose();
        break;

      case ShapeType.pentagon:
        final path = _buildRegularPolygonPath(rect, 5);
        if (stroke.isFilled) canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.octagon:
        final path = _buildRegularPolygonPath(rect, 8);
        if (stroke.isFilled) canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.ring:
        final path = _buildRingPath(rect);
        if (stroke.isFilled) canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.cross:
        final path = _buildCrossPath(rect);
        if (stroke.isFilled) canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.crescent:
        final path = _buildCrescentPath(rect);
        if (stroke.isFilled) canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.chevron:
        final path = _buildChevronPath(rect);
        if (stroke.isFilled) canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.playButton:
        final path = _buildPlayButtonPath(rect);
        if (stroke.isFilled) canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.musicNote:
        final path = _buildMusicNotePath(rect);
        if (stroke.isFilled) canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.crown:
        final path = _buildCrownPath(rect);
        if (stroke.isFilled) canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.banner:
        final path = _buildBannerPath(rect);
        if (stroke.isFilled) canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.starburst:
        final path = _buildStarPath(rect, points: 12);
        if (stroke.isFilled) canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.shield:
        final path = _buildShieldPath(rect);
        if (stroke.isFilled) canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        break;

      case ShapeType.image:
        if (stroke.imagePath == null) return;
        final uiImage = ImageCacheService.instance.getImageSync(stroke.imagePath!);
        if (uiImage == null) return;

        final p1 = stroke.points.first.offset;
        final p2 = stroke.points.length > 1
            ? stroke.points[1].offset
            : p1 + Offset(uiImage.width.toDouble(), uiImage.height.toDouble());
        final dstRect = Rect.fromPoints(p1, p2);
        final srcRect = Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble());

        final effectiveAlpha = (stroke.brush.opacity * layerOpacity).clamp(0.0, 1.0);
        final imgPaint = Paint()
          ..color = Color.fromRGBO(255, 255, 255, effectiveAlpha)
          ..blendMode = stroke.blendMode.toFlutterBlendMode()
          ..filterQuality = FilterQuality.medium;

        final rotation = stroke.imageRotation ?? 0.0;
        if (rotation != 0.0) {
          canvas.save();
          final center = dstRect.center;
          canvas.translate(center.dx, center.dy);
          canvas.rotate(rotation);
          canvas.translate(-center.dx, -center.dy);
          canvas.drawImageRect(uiImage, srcRect, dstRect, imgPaint);
          canvas.restore();
        } else {
          canvas.drawImageRect(uiImage, srcRect, dstRect, imgPaint);
        }
        break;
    }
  }

  /// Build a heart shape path centered within the bounding rect.
  static Path _buildHeartPath(Rect rect) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final width = rect.width;
    final height = rect.height;
    final left = rect.left;
    final top = rect.top;

    path.moveTo(left + width / 2, top + height * 0.82);
    path.cubicTo(
      left + width * 0.05,
      top + height * 0.52,
      left,
      top + height * 0.18,
      left + width * 0.26,
      top,
    );
    path.cubicTo(
      left + width * 0.44,
      top,
      left + width / 2,
      top + height * 0.24,
      left + width / 2,
      top + height * 0.24,
    );
    path.cubicTo(
      left + width / 2,
      top + height * 0.24,
      left + width * 0.56,
      top,
      left + width * 0.74,
      top,
    );
    path.cubicTo(
      left + width,
      top + height * 0.18,
      left + width * 0.95,
      top + height * 0.52,
      left + width / 2,
      top + height * 0.82,
    );
    path.close();
    return path;
  }

  /// Build a regular hexagon path within the bounding rect.
  static Path _buildHexagonPath(Rect rect) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final center = rect.center;
    final radius = min(rect.width, rect.height) / 2;
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * pi / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  /// Build a diamond (rhombus) path within the bounding rect.
  static Path _buildDiamondPath(Rect rect) {
    return Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right, rect.center.dy)
      ..lineTo(rect.center.dx, rect.bottom)
      ..lineTo(rect.left, rect.center.dy)
      ..close();
  }

  /// Build an arrow path pointing right within the bounding rect.
  static Path _buildArrowPath(Rect rect) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final w = rect.width;
    final h = rect.height;
    final l = rect.left;
    final t = rect.top;

    final shaftTop = t + h * 0.35;
    final shaftBottom = t + h * 0.65;
    final headStart = l + w * 0.6;

    path.moveTo(l, shaftTop);
    path.lineTo(headStart, shaftTop);
    path.lineTo(headStart, t + h * 0.1);
    path.lineTo(rect.right, t + h * 0.5);
    path.lineTo(headStart, t + h * 0.9);
    path.lineTo(headStart, shaftBottom);
    path.lineTo(l, shaftBottom);
    path.close();
    return path;
  }

  /// Build a fluffy cloud path within the bounding rect.
  static Path _buildCloudPath(Rect rect) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, rect.top + rect.height * 0.25, rect.width, rect.height * 0.75),
      Radius.circular(rect.height * 0.35),
    );
    path.addRRect(r);
    path.addOval(Rect.fromCircle(
      center: Offset(rect.left + rect.width * 0.35, rect.top + rect.height * 0.4),
      radius: rect.height * 0.38,
    ));
    path.addOval(Rect.fromCircle(
      center: Offset(rect.left + rect.width * 0.65, rect.top + rect.height * 0.32),
      radius: rect.height * 0.32,
    ));
    return path;
  }

  /// Build a comic speech bubble path with a tail at bottom-left.
  static Path _buildSpeechBubblePath(Rect rect) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final bubbleRect = Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.8);
    final r = RRect.fromRectAndRadius(bubbleRect, Radius.circular(rect.height * 0.2));
    path.addRRect(r);
    final tail = Path()
      ..moveTo(rect.left + rect.width * 0.2, rect.top + rect.height * 0.78)
      ..lineTo(rect.left + rect.width * 0.1, rect.bottom)
      ..lineTo(rect.left + rect.width * 0.38, rect.top + rect.height * 0.78)
      ..close();
    path.addPath(tail, Offset.zero);
    return path;
  }

  /// Render scattered airbrush / spray droplets.
  static void _renderSprayStroke(Canvas canvas, Stroke stroke, double layerOpacity) {
    final paint = _buildPaint(stroke, layerOpacity)
      ..style = PaintingStyle.fill
      ..maskFilter = null; // Spray particles are crisp discrete droplets
    final radius = stroke.brush.size * 0.7;
    final density = (stroke.brush.flow * 14).round().clamp(6, 22);

    for (int i = 0; i < stroke.points.length; i++) {
      final pt = stroke.points[i];
      int seed = (pt.x * 1000 + pt.y * 100 + i).round().abs();
      for (int s = 0; s < density; s++) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        final angle = (seed % 628) / 100.0;
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        final dist = ((seed % 1000) / 1000.0) * radius;
        final dotX = pt.x + dist * cos(angle);
        final dotY = pt.y + dist * sin(angle);
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        final dotRadius = 0.5 + ((seed % 100) / 100.0) * (stroke.brush.size * 0.08);

        canvas.drawCircle(Offset(dotX, dotY), dotRadius, paint);
      }
    }
  }

  /// Render highlighter translucent stroke with flat chisel geometry and multiply blending.
  static void _renderHighlighterStroke(Canvas canvas, Stroke stroke, double layerOpacity) {
    final effectiveOpacity = (stroke.brush.opacity * 0.55 * layerOpacity).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = stroke.color.withValues(alpha: effectiveOpacity)
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..strokeWidth = max(2.0, stroke.brush.size)
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.multiply
      ..isAntiAlias = true;

    if (stroke.points.length == 1) {
      final p = stroke.points.first;
      canvas.drawRect(
        Rect.fromCenter(center: p.offset, width: stroke.brush.size, height: stroke.brush.size * 0.7),
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path();
    path.moveTo(stroke.points.first.x, stroke.points.first.y);
    for (int i = 1; i < stroke.points.length; i++) {
      final p = stroke.points[i];
      path.lineTo(p.x, p.y);
    }
    canvas.drawPath(path, paint);
  }

  /// Render magical rainbow brush with continuous chromatic spectrum progression.
  static void _renderRainbowStroke(Canvas canvas, Stroke stroke, double layerOpacity) {
    if (stroke.points.length == 1) {
      final p = stroke.points.first;
      final paint = Paint()
        ..color = _getRainbowColor(0.0, stroke.rainbowMode)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.offset, max(1.0, stroke.brush.size / 2), paint);
      return;
    }

    final mode = stroke.rainbowMode ?? RainbowMode.spectrum;
    final totalPoints = stroke.points.length;

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];
      final progress = (i / max(1, totalPoints - 1)) % 1.0;
      final color = _getRainbowColor(progress, mode);

      final width = max(1.0, stroke.brush.size * ((p1.pressure + p2.pressure) / 2));
      final paint = Paint()
        ..color = color.withValues(alpha: (stroke.brush.opacity * layerOpacity).clamp(0.0, 1.0))
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = stroke.blendMode.toFlutterBlendMode()
        ..isAntiAlias = true;

      canvas.drawLine(p1.offset, p2.offset, paint);
    }
  }

  static Color _getRainbowColor(double progress, RainbowMode? mode) {
    switch (mode) {
      case RainbowMode.pastel:
        final hue = (progress * 360.0) % 360.0;
        return HSVColor.fromAHSV(1.0, hue, 0.45, 0.98).toColor();

      case RainbowMode.neon:
        const colors = [
          Color(0xFF00F0FF),
          Color(0xFFFF007F),
          Color(0xFF39FF14),
          Color(0xFFFFEE00),
          Color(0xFFBF00FF),
          Color(0xFFFF5F00),
        ];
        final index = (progress * colors.length).floor() % colors.length;
        final next = (index + 1) % colors.length;
        final t = (progress * colors.length) - (progress * colors.length).floor();
        return Color.lerp(colors[index], colors[next], t) ?? colors[index];

      case RainbowMode.sunset:
        const colors = [
          Color(0xFFFF2A6D),
          Color(0xFFFF5E36),
          Color(0xFFFFAA00),
          Color(0xFFFFD600),
          Color(0xFF9D00FF),
        ];
        final index = (progress * colors.length).floor() % colors.length;
        final next = (index + 1) % colors.length;
        final t = (progress * colors.length) - (progress * colors.length).floor();
        return Color.lerp(colors[index], colors[next], t) ?? colors[index];

      case RainbowMode.spectrum:
      default:
        final hue = (progress * 360.0) % 360.0;
        return HSVColor.fromAHSV(1.0, hue, 0.9, 0.95).toColor();
    }
  }

  /// Render 2-stop smooth linear or radial gradient fill.
  static void _renderGradientFill(Canvas canvas, Stroke stroke, double layerOpacity) {
    if (stroke.points.length < 2) return;
    final p1 = stroke.points.first.offset;
    final p2 = stroke.points.last.offset;
    final distance = (p2 - p1).distance;
    if (distance < 1.0) return;

    final primary = stroke.color.withValues(alpha: (stroke.brush.opacity * layerOpacity).clamp(0.0, 1.0));
    final secondary = (stroke.secondaryColor ?? stroke.color.withValues(alpha: 0.15))
        .withValues(alpha: (stroke.brush.opacity * layerOpacity).clamp(0.0, 1.0));

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = stroke.blendMode.toFlutterBlendMode();

    final isRadial = stroke.gradientType == GradientType.radial;
    if (isRadial) {
      final radius = max(10.0, distance);
      paint.shader = ui.Gradient.radial(
        p1,
        radius,
        [primary, secondary],
      );
      canvas.drawCircle(p1, radius, paint);
    } else {
      paint.shader = ui.Gradient.linear(
        p1,
        p2,
        [primary, secondary],
      );
      final rawRect = Rect.fromPoints(p1, p2);
      final rect = (rawRect.width < 10 || rawRect.height < 10)
          ? rawRect.inflate(max(20.0, stroke.brush.size))
          : rawRect;
      canvas.drawRect(rect, paint);
    }
  }

  /// Render calligraphy pen stroke with angle-dependent nib width.
  ///
  /// Simulates a flat nib by varying the drawn width based on the direction
  /// angle between consecutive stroke points. Horizontal strokes are thin;
  /// vertical strokes are thick — just like a real calligraphy pen held at ~45°.
  static void _renderCalligraphyStroke(Canvas canvas, Stroke stroke, double layerOpacity) {
    final paint = _buildPaint(stroke, layerOpacity)
      ..strokeCap = StrokeCap.square
      ..maskFilter = null;

    if (stroke.points.length == 1) {
      final pt = stroke.points.first;
      canvas.drawCircle(pt.offset, max(0.5, stroke.brush.size / 2), paint);
      return;
    }

    // Nib angle in radians (~45° default)
    const nibAngle = pi / 4;
    final maxWidth = stroke.brush.size;
    final minWidth = maxWidth * 0.15; // Thin edge of the nib

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p0 = stroke.points[i];
      final p1 = stroke.points[i + 1];
      final dx = p1.x - p0.x;
      final dy = p1.y - p0.y;
      final segAngle = atan2(dy, dx);

      // Width varies sinusoidally with the difference from the nib angle
      final angleDiff = (segAngle - nibAngle).abs();
      final widthFactor = (sin(angleDiff)).abs();
      final width = (minWidth + (maxWidth - minWidth) * widthFactor)
          .clamp(minWidth, maxWidth);

      paint.strokeWidth = max(0.5, width * ((p0.pressure + p1.pressure) / 2));
      canvas.drawLine(p0.offset, p1.offset, paint);
    }
  }

  /// Render crayon / pastel textured stroke.
  ///
  /// Creates a rough, dry-media look by scattering semi-transparent particles
  /// along the stroke path, with varying sizes and alpha values.
  static void _renderCrayonStroke(Canvas canvas, Stroke stroke, double layerOpacity) {
    final brushSize = stroke.brush.size;
    final scatter = (stroke.brush.scatter * brushSize).clamp(2.0, brushSize * 0.8);

    for (int i = 0; i < stroke.points.length; i++) {
      final pt = stroke.points[i];
      // Number of particles per point scaled by brush size
      final particleCount = (brushSize * 0.5).round().clamp(4, 18);

      for (int p = 0; p < particleCount; p++) {
        // Deterministic pseudo-random based on position and index
        int seed = ((pt.x * 373 + pt.y * 571 + i * 137 + p * 41)).round().abs();
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        final offsetX = ((seed % 1000) / 500.0 - 1.0) * scatter;
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        final offsetY = ((seed % 1000) / 500.0 - 1.0) * scatter;
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        final particleAlpha = 0.2 + ((seed % 100) / 100.0) * 0.5;
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        final particleRadius = 0.8 + ((seed % 100) / 100.0) * (brushSize * 0.12);

        final crayonPaint = Paint()
          ..color = stroke.color.withValues(alpha: (particleAlpha * layerOpacity * stroke.brush.opacity).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(pt.x + offsetX, pt.y + offsetY),
          particleRadius,
          crayonPaint,
        );
      }
    }

    // Also draw a semi-transparent core path for continuity
    if (stroke.points.length >= 2) {
      final corePaint = _buildPaint(stroke, layerOpacity)
        ..color = stroke.color.withValues(alpha: (0.3 * layerOpacity * stroke.brush.opacity).clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, max(0.1, brushSize * 0.15));
      _renderSoftStroke(canvas, stroke, corePaint, widthMultiplier: 0.6);
    }
  }

  /// Render dotted pen — evenly-spaced circles along the stroke path.
  static void _renderDottedStroke(Canvas canvas, Stroke stroke, double layerOpacity) {
    final paint = _buildPaint(stroke, layerOpacity)
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    final dotRadius = max(1.0, stroke.brush.size / 2);
    final dotSpacing = max(dotRadius * 2.5, stroke.brush.size * stroke.brush.spacing * 8);

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first.offset, dotRadius, paint);
      return;
    }

    // Walk the polyline at even intervals and place dots
    double accumulated = 0;
    canvas.drawCircle(stroke.points.first.offset, dotRadius, paint); // first dot

    for (int i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];
      final dx = curr.x - prev.x;
      final dy = curr.y - prev.y;
      final segLen = sqrt(dx * dx + dy * dy);
      if (segLen < 0.1) continue;

      final ux = dx / segLen;
      final uy = dy / segLen;

      double walked = 0;
      while (walked < segLen) {
        final remaining = max(0.1, dotSpacing - accumulated);
        if (walked + remaining <= segLen) {
          walked += remaining;
          accumulated = 0;
          final px = prev.x + ux * walked;
          final py = prev.y + uy * walked;
          canvas.drawCircle(Offset(px, py), dotRadius, paint);
        } else {
          accumulated += segLen - walked;
          break;
        }
      }
    }
  }

  /// Render pattern stamp — repeating shapes along the stroke path.
  static void _renderPatternStampStroke(Canvas canvas, Stroke stroke, double layerOpacity) {
    final paint = _buildPaint(stroke, layerOpacity)
      ..style = PaintingStyle.fill
      ..maskFilter = null;
    final stampSize = max(4.0, stroke.brush.size);
    final stampSpacing = max(stampSize * 1.5, stampSize * stroke.brush.spacing * 6);
    final stampType = stroke.stampType ?? PatternStampType.star;

    if (stroke.points.length == 1) {
      _drawStampAt(canvas, stroke.points.first.offset, stampSize, paint, stampType);
      return;
    }

    double accumulated = 0;
    _drawStampAt(canvas, stroke.points.first.offset, stampSize, paint, stampType);

    for (int i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];
      final dx = curr.x - prev.x;
      final dy = curr.y - prev.y;
      final segLen = sqrt(dx * dx + dy * dy);
      if (segLen < 0.1) continue;

      final ux = dx / segLen;
      final uy = dy / segLen;

      double walked = 0;
      while (walked < segLen) {
        final remaining = max(0.1, stampSpacing - accumulated);
        if (walked + remaining <= segLen) {
          walked += remaining;
          accumulated = 0;
          final px = prev.x + ux * walked;
          final py = prev.y + uy * walked;
          _drawStampAt(canvas, Offset(px, py), stampSize, paint, stampType);
        } else {
          accumulated += segLen - walked;
          break;
        }
      }
    }
  }

  /// Draw a single pattern stamp at a position based on selected PatternStampType.
  static void _drawStampAt(Canvas canvas, Offset center, double size, Paint paint, PatternStampType type) {
    final path = Path();
    final half = size / 2;
    final rect = Rect.fromCenter(center: center, width: size, height: size);

    switch (type) {
      case PatternStampType.star:
        const points = 5;
        final outerR = half;
        final innerR = outerR * 0.42;
        const angleStep = pi / points;
        for (int i = 0; i < 2 * points; i++) {
          final r = i % 2 == 0 ? outerR : innerR;
          final angle = i * angleStep - pi / 2;
          final x = center.dx + r * cos(angle);
          final y = center.dy + r * sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        break;

      case PatternStampType.heart:
        path.addPath(_buildHeartPath(rect), Offset.zero);
        break;

      case PatternStampType.flower:
        const petals = 5;
        const step = 2 * pi / petals;
        for (int i = 0; i < petals; i++) {
          final angle = i * step;
          final petalCenter = Offset(
            center.dx + half * 0.5 * cos(angle),
            center.dy + half * 0.5 * sin(angle),
          );
          canvas.drawCircle(petalCenter, half * 0.4, paint);
        }
        final corePaint = Paint()
          ..color = Color.lerp(paint.color, const Color(0xFFFFEB3B), 0.7) ?? paint.color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, half * 0.3, corePaint);
        return;

      case PatternStampType.diamond:
        path.addPath(_buildDiamondPath(rect), Offset.zero);
        break;

      case PatternStampType.spiral:
        final spiralPaint = Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, size * 0.12)
          ..strokeCap = StrokeCap.round;
        final spiralPath = Path();
        for (double t = 0; t < 3 * pi; t += 0.15) {
          final r = (t / (3 * pi)) * half;
          final x = center.dx + r * cos(t);
          final y = center.dy + r * sin(t);
          if (t == 0) {
            spiralPath.moveTo(x, y);
          } else {
            spiralPath.lineTo(x, y);
          }
        }
        canvas.drawPath(spiralPath, spiralPaint);
        return;

      case PatternStampType.leaf:
        path.moveTo(center.dx, center.dy - half);
        path.quadraticBezierTo(center.dx + half * 0.8, center.dy, center.dx, center.dy + half);
        path.quadraticBezierTo(center.dx - half * 0.8, center.dy, center.dx, center.dy - half);
        path.close();
        break;
    }

    canvas.drawPath(path, paint);
  }

  /// Render pixel brush — snaps to grid and draws filled squares.
  static void _renderPixelStroke(Canvas canvas, Stroke stroke, double layerOpacity) {
    final paint = _buildPaint(stroke, layerOpacity)
      ..style = PaintingStyle.fill
      ..maskFilter = null
      ..isAntiAlias = false; // Crisp pixel edges
    final gridSize = max(2.0, stroke.brush.size);

    // Track visited grid cells to avoid overdraw
    final visited = <int>{};

    for (final pt in stroke.points) {
      final gx = (pt.x / gridSize).floor();
      final gy = (pt.y / gridSize).floor();
      final key = gx * 100000 + gy; // Simple hash for grid cell
      if (visited.add(key)) {
        canvas.drawRect(
          Rect.fromLTWH(gx * gridSize, gy * gridSize, gridSize, gridSize),
          paint,
        );
      }
    }
  }

  static Path _buildStarPath(Rect rect, {int points = 5}) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final center = rect.center;
    final outerR = min(rect.width, rect.height) / 2;
    final innerR = outerR * (points > 8 ? 0.65 : 0.45);
    final angleStep = pi / points;

    for (int i = 0; i < 2 * points; i++) {
      final r = i % 2 == 0 ? outerR : innerR;
      final angle = i * angleStep - pi / 2;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  static Path _buildRegularPolygonPath(Rect rect, int sides) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final center = rect.center;
    final radius = min(rect.width, rect.height) / 2;
    for (int i = 0; i < sides; i++) {
      final angle = (2 * pi * i / sides) - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  static Path _buildRingPath(Rect rect) {
    final path = Path()..fillType = PathFillType.evenOdd;
    if (rect.width <= 0 || rect.height <= 0) return path;
    final center = rect.center;
    final outerR = min(rect.width, rect.height) / 2;
    final innerR = outerR * 0.6;
    path.addOval(Rect.fromCircle(center: center, radius: outerR));
    path.addOval(Rect.fromCircle(center: center, radius: innerR));
    return path;
  }

  static Path _buildCrossPath(Rect rect) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final r = min(rect.width, rect.height) / 2;
    final w = r * 0.35;
    path
      ..moveTo(cx - w, cy - r)
      ..lineTo(cx + w, cy - r)
      ..lineTo(cx + w, cy - w)
      ..lineTo(cx + r, cy - w)
      ..lineTo(cx + r, cy + w)
      ..lineTo(cx + w, cy + w)
      ..lineTo(cx + w, cy + r)
      ..lineTo(cx - w, cy + r)
      ..lineTo(cx - w, cy + w)
      ..lineTo(cx - r, cy + w)
      ..lineTo(cx - r, cy - w)
      ..lineTo(cx - w, cy - w)
      ..close();
    return path;
  }

  static Path _buildCrescentPath(Rect rect) {
    if (rect.width <= 0 || rect.height <= 0) return Path();
    final center = rect.center;
    final r = min(rect.width, rect.height) / 2;
    final fullCircle = Path()..addOval(Rect.fromCircle(center: center, radius: r));
    final cutCircle = Path()
      ..addOval(Rect.fromCircle(center: Offset(center.dx + r * 0.5, center.dy), radius: r * 0.85));
    return Path.combine(PathOperation.difference, fullCircle, cutCircle);
  }

  static Path _buildChevronPath(Rect rect) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final r = min(rect.width, rect.height) / 2;
    final thick = r * 0.35;
    path
      ..moveTo(cx - r * 0.5, cy - r)
      ..lineTo(cx + r * 0.5, cy)
      ..lineTo(cx - r * 0.5, cy + r)
      ..lineTo(cx - r * 0.5 + thick, cy + r)
      ..lineTo(cx + r * 0.5 + thick, cy)
      ..lineTo(cx - r * 0.5 + thick, cy - r)
      ..close();
    return path;
  }

  static Path _buildPlayButtonPath(Rect rect) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final r = min(rect.width, rect.height) / 2;
    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    final tri = Path()
      ..moveTo(cx - r * 0.25, cy - r * 0.45)
      ..lineTo(cx + r * 0.5, cy)
      ..lineTo(cx - r * 0.25, cy + r * 0.45)
      ..close();
    path.addPath(tri, Offset.zero);
    return path;
  }

  static Path _buildMusicNotePath(Rect rect) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final r = min(rect.width, rect.height) / 2;
    path.addOval(Rect.fromCenter(center: Offset(cx - r * 0.25, cy + r * 0.45), width: r * 0.65, height: r * 0.45));
    path.addRect(Rect.fromLTWH(cx + r * 0.05, cy - r * 0.7, r * 0.12, r * 1.15));
    final flag = Path()
      ..moveTo(cx + r * 0.17, cy - r * 0.7)
      ..quadraticBezierTo(cx + r * 0.6, cy - r * 0.5, cx + r * 0.45, cy - r * 0.1)
      ..quadraticBezierTo(cx + r * 0.35, cy - r * 0.4, cx + r * 0.17, cy - r * 0.45)
      ..close();
    path.addPath(flag, Offset.zero);
    return path;
  }

  static Path _buildCrownPath(Rect rect) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final r = min(rect.width, rect.height) / 2;
    path
      ..moveTo(cx - r, cy + r * 0.5)
      ..lineTo(cx - r, cy - r * 0.2)
      ..lineTo(cx - r * 0.5, cy + r * 0.1)
      ..lineTo(cx, cy - r * 0.7)
      ..lineTo(cx + r * 0.5, cy + r * 0.1)
      ..lineTo(cx + r, cy - r * 0.2)
      ..lineTo(cx + r, cy + r * 0.5)
      ..close();
    return path;
  }

  static Path _buildBannerPath(Rect rect) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final r = min(rect.width, rect.height) / 2;
    path
      ..moveTo(cx - r, cy - r * 0.45)
      ..lineTo(cx + r, cy - r * 0.45)
      ..lineTo(cx + r, cy + r * 0.45)
      ..lineTo(cx + r * 0.65, cy + r * 0.15)
      ..lineTo(cx + r * 0.35, cy + r * 0.45)
      ..lineTo(cx - r * 0.35, cy + r * 0.45)
      ..lineTo(cx - r * 0.65, cy + r * 0.15)
      ..lineTo(cx - r, cy + r * 0.45)
      ..close();
    return path;
  }

  static Path _buildShieldPath(Rect rect) {
    final path = Path();
    if (rect.width <= 0 || rect.height <= 0) return path;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final r = min(rect.width, rect.height) / 2;
    path
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.9, cy - r * 0.6)
      ..lineTo(cx + r * 0.9, cy + r * 0.15)
      ..quadraticBezierTo(cx + r * 0.45, cy + r * 0.85, cx, cy + r)
      ..quadraticBezierTo(cx - r * 0.45, cy + r * 0.85, cx - r * 0.9, cy + r * 0.15)
      ..lineTo(cx - r * 0.9, cy - r * 0.6)
      ..close();
    return path;
  }

  /// Render a hard-edged stroke using line segments.
  static void _renderHardStroke(Canvas canvas, Stroke stroke, Paint paint) {
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p0 = stroke.points[i];
      final p1 = stroke.points[i + 1];

      // Pressure-sensitive width
      final width = max(0.5, stroke.brush.size * ((p0.pressure + p1.pressure) / 2));
      paint.strokeWidth = width;

      canvas.drawLine(p0.offset, p1.offset, paint);
    }
  }

  /// Render a soft stroke using Catmull-Rom spline interpolation.
  static void _renderSoftStroke(
    Canvas canvas,
    Stroke stroke,
    Paint paint, {
    double widthMultiplier = 1.0,
  }) {
    final path = Path();
    final points = stroke.points;

    if (points.length < 3) {
      paint.strokeWidth = max(0.5, stroke.brush.size * points.first.pressure * widthMultiplier);
      path.moveTo(points.first.x, points.first.y);
      path.lineTo(points.last.x, points.last.y);
      canvas.drawPath(path, paint);
      return;
    }

    // Catmull-Rom spline for smooth curves
    path.moveTo(points.first.x, points.first.y);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      // Catmull-Rom to cubic Bezier conversion
      final cp1x = p1.x + (p2.x - p0.x) / 6;
      final cp1y = p1.y + (p2.y - p0.y) / 6;
      final cp2x = p2.x - (p3.x - p1.x) / 6;
      final cp2y = p2.y - (p3.y - p1.y) / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.x, p2.y);
    }

    // Apply stroke width as average pressure
    final avgPressure =
        points.map((p) => p.pressure).reduce((a, b) => a + b) / points.length;
    paint.strokeWidth = max(0.5, stroke.brush.size * avgPressure * widthMultiplier);

    canvas.drawPath(path, paint);
  }

  /// Build the Paint object from brush parameters.
  static Paint _buildPaint(Stroke stroke, double layerOpacity) {
    final brush = stroke.brush;
    final effectiveOpacity = (brush.opacity * layerOpacity).clamp(0.0, 1.0);

    final paint =
        Paint()
          ..color = stroke.color.withValues(alpha: effectiveOpacity)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = max(0.5, brush.size)
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;

    if (brush.isEraser) {
      paint.blendMode = BlendMode.clear;
    } else {
      paint.blendMode = stroke.blendMode.toFlutterBlendMode();
    }

    // Apply blur and smudge brush behaviors
    if (brush.isBlur) {
      final sigma = max(1.0, brush.size * 0.4);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
      paint.color = stroke.color.withValues(alpha: (0.35 * layerOpacity * brush.opacity).clamp(0.0, 1.0));
    } else if (brush.isSmudge) {
      final sigma = max(0.5, brush.size * 0.22);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
      paint.color = stroke.color.withValues(alpha: (0.45 * layerOpacity * brush.opacity).clamp(0.0, 1.0));
    } else if (brush.hardness < 0.8) {
      // Apply hardness as blur effect (softer = more blur)
      final sigma = max(0.1, (1.0 - brush.hardness) * brush.size * 0.3);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);
    }

    return paint;
  }

  /// Interpolate additional points between raw input for smoother strokes.
  static List<StrokePoint> interpolatePoints(
    List<StrokePoint> rawPoints, {
    double minDistance = 2.0,
  }) {
    if (rawPoints.length < 2) return rawPoints;

    final result = <StrokePoint>[rawPoints.first];

    for (int i = 1; i < rawPoints.length; i++) {
      final prev = rawPoints[i - 1];
      final curr = rawPoints[i];
      final dx = curr.x - prev.x;
      final dy = curr.y - prev.y;
      final distance = sqrt(dx * dx + dy * dy);

      if (distance > minDistance * 2) {
        final steps = (distance / minDistance).ceil();
        for (int s = 1; s < steps; s++) {
          final t = s / steps;
          result.add(
            StrokePoint(
              x: prev.x + dx * t,
              y: prev.y + dy * t,
              pressure: prev.pressure + (curr.pressure - prev.pressure) * t,
              tilt: prev.tilt + (curr.tilt - prev.tilt) * t,
            ),
          );
        }
      }
      result.add(curr);
    }

    return result;
  }

  /// Apply stabilization and streamline rope algorithm to smooth incoming points.
  static StrokePoint stabilize(
    StrokePoint newPoint,
    List<StrokePoint> history,
    StabilizationMode mode, {
    double streamline = 0.0,
  }) {
    var candidate = newPoint;

    // Streamline (lazy-mouse / rope stabilizer): smooth trailing lag behind stylus/finger
    if (streamline > 0.0 && history.isNotEmpty) {
      final prev = history.last;
      final lagFactor = (1.0 - (streamline.clamp(0.0, 1.0) * 0.88)).clamp(0.06, 1.0);
      candidate = StrokePoint(
        x: prev.x + (newPoint.x - prev.x) * lagFactor,
        y: prev.y + (newPoint.y - prev.y) * lagFactor,
        pressure: prev.pressure + (newPoint.pressure - prev.pressure) * lagFactor,
        tilt: newPoint.tilt,
        timestamp: newPoint.timestamp,
      );
    }

    if (mode == StabilizationMode.off || history.isEmpty) return candidate;

    final strength = mode.strength;
    final windowSize = (history.length * strength).ceil().clamp(1, history.length);
    final window = history.sublist(history.length - windowSize);

    double avgX = 0, avgY = 0, avgP = 0;
    for (final p in window) {
      avgX += p.x;
      avgY += p.y;
      avgP += p.pressure;
    }
    avgX /= window.length;
    avgY /= window.length;
    avgP /= window.length;

    return StrokePoint(
      x: candidate.x * (1 - strength) + avgX * strength,
      y: candidate.y * (1 - strength) + avgY * strength,
      pressure: candidate.pressure * (1 - strength) + avgP * strength,
      tilt: candidate.tilt,
      timestamp: candidate.timestamp,
    );
  }
}
