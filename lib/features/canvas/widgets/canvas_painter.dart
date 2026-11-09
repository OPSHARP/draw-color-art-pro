import 'dart:math';
import 'package:flutter/material.dart';
import '../../../rendering/engine/stroke_renderer.dart';
import '../models/canvas_document.dart';
import '../models/drawing_guides.dart';
import '../models/stroke.dart';
import '../models/symmetry.dart';
import '../models/paper_texture.dart';
import '../../../core/theme/app_theme.dart';

/// CustomPainter that renders the entire canvas document.
///
/// Renders:
/// - Background and procedural paper textures
/// - Layers bottom-to-top with blend modes, opacity, visibility, alpha-lock & clipping masks
/// - Active in-progress stroke with live symmetry mirroring
/// - Grid, isometric & 1P/2P perspective guides overlay
/// - Symmetry guide axes and center pivot
class CanvasPainter extends CustomPainter {
  const CanvasPainter({
    required this.document,
    this.currentStroke,
    this.showGrid = false,
    this.gridSize = 32.0,
    this.drawingGuide = const DrawingGuideConfig(),
    this.symmetryConfig = const SymmetryConfig(),
    this.paperTexture = CanvasPaperTexture.none,
    this.isThumbnail = false,
    this.onionSkinEnabled = false,
  });

  final CanvasDocument document;
  final Stroke? currentStroke;
  final bool showGrid;
  final double gridSize;
  final DrawingGuideConfig drawingGuide;
  final SymmetryConfig symmetryConfig;
  final CanvasPaperTexture paperTexture;
  final bool isThumbnail;
  final bool onionSkinEnabled;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Background ──────────────────────────────────────────────
    _drawBackground(canvas, size);

    // ── Paper Texture Overlay ───────────────────────────────────
    if (paperTexture != CanvasPaperTexture.none) {
      _drawPaperTexture(canvas, size);
    }

    // ── Onion Skinning (Animation Light Table) ───────────────────
    if (onionSkinEnabled && !isThumbnail && document.layers.length > 1) {
      final activeIdx = document.activeLayerIndex;
      if (activeIdx > 0 && activeIdx - 1 < document.layers.length) {
        _drawOnionSkin(canvas, document.layers[activeIdx - 1], const Color(0xFFFF4757));
      }
      if (activeIdx < document.layers.length - 1) {
        _drawOnionSkin(canvas, document.layers[activeIdx + 1], const Color(0xFF2ED573));
      }
    }

    // ── Layers (bottom to top) ──────────────────────────────────
    bool activeLayerRendered = false;
    for (final layer in document.layers) {
      if (!layer.isVisible) continue;
      if (layer.id == document.activeLayer?.id) {
        activeLayerRendered = true;
      }
      _drawLayer(canvas, layer);
    }

    // ── Current stroke fallback (if active layer was not rendered or hidden) ──
    if (!activeLayerRendered &&
        currentStroke != null &&
        currentStroke!.points.isNotEmpty &&
        (document.activeLayer?.isVisible ?? true)) {
      final activeLayer = document.activeLayer;
      final isAlphaLocked = activeLayer?.isAlphaLocked ?? false;

      if (isAlphaLocked) {
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, document.width.toDouble(), document.height.toDouble()),
          Paint()..blendMode = BlendMode.srcATop,
        );
      }

      _renderCurrentStroke(canvas);

      if (isAlphaLocked) {
        canvas.restore();
      }
    }

    // ── Guides Overlay (Isometric, Perspective, or Cartesian) ────
    if (!isThumbnail) {
      if (drawingGuide.isEnabled) {
        _drawDrawingGuides(canvas, size);
      } else if (showGrid) {
        _drawGrid(canvas, size);
      }

      // ── Symmetry Guides Overlay ─────────────────────────────────
      if (symmetryConfig.isEnabled && symmetryConfig.showGuides) {
        _drawSymmetryGuides(canvas);
      }
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      0,
      document.width.toDouble(),
      document.height.toDouble(),
    );

    // Canvas page drop shadow for paper elevation (skipped for thumbnails/exports)
    if (!isThumbnail) {
      canvas.drawRect(
        rect.shift(const Offset(0, 4)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    if (document.isTransparentBackground) {
      _drawCheckerboard(canvas, rect);
    } else {
      final bgColor = paperTexture != CanvasPaperTexture.none
          ? paperTexture.baseTint
          : document.backgroundColor;
      canvas.drawRect(
        rect,
        Paint()..color = bgColor,
      );
    }

    // Crisp 1px boundary line
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawPaperTexture(Canvas canvas, Size size) {
    final width = document.width.toDouble();
    final height = document.height.toDouble();
    final rect = Rect.fromLTWH(0, 0, width, height);

    switch (paperTexture) {
      case CanvasPaperTexture.none:
        break;

      case CanvasPaperTexture.watercolor:
        // Cold-press tooth: subtle warm grain & organic micro fibers
        final grainPaint = Paint()
          ..color = const Color(0xFF8B7355).withValues(alpha: 0.04)
          ..strokeWidth = 1.0;
        const step = 8.0;
        for (double y = 4; y < height; y += step) {
          for (double x = 4; x < width; x += step) {
            // Pseudo-random deterministic hash
            final pseudo = sin(x * 12.9898 + y * 78.233) * 43758.5453;
            final frac = pseudo - pseudo.floor();
            if (frac > 0.45) {
              canvas.drawCircle(Offset(x, y), frac * 1.5, grainPaint);
            }
          }
        }
        break;

      case CanvasPaperTexture.parchment:
        // Antiqued vintage vignette
        final vignettePaint = Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [
              Colors.transparent,
              const Color(0xFF8B5A2B).withValues(alpha: 0.06),
              const Color(0xFF5C3A21).withValues(alpha: 0.16),
            ],
            stops: const [0.4, 0.8, 1.0],
          ).createShader(rect);
        canvas.drawRect(rect, vignettePaint);
        break;

      case CanvasPaperTexture.blueprint:
        // Engineering blueprint grid
        final fineGridPaint = Paint()
          ..color = const Color(0xFF64B5F6).withValues(alpha: 0.18)
          ..strokeWidth = 0.5;
        final majorGridPaint = Paint()
          ..color = const Color(0xFFE3F2FD).withValues(alpha: 0.35)
          ..strokeWidth = 1.0;

        for (double x = 0; x <= width; x += 16) {
          final isMajor = (x % 64) == 0;
          canvas.drawLine(
            Offset(x, 0),
            Offset(x, height),
            isMajor ? majorGridPaint : fineGridPaint,
          );
        }
        for (double y = 0; y <= height; y += 16) {
          final isMajor = (y % 64) == 0;
          canvas.drawLine(
            Offset(0, y),
            Offset(width, y),
            isMajor ? majorGridPaint : fineGridPaint,
          );
        }
        break;

      case CanvasPaperTexture.darkSketchbook:
        // Charcoal stippling & slate vignette
        final darkVignette = Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 0.9,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.25),
            ],
          ).createShader(rect);
        canvas.drawRect(rect, darkVignette);

        final fleckPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.03)
          ..strokeWidth = 1.0;
        const fleckStep = 12.0;
        for (double y = 6; y < height; y += fleckStep) {
          for (double x = 6; x < width; x += fleckStep) {
            final pseudo = sin(x * 93.9898 + y * 67.233) * 23758.5453;
            if ((pseudo - pseudo.floor()) > 0.6) {
              canvas.drawCircle(Offset(x, y), 0.75, fleckPaint);
            }
          }
        }
        break;
    }
  }

  void _drawCheckerboard(Canvas canvas, Rect rect) {
    const checkSize = 16.0;
    final paint1 = Paint()..color = AppTheme.canvasCheckLight;
    final paint2 = Paint()..color = AppTheme.canvasCheckDark;

    for (double y = rect.top; y < rect.bottom; y += checkSize) {
      for (double x = rect.left; x < rect.right; x += checkSize) {
        final isEven =
            ((x / checkSize).floor() + (y / checkSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkSize, checkSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  void _drawLayer(Canvas canvas, LayerModel layer) {
    canvas.saveLayer(
      Rect.fromLTWH(
        0,
        0,
        document.width.toDouble(),
        document.height.toDouble(),
      ),
      Paint()
        ..colorFilter = null
        ..color = Colors.white.withValues(alpha: layer.opacity.clamp(0.0, 1.0))
        ..blendMode = layer.isClipping
            ? BlendMode.srcATop
            : layer.blendMode.toFlutterBlendMode(),
    );

    final isActiveLayer = layer.id == document.activeLayer?.id;
    final hasActiveStroke = isActiveLayer && currentStroke != null && currentStroke!.points.isNotEmpty;

    if (layer.isAlphaLocked && layer.strokes.isNotEmpty) {
      // First stroke defines base alpha mask
      StrokeRenderer.renderStroke(canvas, layer.strokes.first, layerOpacity: 1.0);
      // Subsequent strokes composite strictly over existing non-transparent pixels
      for (int i = 1; i < layer.strokes.length; i++) {
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, document.width.toDouble(), document.height.toDouble()),
          Paint()..blendMode = BlendMode.srcATop,
        );
        StrokeRenderer.renderStroke(canvas, layer.strokes[i], layerOpacity: 1.0);
        canvas.restore();
      }
      if (hasActiveStroke) {
        canvas.saveLayer(
          Rect.fromLTWH(0, 0, document.width.toDouble(), document.height.toDouble()),
          Paint()..blendMode = BlendMode.srcATop,
        );
        _renderCurrentStroke(canvas);
        canvas.restore();
      }
    } else {
      for (final stroke in layer.strokes) {
        StrokeRenderer.renderStroke(canvas, stroke, layerOpacity: 1.0);
      }
      if (hasActiveStroke) {
        _renderCurrentStroke(canvas);
      }
    }

    canvas.restore();
  }

  void _renderCurrentStroke(Canvas canvas) {
    if (currentStroke == null || currentStroke!.points.isEmpty) return;
    if (symmetryConfig.isEnabled) {
      final symmetricStrokes = symmetryConfig.generateSymmetricStrokes(
        currentStroke!,
        document.width.toDouble(),
        document.height.toDouble(),
      );
      for (final symStroke in symmetricStrokes) {
        StrokeRenderer.renderStroke(canvas, symStroke, layerOpacity: 1.0);
      }
    } else {
      StrokeRenderer.renderStroke(canvas, currentStroke!, layerOpacity: 1.0);
    }
  }

  void _drawDrawingGuides(Canvas canvas, Size size) {
    final width = document.width.toDouble();
    final height = document.height.toDouble();
    final paint = Paint()
      ..color = drawingGuide.color.withValues(alpha: drawingGuide.opacity)
      ..strokeWidth = 1.0;

    switch (drawingGuide.type) {
      case DrawingGuideType.none:
        break;

      case DrawingGuideType.grid2D:
        final step = drawingGuide.spacing.clamp(8.0, 256.0);
        for (double x = 0; x <= width; x += step) {
          canvas.drawLine(Offset(x, 0), Offset(x, height), paint);
        }
        for (double y = 0; y <= height; y += step) {
          canvas.drawLine(Offset(0, y), Offset(width, y), paint);
        }
        break;

      case DrawingGuideType.isometric:
        // Isometric 30-degree grid: vertical lines + 30-degree diagonal lines
        final s = drawingGuide.spacing.clamp(16.0, 128.0);
        final dx = s * cos(pi / 6); // ~0.866 * s
        final dy = s * sin(pi / 6); // 0.5 * s

        // Vertical lines
        for (double x = 0; x <= width; x += dx) {
          canvas.drawLine(Offset(x, 0), Offset(x, height), paint);
        }

        // Positive diagonals (/ 30 deg from horizontal)
        final totalDiag = (height / dy) + (width / dx);
        for (double i = -totalDiag; i <= totalDiag; i++) {
          final startY = i * dy;
          canvas.drawLine(
            Offset(0, startY),
            Offset(width, startY + (width / dx) * dy),
            paint,
          );
        }

        // Negative diagonals (\ 30 deg from horizontal)
        for (double i = -totalDiag; i <= totalDiag; i++) {
          final startY = i * dy;
          canvas.drawLine(
            Offset(0, startY),
            Offset(width, startY - (width / dx) * dy),
            paint,
          );
        }
        break;

      case DrawingGuideType.perspective1P:
        final horizonY = height * drawingGuide.horizonRatio;
        final vp = Offset(width * drawingGuide.vp1Ratio, horizonY);

        // Horizon line (bolder)
        final horizonPaint = Paint()
          ..color = drawingGuide.color.withValues(alpha: (drawingGuide.opacity * 1.6).clamp(0.0, 1.0))
          ..strokeWidth = 1.8;
        canvas.drawLine(Offset(0, horizonY), Offset(width, horizonY), horizonPaint);

        // Radiating rays to canvas perimeter
        final rayCount = drawingGuide.rayCount;
        for (int i = 0; i <= rayCount; i++) {
          final x = (width / rayCount) * i;
          canvas.drawLine(vp, Offset(x, 0), paint);
          canvas.drawLine(vp, Offset(x, height), paint);
        }
        for (int i = 0; i <= (rayCount ~/ 2); i++) {
          final y = (height / (rayCount ~/ 2)) * i;
          canvas.drawLine(vp, Offset(0, y), paint);
          canvas.drawLine(vp, Offset(width, y), paint);
        }

        // Center vanishing point node
        canvas.drawCircle(vp, 4.0, horizonPaint);
        break;

      case DrawingGuideType.perspective2P:
        final horizonY = height * drawingGuide.horizonRatio;
        final vp1 = Offset(width * drawingGuide.vp1Ratio, horizonY);
        final vp2 = Offset(width * drawingGuide.vp2Ratio, horizonY);

        // Horizon line
        final horizonPaint = Paint()
          ..color = drawingGuide.color.withValues(alpha: (drawingGuide.opacity * 1.6).clamp(0.0, 1.0))
          ..strokeWidth = 1.8;
        canvas.drawLine(Offset(0, horizonY), Offset(width, horizonY), horizonPaint);

        // Converging rays from VP1 and VP2 across bottom half and top half
        final rayCount = drawingGuide.rayCount;
        for (int i = 0; i <= rayCount; i++) {
          final x = (width / rayCount) * i;
          canvas.drawLine(vp1, Offset(x, height), paint);
          canvas.drawLine(vp2, Offset(x, height), paint);
          canvas.drawLine(vp1, Offset(x, 0), paint);
          canvas.drawLine(vp2, Offset(x, 0), paint);
        }

        // Vanishing point nodes
        canvas.drawCircle(vp1, 4.0, horizonPaint);
        canvas.drawCircle(vp2, 4.0, horizonPaint);
        break;

      case DrawingGuideType.perspective3P:
        final horizonY = height * drawingGuide.horizonRatio;
        final vp1 = Offset(width * drawingGuide.vp1Ratio, horizonY);
        final vp2 = Offset(width * drawingGuide.vp2Ratio, horizonY);
        final vp3 = Offset(width * 0.5, height * drawingGuide.vp3Ratio);

        // Horizon line
        final horizonPaint = Paint()
          ..color = drawingGuide.color.withValues(alpha: (drawingGuide.opacity * 1.6).clamp(0.0, 1.0))
          ..strokeWidth = 1.8;
        canvas.drawLine(Offset(0, horizonY), Offset(width, horizonY), horizonPaint);

        final rayCount = drawingGuide.rayCount;
        for (int i = 0; i <= rayCount; i++) {
          final x = (width / rayCount) * i;
          canvas.drawLine(vp1, Offset(x, height), paint);
          canvas.drawLine(vp2, Offset(x, height), paint);
          canvas.drawLine(vp1, Offset(x, 0), paint);
          canvas.drawLine(vp2, Offset(x, 0), paint);
          // Vertical perspective rays from VP3
          canvas.drawLine(vp3, Offset(x, height), paint);
        }

        // Vanishing point nodes
        canvas.drawCircle(vp1, 4.0, horizonPaint);
        canvas.drawCircle(vp2, 4.0, horizonPaint);
        canvas.drawCircle(vp3, 4.0, horizonPaint);
        break;

      case DrawingGuideType.ruleOfThirds:
        _drawRuleOfThirdsGuide(canvas, width, height, paint);
        break;

      case DrawingGuideType.thumbnailSafeZone:
        _drawThumbnailSafeZoneGuide(canvas, width, height, paint);
        break;
    }
  }

  void _drawOnionSkin(Canvas canvas, LayerModel layer, Color tintColor) {
    canvas.saveLayer(
      Rect.fromLTWH(
        0,
        0,
        document.width.toDouble(),
        document.height.toDouble(),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..blendMode = BlendMode.srcOver,
    );
    for (final stroke in layer.strokes) {
      final tintedStroke = stroke.copyWith(
        color: tintColor,
      );
      StrokeRenderer.renderStroke(canvas, tintedStroke, layerOpacity: 0.35);
    }
    canvas.restore();
  }

  void _drawRuleOfThirdsGuide(Canvas canvas, double width, double height, Paint basePaint) {
    final linePaint = Paint()
      ..color = drawingGuide.color.withValues(alpha: drawingGuide.opacity.clamp(0.1, 0.9))
      ..strokeWidth = 1.4;

    final x1 = width / 3.0;
    final x2 = (2.0 * width) / 3.0;
    final y1 = height / 3.0;
    final y2 = (2.0 * height) / 3.0;

    // Vertical lines
    canvas.drawLine(Offset(x1, 0), Offset(x1, height), linePaint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, height), linePaint);

    // Horizontal lines
    canvas.drawLine(Offset(0, y1), Offset(width, y1), linePaint);
    canvas.drawLine(Offset(0, y2), Offset(width, y2), linePaint);

    // 4 intersection power points
    final dotPaint = Paint()
      ..color = drawingGuide.color.withValues(alpha: (drawingGuide.opacity * 1.5).clamp(0.2, 1.0))
      ..style = PaintingStyle.fill;
    const dotRadius = 4.0;
    canvas.drawCircle(Offset(x1, y1), dotRadius, dotPaint);
    canvas.drawCircle(Offset(x2, y1), dotRadius, dotPaint);
    canvas.drawCircle(Offset(x1, y2), dotRadius, dotPaint);
    canvas.drawCircle(Offset(x2, y2), dotRadius, dotPaint);
  }

  void _drawThumbnailSafeZoneGuide(Canvas canvas, double width, double height, Paint basePaint) {
    // 1. Subtle Rule of Thirds in the background
    final subtleThirdsPaint = Paint()
      ..color = drawingGuide.color.withValues(alpha: (drawingGuide.opacity * 0.4).clamp(0.08, 0.5))
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(width / 3.0, 0), Offset(width / 3.0, height), subtleThirdsPaint);
    canvas.drawLine(Offset((2.0 * width) / 3.0, 0), Offset((2.0 * width) / 3.0, height), subtleThirdsPaint);
    canvas.drawLine(Offset(0, height / 3.0), Offset(width, height / 3.0), subtleThirdsPaint);
    canvas.drawLine(Offset(0, (2.0 * height) / 3.0), Offset(width, (2.0 * height) / 3.0), subtleThirdsPaint);

    // 2. Safe Edge Margins (5% inset from all edges)
    final marginX = width * 0.05;
    final marginY = height * 0.05;
    final safeMarginRect = Rect.fromLTRB(marginX, marginY, width - marginX, height - marginY);

    final safeMarginPaint = Paint()
      ..color = const Color(0xFF00CEC9).withValues(alpha: (drawingGuide.opacity * 1.2).clamp(0.25, 0.95))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(safeMarginRect, const Radius.circular(8)), safeMarginPaint);

    // 3. Center Crosshair for Subject Alignment
    final centerCrossPaint = Paint()
      ..color = drawingGuide.color.withValues(alpha: (drawingGuide.opacity * 0.7).clamp(0.2, 0.8))
      ..strokeWidth = 1.0;
    const crossSize = 14.0;
    final cx = width / 2.0;
    final cy = height / 2.0;
    canvas.drawLine(Offset(cx - crossSize, cy), Offset(cx + crossSize, cy), centerCrossPaint);
    canvas.drawLine(Offset(cx, cy - crossSize), Offset(cx, cy + crossSize), centerCrossPaint);

    // 4. YouTube Duration Timestamp Safe Zone (Bottom-Right overlay)
    final badgeW = width * 0.22;
    final badgeH = height * 0.17;
    final badgeR = Rect.fromLTWH(width - badgeW - marginX * 0.6, height - badgeH - marginY * 0.6, badgeW, badgeH);

    final badgeFill = Paint()
      ..color = const Color(0xFFD63031).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final badgeStroke = Paint()
      ..color = const Color(0xFFFF7675)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final badgeRRect = RRect.fromRectAndRadius(badgeR, const Radius.circular(6));
    canvas.drawRRect(badgeRRect, badgeFill);
    canvas.drawRRect(badgeRRect, badgeStroke);

    // Badge Warning Label
    final tpBadge = TextPainter(
      text: const TextSpan(
        text: '12:45\nSAFE ZONE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.15,
          letterSpacing: 0.5,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tpBadge.layout(maxWidth: badgeW);
    final badgeTextOffset = Offset(
      badgeR.center.dx - (tpBadge.width / 2),
      badgeR.center.dy - (tpBadge.height / 2),
    );
    tpBadge.paint(canvas, badgeTextOffset);
    tpBadge.dispose();
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.3)
          ..strokeWidth = 0.5;

    for (double x = 0; x <= document.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, document.height.toDouble()),
        paint,
      );
    }
    for (double y = 0; y <= document.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(document.width.toDouble(), y),
        paint,
      );
    }
  }

  void _drawSymmetryGuides(Canvas canvas) {
    final width = document.width.toDouble();
    final height = document.height.toDouble();
    final centerX = width / 2;
    final centerY = height / 2;
    final center = Offset(centerX, centerY);

    final guidePaint = Paint()
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final secondaryPaint = Paint()
      ..color = const Color(0xFFFF6B9D).withValues(alpha: 0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    switch (symmetryConfig.mode) {
      case SymmetryMode.off:
        return;

      case SymmetryMode.vertical:
        _drawDashedLine(canvas, Offset(centerX, 0), Offset(centerX, height), guidePaint);
        break;

      case SymmetryMode.horizontal:
        _drawDashedLine(canvas, Offset(0, centerY), Offset(width, centerY), guidePaint);
        break;

      case SymmetryMode.dual:
        _drawDashedLine(canvas, Offset(centerX, 0), Offset(centerX, height), guidePaint);
        _drawDashedLine(canvas, Offset(0, centerY), Offset(width, centerY), guidePaint);
        break;

      case SymmetryMode.radial:
        final maxRadius = sqrt(centerX * centerX + centerY * centerY);
        final angleStep = (2 * pi) / symmetryConfig.segments;

        // Concentric reference rings
        for (double r = 100; r < maxRadius; r += 100) {
          canvas.drawCircle(center, r, secondaryPaint);
        }

        // Radial rays
        for (int i = 0; i < symmetryConfig.segments; i++) {
          final theta = i * angleStep;
          final end = Offset(
            centerX + maxRadius * cos(theta),
            centerY + maxRadius * sin(theta),
          );
          _drawDashedLine(canvas, center, end, i % 2 == 0 ? guidePaint : secondaryPaint);
        }
        break;
    }

    // Draw glowing center pivot indicator
    final glowPaint = Paint()
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final pivotPaint = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..style = PaintingStyle.fill;
    final innerDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8.0, glowPaint);
    canvas.drawCircle(center, 4.0, pivotPaint);
    canvas.drawCircle(center, 1.5, innerDot);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;

    double currentDist = 0;
    while (currentDist < distance) {
      final start = Offset(
        p1.dx + unitX * currentDist,
        p1.dy + unitY * currentDist,
      );
      final segmentLen = min(dashWidth, distance - currentDist);
      final end = Offset(
        p1.dx + unitX * (currentDist + segmentLen),
        p1.dy + unitY * (currentDist + segmentLen),
      );
      canvas.drawLine(start, end, paint);
      currentDist += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return document != oldDelegate.document ||
        currentStroke != oldDelegate.currentStroke ||
        showGrid != oldDelegate.showGrid ||
        symmetryConfig != oldDelegate.symmetryConfig ||
        paperTexture != oldDelegate.paperTexture;
  }
}
