import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/canvas_document.dart';
import '../models/drawing_guides.dart';
import '../models/stroke.dart';
import '../models/tools.dart';
import '../providers/canvas_providers.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../rendering/engine/flood_fill_service.dart';
import '../../../rendering/engine/stroke_renderer.dart';
import '../../../rendering/engine/quick_shape_recognizer.dart';
import '../../settings/providers/settings_providers.dart';
import '../../text/views/font_picker_dialog.dart';
import 'canvas_painter.dart';

/// The interactive canvas widget that handles gesture input, stylus pressure,
/// palm rejection, real-time symmetry, shapes, bucket fill, eyedropper, and audio SFX.
class CanvasWidget extends ConsumerStatefulWidget {
  const CanvasWidget({super.key});

  @override
  ConsumerState<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends ConsumerState<CanvasWidget> {
  // Track active stroke points for stabilization
  final List<StrokePoint> _strokeHistory = [];
  bool _isDrawing = false;
  int _pointerCount = 0;

  // QuickShape (Draw & Hold) state
  Timer? _quickShapeTimer;
  bool _isQuickShapeSnapped = false;
  Offset? _lastPointerMovePos;

  // Multi-touch tap gesture tracking (two-finger undo, three-finger redo)
  int _maxPointersInGesture = 0;
  DateTime? _firstPointerDownTime;
  Offset? _pointerInitialPos;
  bool _movedSignificantly = false;

  // Stylus pressure and palm rejection tracking
  double _lastPointerPressure = 1.0;
  bool _stylusActive = false;

  // Multi-touch 2-finger zoom and pan state
  bool _isZooming = false;
  double _baseGestureScale = 1.0;
  double _startZoom = 1.0;
  double _startRotation = 0.0;

  // Auto-fit tracking
  String? _lastFittedDocId;
  double _lastViewportWidth = 0.0;
  double _lastViewportHeight = 0.0;
  double _activePanX = 0.0;
  double _activePanY = 0.0;
  double _activeZoom = 1.0;
  Offset? _selectionStartPoint;
  Offset? _transformStartPoint;
  List<Stroke> _transformInitialStrokes = [];
  bool _transformDidMove = false;

  // Zero-latency tap and double-tap zoom tracking
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;

  // Element direct manipulation (drag any element: text, shape, or stroke)
  Stroke? _movingElementStroke;
  Offset? _elementMoveLastPoint;
  List<Stroke> _preMoveStrokes = [];

  /// Detects whether user touched directly on an existing element (text, shape, stroke).
  Stroke? _findHitStroke(Offset point, List<Stroke> strokes) {
    for (int i = strokes.length - 1; i >= 0; i--) {
      final s = strokes[i];
      if (s.points.isEmpty) continue;

      if (s.shapeType == ShapeType.text) {
        final text = s.text ?? '';
        final fontSize = s.fontSize ?? 24.0;
        final estimatedWidth = max(text.length * fontSize * 0.75, 48.0);
        final estimatedHeight = max(fontSize * 1.4, 32.0);
        final start = s.points.first;
        // Text is rendered from (start.x, start.y) downwards to (start.x + w, start.y + h)
        final rect = Rect.fromLTWH(
          start.x - 16,
          start.y - 12,
          estimatedWidth + 32,
          estimatedHeight + 24,
        );
        if (rect.contains(point)) return s;
      } else if (s.shapeType != ShapeType.none && s.points.length >= 2) {
        final p1 = s.points.first;
        final p2 = s.points.last;
        final rect = Rect.fromPoints(Offset(p1.x, p1.y), Offset(p2.x, p2.y))
            .inflate(max(s.brush.size / 2 + 18.0, 26.0));
        if (rect.contains(point)) return s;
      } else {
        // Freehand stroke: check proximity to points
        final hitRadius = max(s.brush.size / 2 + 18.0, 24.0);
        for (final pt in s.points) {
          if ((Offset(pt.x, pt.y) - point).distance <= hitRadius) {
            return s;
          }
        }
      }
    }
    return null;
  }

  @override
  void dispose() {
    _quickShapeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final document = ref.watch(canvasDocumentProvider);
    final currentStroke = ref.watch(currentStrokeProvider);
    final viewState = ref.watch(canvasViewProvider);
    final symmetryConfig = ref.watch(symmetryProvider);
    final paperTexture = ref.watch(paperTextureProvider);
    final eyedropperPos = ref.watch(eyedropperPositionProvider);
    final eyedropperColor = ref.watch(eyedropperColorProvider);
    final showGrid = ref.watch(showGridProvider);
    final gridSize = ref.watch(gridSizeProvider);
    final drawingGuide = ref.watch(drawingGuideProvider);
    final gestureSettings = ref.watch(gestureSettingsProvider);
    final selectionRect = ref.watch(activeSelectionRectProvider);
    final activeTool = ref.watch(activeToolProvider);

    return Container(
      color: isDark ? const Color(0xFF161622) : const Color(0xFFEBEBF0),
      child: Stack(
      children: [
        Listener(
          onPointerDown: (event) {
            _pointerCount++;
            if (_pointerCount == 1) {
              _maxPointersInGesture = 1;
              _firstPointerDownTime = DateTime.now();
              _pointerInitialPos = event.position;
              _movedSignificantly = false;
            } else if (_pointerCount > _maxPointersInGesture) {
              _maxPointersInGesture = _pointerCount;
            }

            // Stylus detection
            if (event.kind == PointerDeviceKind.stylus ||
                event.kind == PointerDeviceKind.invertedStylus) {
              _stylusActive = true;
            }

            // Palm rejection: If stylus is active, ignore finger touches
            if (_stylusActive && event.kind == PointerDeviceKind.touch) {
              return;
            }

            // Stylus-only drawing mode
            if (gestureSettings.stylusOnlyDrawing &&
                event.kind == PointerDeviceKind.touch) {
              return;
            }

            // Extract hardware stylus pressure if available (> 0.0)
            if (event.pressure > 0.0) {
              _lastPointerPressure = event.pressure;
            } else {
              _lastPointerPressure = 1.0;
            }
          },
          onPointerMove: (event) {
            if (event.kind == PointerDeviceKind.stylus ||
                event.kind == PointerDeviceKind.invertedStylus) {
              _stylusActive = true;
            }

            if (_pointerInitialPos != null &&
                (event.position - _pointerInitialPos!).distance > 18.0) {
              _movedSignificantly = true;
            }

            if (event.pressure > 0.0) {
              _lastPointerPressure = event.pressure;
            }
          },
          onPointerUp: (event) {
            _pointerCount--;
            if (_pointerCount <= 0) {
              _pointerCount = 0;
              _stylusActive = false;

              // Check for 2-finger (Undo) or 3-finger (Redo) quick tap
              if (_firstPointerDownTime != null && !_movedSignificantly) {
                final elapsed =
                    DateTime.now().difference(_firstPointerDownTime!).inMilliseconds;
                if (elapsed < 350) {
                  if (_maxPointersInGesture == 2 &&
                      gestureSettings.twoFingerTapUndo) {
                    ref.read(undoRedoProvider.notifier).undo();
                    SoundEffectService.instance.playPop();
                  } else if (_maxPointersInGesture == 3 &&
                      gestureSettings.threeFingerTapRedo) {
                    ref.read(undoRedoProvider.notifier).redo();
                    SoundEffectService.instance.playPop();
                  }
                } else if (_maxPointersInGesture == 1) {
                  // Single tap - check for double-tap zoom (zero-latency gesture arena)
                  final now = DateTime.now();
                  if (_lastTapTime != null &&
                      now.difference(_lastTapTime!).inMilliseconds < 280 &&
                      _lastTapPosition != null &&
                      (event.position - _lastTapPosition!).distance < 36.0) {
                    _onDoubleTapZoom();
                    _lastTapTime = null;
                    _lastTapPosition = null;
                  } else {
                    _lastTapTime = now;
                    _lastTapPosition = event.position;
                  }
                }
              }
              _maxPointersInGesture = 0;
              _firstPointerDownTime = null;
              _pointerInitialPos = null;
            }
          },
          onPointerCancel: (_) {
            _pointerCount = 0;
            _stylusActive = false;
            _maxPointersInGesture = 0;
            _firstPointerDownTime = null;
            _pointerInitialPos = null;
          },
            child: ClipRect(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final availableHeight = constraints.maxHeight;

                    var currentPanX = viewState.panX;
                    var currentPanY = viewState.panY;
                    var currentZoom = viewState.zoom;

                    final requestedAutoFit = ref.watch(autoFitToScreenProvider);
                    final isNewDoc = _lastFittedDocId != document.id;

                    if (availableWidth > 0 &&
                        availableHeight > 0 &&
                        document.width > 0 &&
                        document.height > 0) {
                      _lastViewportWidth = availableWidth;
                      _lastViewportHeight = availableHeight;

                      if (requestedAutoFit || isNewDoc) {
                        _lastFittedDocId = document.id;

                        final scaleX = availableWidth / document.width;
                        final scaleY = availableHeight / document.height;
                        final fitZoom = ((scaleX < scaleY ? scaleX : scaleY) * 0.92)
                            .clamp(CanvasDefaults.minZoom, CanvasDefaults.maxZoom);
                        final fitPanX = (availableWidth - document.width * fitZoom) / 2;
                        final fitPanY = (availableHeight - document.height * fitZoom) / 2;

                        currentZoom = fitZoom;
                        currentPanX = fitPanX;
                        currentPanY = fitPanY;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            if (ref.read(autoFitToScreenProvider)) {
                              ref.read(autoFitToScreenProvider.notifier).state = false;
                            }
                            ref.read(canvasViewProvider.notifier).setViewport(
                              zoom: fitZoom,
                              panX: fitPanX,
                              panY: fitPanY,
                            );
                          }
                        });
                      }
                    }

                    _activePanX = currentPanX;
                    _activePanY = currentPanY;
                    _activeZoom = currentZoom;

                    return SizedBox.expand(
                      child: Transform(
                        transform: Matrix4.translationValues(
                          currentPanX,
                          currentPanY,
                          0.0,
                        )..scaleByDouble(currentZoom, currentZoom, 1.0, 1.0),
                        child: Stack(
                          children: [
                            RepaintBoundary(
                              child: CustomPaint(
                                painter: CanvasPainter(
                                  document: document,
                                  currentStroke: currentStroke,
                                  showGrid: showGrid,
                                  gridSize: gridSize,
                                  drawingGuide: drawingGuide,
                                  symmetryConfig: symmetryConfig,
                                  paperTexture: paperTexture,
                                  onionSkinEnabled: ref.watch(onionSkinEnabledProvider),
                                ),
                                size: Size(
                                  document.width.toDouble(),
                                  document.height.toDouble(),
                                ),
                              ),
                            ),
                            if (selectionRect != null)
                              CustomPaint(
                                painter: _SelectionMarqueePainter(rect: selectionRect),
                                size: Size(
                                  document.width.toDouble(),
                                  document.height.toDouble(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        // Text Selection & Swift/Move Controls Overlay
        if (activeTool == DrawingTool.text)
          _buildTextSelectionOverlay(context, viewState, document),

        // Eyedropper floating magnifier loupe
        if (eyedropperPos != null && eyedropperColor != null)
          Positioned(
            left: (eyedropperPos.dx - 36).clamp(10.0, MediaQuery.of(context).size.width - 82),
            top: (eyedropperPos.dy - 100).clamp(10.0, MediaQuery.of(context).size.height - 150),
            child: IgnorePointer(
              child: _EyedropperLoupe(color: eyedropperColor),
            ),
          ),
      ],
    ),
  );
}

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount > 1) {
      // Multi-touch: pan/zoom mode - immediately cancel drawing so no dots or lines are left
      _isZooming = true;
      _isDrawing = false;
      _baseGestureScale = 1.0;
      _startZoom = ref.read(canvasViewProvider).zoom;
      _startRotation = ref.read(canvasViewProvider).rotation;
      ref.read(currentStrokeProvider.notifier).state = null;
      _strokeHistory.clear();
      return;
    }
    _isZooming = false;

    final activeTool = ref.read(activeToolProvider);
    final viewState = ref.read(canvasViewProvider);
    final localPoint = _screenToCanvas(details.localFocalPoint, viewState);
    final doc = ref.read(canvasDocumentProvider);

    // Guard against modifying locked or hidden layers for drawing/transform tools
    final activeLayer = doc.activeLayer;
    if (activeTool != DrawingTool.eyedropper && activeTool != DrawingTool.selection) {
      if (activeLayer == null) return;
      if (activeLayer.isLocked) {
        HapticFeedback.lightImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Layer is locked. Unlock it in the Layers panel.'),
                ],
              ),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF1E1E2C),
            ),
          );
        }
        return;
      }
      if (!activeLayer.isVisible) {
        HapticFeedback.lightImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.visibility_off_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Layer is hidden. Make it visible in the Layers panel to draw.'),
                ],
              ),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF1E1E2C),
            ),
          );
        }
        return;
      }
    }

    // 1. Eyedropper mode: sample color under touch
    if (activeTool == DrawingTool.eyedropper) {
      final sampled = _sampleColorAt(doc, localPoint);
      ref.read(eyedropperColorProvider.notifier).state = sampled;
      ref.read(eyedropperPositionProvider.notifier).state = details.localFocalPoint;
      _isDrawing = true;
      SoundEffectService.instance.playPop();
      return;
    }

    // 2. Flood Fill mode: tap to fill bounded region
    if (activeTool == DrawingTool.fill) {
      SoundEffectService.instance.playBrush();
      _performFloodFill(localPoint);
      return;
    }

    final brush = ref.read(activeBrushProvider);
    final color = ref.read(activeColorProvider);

    // Double-tap tracking for quick editing
    final now = DateTime.now();
    final isDoubleTap = _lastTapPosition != null &&
        (localPoint - _lastTapPosition!).distance < 36.0 &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 320);
    _lastTapTime = now;
    _lastTapPosition = localPoint;

    // 3. Text mode: select, move, edit, or prompt to add text (Never stamp automatically!)
    if (activeTool == DrawingTool.text) {
      final doc = ref.read(canvasDocumentProvider);
      final activeLayer = doc.activeLayer;
      if (activeLayer != null) {
        final hit = _findHitStroke(localPoint, activeLayer.strokes);
        if (hit != null && hit.shapeType == ShapeType.text) {
          ref.read(selectedTextStrokeIdProvider.notifier).state = hit.id;
          if (isDoubleTap) {
            _editExistingText(hit);
            return;
          }
          // Direct element move / swift
          _movingElementStroke = hit;
          _elementMoveLastPoint = localPoint;
          _preMoveStrokes = List<Stroke>.from(activeLayer.strokes);
          _isDrawing = true;
          SoundEffectService.instance.playPop();
          HapticFeedback.lightImpact();
          return;
        }
      }

      // If user tapped on empty canvas while a text was selected:
      final currentlySelectedId = ref.read(selectedTextStrokeIdProvider);
      if (currentlySelectedId != null) {
        // Deselect the text! DO NOT STAMP!
        ref.read(selectedTextStrokeIdProvider.notifier).state = null;
        SoundEffectService.instance.playPop();
        HapticFeedback.selectionClick();
        return;
      }

      // If user tapped empty canvas with no text selected:
      // Open add text dialog at this position instead of automatically stamping!
      _promptAddTextAt(localPoint);
      return;
    }

    // 4. Shape mode: if user tapped on existing shape, move it! Otherwise draw new shape
    if (activeTool == DrawingTool.shape) {
      final doc = ref.read(canvasDocumentProvider);
      final activeLayer = doc.activeLayer;
      if (activeLayer != null) {
        final hit = _findHitStroke(localPoint, activeLayer.strokes);
        if (hit != null && hit.shapeType != ShapeType.none && hit.shapeType != ShapeType.text) {
          _movingElementStroke = hit;
          _elementMoveLastPoint = localPoint;
          _preMoveStrokes = List<Stroke>.from(activeLayer.strokes);
          _isDrawing = true;
          SoundEffectService.instance.playPop();
          HapticFeedback.lightImpact();
          return;
        }
      }

      SoundEffectService.instance.playPencil();
      final shapeType = ref.read(activeShapeProvider);
      final isFilled = ref.read(isShapeFilledProvider);
      final startPt = StrokePoint(
        x: localPoint.dx,
        y: localPoint.dy,
        pressure: 1.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      _strokeHistory.clear();
      _strokeHistory.add(startPt);
      _isDrawing = true;

      ref.read(currentStrokeProvider.notifier).state = Stroke(
        points: [startPt, startPt],
        color: color,
        brush: brush,
        shapeType: shapeType,
        isFilled: isFilled,
      );
      return;
    }

    // 5. Ruler mode: initialize straight line / angle snapped preview
    if (activeTool == DrawingTool.ruler) {
      SoundEffectService.instance.playPencil();
      final startPt = StrokePoint(
        x: localPoint.dx,
        y: localPoint.dy,
        pressure: 1.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      _strokeHistory.clear();
      _strokeHistory.add(startPt);
      _isDrawing = true;

      ref.read(currentStrokeProvider.notifier).state = Stroke(
        points: [startPt, startPt],
        color: color,
        brush: brush,
        shapeType: ShapeType.line,
      );
      return;
    }

    // 6. Gradient mode: initialize 2-stop gradient drag preview
    if (activeTool == DrawingTool.gradient) {
      SoundEffectService.instance.playPop();
      final gType = ref.read(gradientTypeProvider);
      final secColor = ref.read(gradientSecondaryColorProvider);
      final startPt = StrokePoint(
        x: localPoint.dx,
        y: localPoint.dy,
        pressure: 1.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      _strokeHistory.clear();
      _strokeHistory.add(startPt);
      _isDrawing = true;

      ref.read(currentStrokeProvider.notifier).state = Stroke(
        points: [startPt, startPt],
        color: color,
        brush: brush,
        shapeType: ShapeType.gradientFill,
        gradientType: gType,
        secondaryColor: secColor,
      );
      return;
    }

    // 7. Selection mode: drag bounding marquee box
    if (activeTool == DrawingTool.selection) {
      SoundEffectService.instance.playPop();
      _selectionStartPoint = localPoint;
      ref.read(activeSelectionRectProvider.notifier).state =
          Rect.fromPoints(localPoint, localPoint);
      _isDrawing = true;
      return;
    }

    // 8. Transform mode: drag to translate specific element OR active layer
    if (activeTool == DrawingTool.transform) {
      _transformStartPoint = localPoint;
      _transformDidMove = false;
      final doc = ref.read(canvasDocumentProvider);
      final activeLayer = doc.activeLayer;
      if (activeLayer != null) {
        _transformInitialStrokes = List<Stroke>.from(activeLayer.strokes);
        _movingElementStroke = _findHitStroke(localPoint, activeLayer.strokes);
        if (_movingElementStroke != null) {
          _elementMoveLastPoint = localPoint;
          _preMoveStrokes = List<Stroke>.from(activeLayer.strokes);
          SoundEffectService.instance.playPop();
          HapticFeedback.lightImpact();
        }
      } else {
        _transformInitialStrokes = [];
      }
      _isDrawing = true;
      return;
    }

    // 9. Freehand drawing tools: Brush, Pencil, Pen, Marker, Highlighter, Rainbow, Eraser, etc.
    if (activeTool == DrawingTool.eraser || brush.isEraser) {
      SoundEffectService.instance.playEraser();
    } else if (activeTool == DrawingTool.pencil || brush.category == BrushCategory.sketching) {
      SoundEffectService.instance.playPencil();
    } else {
      SoundEffectService.instance.playBrush();
    }

    final effectiveBrush = switch (activeTool) {
      DrawingTool.eraser => brush.copyWith(isEraser: true),
      DrawingTool.highlighter => brush.copyWith(isHighlighter: true),
      DrawingTool.rainbow => brush.copyWith(isRainbow: true),
      DrawingTool.smudge => brush.copyWith(isSmudge: true, isBlur: false),
      DrawingTool.blur => brush.copyWith(isBlur: true, isSmudge: false),
      _ => brush,
    };

    final effectiveBlendMode = activeTool == DrawingTool.highlighter
        ? DrawBlendMode.multiply
        : DrawBlendMode.normal;

    final stampType = activeTool == DrawingTool.patternStamp
        ? ref.read(patternStampTypeProvider)
        : null;

    final rainbowMode = activeTool == DrawingTool.rainbow
        ? ref.read(rainbowModeProvider)
        : null;

    final point = StrokePoint(
      x: localPoint.dx,
      y: localPoint.dy,
      pressure: _lastPointerPressure.clamp(0.15, 2.0),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _strokeHistory.clear();
    _strokeHistory.add(point);
    _isDrawing = true;
    _isQuickShapeSnapped = false;
    _lastPointerMovePos = details.localFocalPoint;
    _startQuickShapeTimer();

    ref.read(currentStrokeProvider.notifier).state = Stroke(
      points: [point],
      color: color,
      brush: effectiveBrush,
      blendMode: effectiveBlendMode,
      stampType: stampType,
      rainbowMode: rainbowMode,
    );
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount > 1 || _isZooming) {
      if (!_isZooming) {
        _isZooming = true;
        _isDrawing = false;
        _baseGestureScale = details.scale;
        _startZoom = ref.read(canvasViewProvider).zoom;
        _startRotation = ref.read(canvasViewProvider).rotation;
        ref.read(currentStrokeProvider.notifier).state = null;
        _strokeHistory.clear();
      }

      final double scaleRatio = details.scale / (_baseGestureScale > 0 ? _baseGestureScale : 1.0);
      final double newScale = _startZoom * scaleRatio;
      final gestureSettings = ref.read(gestureSettingsProvider);
      final double? newRotation = gestureSettings.allowCanvasRotation
          ? _startRotation + details.rotation
          : null;

      ref.read(canvasViewProvider.notifier).applyPinchTransform(
        newScale: newScale,
        focalPoint: details.localFocalPoint,
        focalDelta: details.focalPointDelta,
        newRotation: newRotation,
      );
      return;
    }

    final activeTool = ref.read(activeToolProvider);
    final viewState = ref.read(canvasViewProvider);
    final localPoint = _screenToCanvas(details.localFocalPoint, viewState);

    // Eyedropper update: live color sampling
    if (activeTool == DrawingTool.eyedropper) {
      final doc = ref.read(canvasDocumentProvider);
      final sampled = _sampleColorAt(doc, localPoint);
      ref.read(eyedropperColorProvider.notifier).state = sampled;
      ref.read(eyedropperPositionProvider.notifier).state = details.localFocalPoint;
      return;
    }

    // Shape update: preview shape to current drag endpoint
    if (activeTool == DrawingTool.shape) {
      final currentStroke = ref.read(currentStrokeProvider);
      if (currentStroke != null && currentStroke.points.isNotEmpty) {
        final start = currentStroke.points.first;
        final end = StrokePoint(
          x: localPoint.dx,
          y: localPoint.dy,
          pressure: 1.0,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        ref.read(currentStrokeProvider.notifier).state = currentStroke.copyWith(
          points: [start, end],
        );
      }
      return;
    }

    // Ruler update: snap line according to rulerGuideMode
    if (activeTool == DrawingTool.ruler) {
      final currentStroke = ref.read(currentStrokeProvider);
      if (currentStroke != null && currentStroke.points.isNotEmpty) {
        final start = currentStroke.points.first;
        final mode = ref.read(rulerGuideModeProvider);
        final snappedPoint = _snapToRuler(start.offset, localPoint, mode);
        final end = StrokePoint(
          x: snappedPoint.dx,
          y: snappedPoint.dy,
          pressure: 1.0,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        ref.read(currentStrokeProvider.notifier).state = currentStroke.copyWith(
          points: [start, end],
        );
      }
      return;
    }

    // Gradient update: preview gradient endpoint
    if (activeTool == DrawingTool.gradient) {
      final currentStroke = ref.read(currentStrokeProvider);
      if (currentStroke != null && currentStroke.points.isNotEmpty) {
        final start = currentStroke.points.first;
        final end = StrokePoint(
          x: localPoint.dx,
          y: localPoint.dy,
          pressure: 1.0,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        ref.read(currentStrokeProvider.notifier).state = currentStroke.copyWith(
          points: [start, end],
        );
      }
      return;
    }

    // Selection update: expand marquee box
    if (activeTool == DrawingTool.selection && _selectionStartPoint != null) {
      ref.read(activeSelectionRectProvider.notifier).state =
          Rect.fromPoints(_selectionStartPoint!, localPoint);
      return;
    }

    // Direct element move update (Text, Shape, or Stroke)
    if (_movingElementStroke != null && _elementMoveLastPoint != null) {
      final delta = localPoint - _elementMoveLastPoint!;
      _elementMoveLastPoint = localPoint;
      final doc = ref.read(canvasDocumentProvider);
      final activeLayer = doc.activeLayer;
      if (activeLayer != null) {
        final movingId = _movingElementStroke!.id;
        final updatedStrokes = activeLayer.strokes.map((s) {
          if (s.id == movingId) {
            final translatedPts = s.points
                .map((p) => p.copyWith(x: p.x + delta.dx, y: p.y + delta.dy))
                .toList();
            return s.copyWith(points: translatedPts);
          }
          return s;
        }).toList();
        ref.read(canvasDocumentProvider.notifier).updateActiveLayerStrokes(updatedStrokes);
      }
      return;
    }

    // Transform update: translate active layer
    if (activeTool == DrawingTool.transform && _transformStartPoint != null) {
      final delta = localPoint - _transformStartPoint!;
      _transformStartPoint = localPoint;
      if (delta.dx.abs() > 0.1 || delta.dy.abs() > 0.1) {
        _transformDidMove = true;
      }
      final doc = ref.read(canvasDocumentProvider);
      final activeLayer = doc.activeLayer;
      if (activeLayer != null && activeLayer.strokes.isNotEmpty) {
        final translatedStrokes = activeLayer.strokes.map((s) {
          final translatedPts = s.points.map((p) => p.copyWith(x: p.x + delta.dx, y: p.y + delta.dy)).toList();
          return s.copyWith(points: translatedPts);
        }).toList();
        ref.read(canvasDocumentProvider.notifier).updateActiveLayerStrokes(translatedStrokes);
      }
      return;
    }

    // If QuickShape is already snapped, user can dynamically drag to scale/orient the shape before releasing
    if (_isQuickShapeSnapped) {
      final currentStroke = ref.read(currentStrokeProvider);
      if (currentStroke != null && currentStroke.points.isNotEmpty) {
        final start = currentStroke.points.first;
        final end = StrokePoint(
          x: localPoint.dx,
          y: localPoint.dy,
          pressure: 1.0,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        ref.read(currentStrokeProvider.notifier).state = currentStroke.copyWith(
          points: [start, end],
        );
      }
      return;
    }

    _resetQuickShapeTimer(details.localFocalPoint);

    // Freehand stroke update
    final brush = ref.read(activeBrushProvider);

    var newPoint = StrokePoint(
      x: localPoint.dx,
      y: localPoint.dy,
      pressure: _lastPointerPressure.clamp(0.15, 2.0),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    // Apply stabilization and streamline rope
    final streamline = ref.read(streamlineLevelProvider);
    newPoint = StrokeRenderer.stabilize(
      newPoint,
      _strokeHistory,
      brush.stabilization,
      streamline: streamline > 0 ? streamline : brush.streamline,
    );

    // Apply perspective snapping if guide is enabled and snapToGuide is true
    final doc = ref.read(canvasDocumentProvider);
    final drawingGuide = ref.read(drawingGuideProvider);
    if (drawingGuide.isEnabled && drawingGuide.snapToGuide) {
      final snapped = _snapToPerspective(
        Offset(newPoint.x, newPoint.y),
        drawingGuide,
        doc.width.toDouble(),
        doc.height.toDouble(),
      );
      newPoint = newPoint.copyWith(x: snapped.dx, y: snapped.dy);
    }

    _strokeHistory.add(newPoint);

    final currentStroke = ref.read(currentStrokeProvider);
    if (currentStroke != null) {
      ref.read(currentStrokeProvider.notifier).state = currentStroke.copyWith(
        points: List<StrokePoint>.from(_strokeHistory),
      );
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _quickShapeTimer?.cancel();
    if (_isZooming) {
      _isZooming = false;
      return;
    }
    if (!_isDrawing) return;
    _isDrawing = false;

    // Direct element move commit (push undo action)
    if (_movingElementStroke != null) {
      final doc = ref.read(canvasDocumentProvider);
      final activeLayer = doc.activeLayer;
      if (activeLayer != null && _preMoveStrokes.isNotEmpty) {
        ref.read(undoRedoProvider.notifier).pushAction(
          LayerStrokesAction(
            documentNotifier: ref.read(canvasDocumentProvider.notifier),
            oldStrokes: _preMoveStrokes,
            newStrokes: List<Stroke>.from(activeLayer.strokes),
          ),
        );
        ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
      }
      _movingElementStroke = null;
      _elementMoveLastPoint = null;
      _preMoveStrokes = [];
      return;
    }

    final activeTool = ref.read(activeToolProvider);

    // Eyedropper commit: set active color
    if (activeTool == DrawingTool.eyedropper) {
      final sampled = ref.read(eyedropperColorProvider);
      if (sampled != null) {
        ref.read(activeColorProvider.notifier).setColor(sampled);
        SoundEffectService.instance.playPop();
      }
      ref.read(eyedropperColorProvider.notifier).state = null;
      ref.read(eyedropperPositionProvider.notifier).state = null;
      return;
    }

    // Shape commit
    if (activeTool == DrawingTool.shape) {
      final currentStroke = ref.read(currentStrokeProvider);
      if (currentStroke != null && currentStroke.points.length >= 2) {
        final doc = ref.read(canvasDocumentProvider);
        final symmetryConfig = ref.read(symmetryProvider);
        final docNotifier = ref.read(canvasDocumentProvider.notifier);
        final undoNotifier = ref.read(undoRedoProvider.notifier);

        if (symmetryConfig.isEnabled) {
          final symmetricStrokes = symmetryConfig.generateSymmetricStrokes(
            currentStroke,
            doc.width.toDouble(),
            doc.height.toDouble(),
          );
          for (final s in symmetricStrokes) {
            docNotifier.addStroke(s);
          }
          undoNotifier.pushAction(
            MultiStrokeAction(
              documentNotifier: docNotifier,
              strokes: symmetricStrokes,
            ),
          );
        } else {
          docNotifier.addStroke(currentStroke);
          undoNotifier.pushAction(
            StrokeAction(documentNotifier: docNotifier, stroke: currentStroke),
          );
        }
        SoundEffectService.instance.playPop();
        ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
      }
      ref.read(currentStrokeProvider.notifier).state = null;
      _strokeHistory.clear();
      return;
    }

    // Ruler commit: add the straight snapped stroke
    if (activeTool == DrawingTool.ruler) {
      final currentStroke = ref.read(currentStrokeProvider);
      if (currentStroke != null && currentStroke.points.length >= 2) {
        final doc = ref.read(canvasDocumentProvider);
        final symmetryConfig = ref.read(symmetryProvider);
        final docNotifier = ref.read(canvasDocumentProvider.notifier);
        final undoNotifier = ref.read(undoRedoProvider.notifier);

        if (symmetryConfig.isEnabled) {
          final symmetricStrokes = symmetryConfig.generateSymmetricStrokes(
            currentStroke,
            doc.width.toDouble(),
            doc.height.toDouble(),
          );
          for (final s in symmetricStrokes) {
            docNotifier.addStroke(s);
          }
          undoNotifier.pushAction(
            MultiStrokeAction(
              documentNotifier: docNotifier,
              strokes: symmetricStrokes,
            ),
          );
        } else {
          docNotifier.addStroke(currentStroke);
          undoNotifier.pushAction(
            StrokeAction(documentNotifier: docNotifier, stroke: currentStroke),
          );
        }
        SoundEffectService.instance.playPop();
        ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
      }
      ref.read(currentStrokeProvider.notifier).state = null;
      _strokeHistory.clear();
      return;
    }

    // Gradient commit
    if (activeTool == DrawingTool.gradient) {
      final currentStroke = ref.read(currentStrokeProvider);
      if (currentStroke != null && currentStroke.points.length >= 2) {
        final docNotifier = ref.read(canvasDocumentProvider.notifier);
        final undoNotifier = ref.read(undoRedoProvider.notifier);
        docNotifier.addStroke(currentStroke);
        undoNotifier.pushAction(
          StrokeAction(documentNotifier: docNotifier, stroke: currentStroke),
        );
        SoundEffectService.instance.playCelebration();
        ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
      }
      ref.read(currentStrokeProvider.notifier).state = null;
      _strokeHistory.clear();
      return;
    }

    // Selection end: keep selection active or deselect on single tap
    if (activeTool == DrawingTool.selection) {
      final sel = ref.read(activeSelectionRectProvider);
      if (sel != null && (sel.width < 5 || sel.height < 5)) {
        ref.read(activeSelectionRectProvider.notifier).state = null;
      } else {
        SoundEffectService.instance.playPop();
      }
      _selectionStartPoint = null;
      return;
    }

    // Transform end: commit translation with undo/redo support
    if (activeTool == DrawingTool.transform) {
      _transformStartPoint = null;
      final doc = ref.read(canvasDocumentProvider);
      final activeLayer = doc.activeLayer;
      if (_transformDidMove && activeLayer != null && _transformInitialStrokes.isNotEmpty) {
        ref.read(undoRedoProvider.notifier).pushAction(
          LayerStrokesAction(
            documentNotifier: ref.read(canvasDocumentProvider.notifier),
            oldStrokes: _transformInitialStrokes,
            newStrokes: List<Stroke>.from(activeLayer.strokes),
          ),
        );
        SoundEffectService.instance.playPop();
        ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
      }
      _transformInitialStrokes = [];
      _transformDidMove = false;
      return;
    }

    // Freehand stroke commit
    final currentStroke = ref.read(currentStrokeProvider);
    if (currentStroke != null && currentStroke.points.isNotEmpty) {
      final interpolated = (currentStroke.shapeType != ShapeType.none ||
              currentStroke.brush.isSpray ||
              currentStroke.brush.isRainbow)
          ? currentStroke.points
          : StrokeRenderer.interpolatePoints(currentStroke.points);
      final finalStroke = currentStroke.copyWith(points: interpolated);

      final doc = ref.read(canvasDocumentProvider);
      final symmetryConfig = ref.read(symmetryProvider);
      final docNotifier = ref.read(canvasDocumentProvider.notifier);
      final undoNotifier = ref.read(undoRedoProvider.notifier);

      if (symmetryConfig.isEnabled) {
        final symmetricStrokes = symmetryConfig.generateSymmetricStrokes(
          finalStroke,
          doc.width.toDouble(),
          doc.height.toDouble(),
        );

        for (final s in symmetricStrokes) {
          docNotifier.addStroke(s);
        }

        undoNotifier.pushAction(
          MultiStrokeAction(
            documentNotifier: docNotifier,
            strokes: symmetricStrokes,
          ),
        );
      } else {
        docNotifier.addStroke(finalStroke);
        undoNotifier.pushAction(
          StrokeAction(documentNotifier: docNotifier, stroke: finalStroke),
        );
      }

      SoundEffectService.instance.playPop();
      ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
    }

    _isQuickShapeSnapped = false;
    ref.read(currentStrokeProvider.notifier).state = null;
    _strokeHistory.clear();
  }

  Future<void> _performFloodFill(Offset localPoint) async {
    try {
      final doc = ref.read(canvasDocumentProvider);
      final fillColor = ref.read(activeColorProvider);
      final tolerance = ref.read(fillToleranceProvider);

      final fillStroke = await FloodFillService.instance.computeFill(
        document: doc,
        seedPoint: localPoint,
        fillColor: fillColor,
        tolerance: tolerance,
      );

      if (fillStroke != null && mounted) {
        final docNotifier = ref.read(canvasDocumentProvider.notifier);
        final undoNotifier = ref.read(undoRedoProvider.notifier);
        docNotifier.addStroke(fillStroke);
        undoNotifier.pushAction(
          StrokeAction(documentNotifier: docNotifier, stroke: fillStroke),
        );
        SoundEffectService.instance.playCelebration();
        ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
      }
    } catch (_) {
      // Flood fill fallback
    }
  }

  /// Samples the rendered color at `point` in canvas space by hit-testing strokes in reverse z-order.
  Color _sampleColorAt(CanvasDocument doc, Offset point) {
    final visibleLayers = doc.layers.where((l) => l.isVisible).toList().reversed;

    for (final layer in visibleLayers) {
      for (final stroke in layer.strokes.reversed) {
        if (_strokeContainsPoint(stroke, point)) {
          return stroke.color;
        }
      }
    }
    return doc.backgroundColor;
  }

  bool _strokeContainsPoint(Stroke stroke, Offset pt) {
    if (stroke.points.isEmpty) return false;

    final shape = stroke.shapeType;
    final strokeWidth = max(stroke.brush.size, 4.0);

    // Fast AABB bounding box early rejection for ultra-fast hit testing
    if (shape != ShapeType.floodFill &&
        !stroke.bounds.inflate(strokeWidth + 16.0).contains(pt)) {
      return false;
    }

    if (shape == ShapeType.floodFill) {
      final spanHeight = max(stroke.brush.size, 2.0);
      for (int i = 0; i < stroke.points.length - 1; i += 2) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        if (pt.dy >= p1.y &&
            pt.dy <= p1.y + spanHeight &&
            pt.dx >= min(p1.x, p2.x) &&
            pt.dx <= max(p1.x, p2.x) + 1.0) {
          return true;
        }
      }
      return false;
    }

    if (shape == ShapeType.rectangle || shape == ShapeType.roundedRectangle) {
      final p1 = stroke.points.first.offset;
      final p2 = stroke.points.last.offset;
      final rect = Rect.fromPoints(p1, p2);
      if (stroke.isFilled) {
        return rect.contains(pt);
      } else {
        final outer = rect.inflate(strokeWidth / 2);
        final inner = rect.deflate(strokeWidth / 2);
        return outer.contains(pt) && !inner.contains(pt);
      }
    }

    if (shape == ShapeType.gradientFill) {
      final p1 = stroke.points.first.offset;
      final p2 = stroke.points.last.offset;
      if (stroke.gradientType == GradientType.radial) {
        final radius = (p2 - p1).distance;
        return (pt - p1).distance <= radius;
      }
      return Rect.fromPoints(p1, p2).contains(pt);
    }

    if (shape == ShapeType.circle) {
      final p1 = stroke.points.first.offset;
      final p2 = stroke.points.last.offset;
      final rect = Rect.fromPoints(p1, p2);
      final rx = rect.width / 2;
      final ry = rect.height / 2;
      if (rx <= 0 || ry <= 0) return false;
      final dx = (pt.dx - rect.center.dx) / rx;
      final dy = (pt.dy - rect.center.dy) / ry;
      final normDistSq = dx * dx + dy * dy;
      if (stroke.isFilled) {
        return normDistSq <= 1.0;
      } else {
        final outerNorm = pow((rx + strokeWidth / 2) / rx, 2);
        final innerNorm = pow(max(0.0, rx - strokeWidth / 2) / rx, 2);
        return normDistSq <= outerNorm && normDistSq >= innerNorm;
      }
    }

    if (shape == ShapeType.line) {
      final p1 = stroke.points.first.offset;
      final p2 = stroke.points.last.offset;
      return _distanceToSegment(pt, p1, p2) <= strokeWidth / 2;
    }

    if (shape == ShapeType.text) {
      if (stroke.points.isEmpty || stroke.text == null || stroke.text!.isEmpty) return false;
      final p = stroke.points.first.offset;
      final fontSize = stroke.fontSize ?? 32.0;
      final textWidth = (stroke.text!.length * fontSize * 0.65);
      final textRect = Rect.fromLTWH(p.dx, p.dy, textWidth, fontSize * 1.3);
      return textRect.contains(pt);
    }

    if (shape == ShapeType.image) {
      if (stroke.points.isEmpty) return false;
      final p1 = stroke.points.first.offset;
      final p2 = stroke.points.length > 1 ? stroke.points[1].offset : p1;
      final rect = Rect.fromPoints(p1, p2);
      final rot = stroke.imageRotation ?? 0.0;
      if (rot != 0.0) {
        final center = rect.center;
        final cosR = cos(-rot);
        final sinR = sin(-rot);
        final dx = pt.dx - center.dx;
        final dy = pt.dy - center.dy;
        final unrotatedPt = Offset(cosR * dx - sinR * dy + center.dx, sinR * dx + cosR * dy + center.dy);
        return rect.contains(unrotatedPt);
      }
      return rect.contains(pt);
    }

    if (shape != ShapeType.none &&
        shape != ShapeType.line &&
        shape != ShapeType.text &&
        shape != ShapeType.image &&
        shape != ShapeType.floodFill &&
        shape != ShapeType.gradientFill) {
      if (stroke.points.isEmpty) return false;
      final p1 = stroke.points.first.offset;
      final p2 = stroke.points.length > 1 ? stroke.points.last.offset : p1;
      final rect = Rect.fromPoints(p1, p2);
      return rect.contains(pt);
    }

    // Freehand stroke: check distance to each line segment
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];
      final segRadius = (stroke.brush.size * ((p1.pressure + p2.pressure) / 2) / 2).clamp(3.0, 100.0);
      if (_distanceToSegment(pt, p1.offset, p2.offset) <= segRadius) {
        return true;
      }
    }
    if (stroke.points.length == 1) {
      final p = stroke.points.first;
      final r = (stroke.brush.size * p.pressure / 2).clamp(3.0, 100.0);
      if ((pt - p.offset).distance <= r) return true;
    }

    return false;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLenSq == 0) return (p - a).distance;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / abLenSq).clamp(0.0, 1.0);
    final projection = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
    return (p - projection).distance;
  }

  /// Calculates snapped line endpoint based on the selected RulerGuideMode.
  Offset _snapToRuler(Offset start, Offset current, RulerGuideMode mode) {
    final dx = current.dx - start.dx;
    final dy = current.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance < 2.0) return current;

    switch (mode) {
      case RulerGuideMode.off:
        return current;

      case RulerGuideMode.straight:
        final angle = atan2(dy, dx);
        final deg = (angle * 180 / pi + 360) % 360;
        if ((deg < 20 || deg > 340) || (deg > 160 && deg < 200)) {
          return Offset(current.dx, start.dy);
        } else if ((deg > 70 && deg < 110) || (deg > 250 && deg < 290)) {
          return Offset(start.dx, current.dy);
        }
        return current;

      case RulerGuideMode.angle45:
        final angle = atan2(dy, dx);
        const step = pi / 4;
        final snappedAngle = (angle / step).round() * step;
        return Offset(
          start.dx + distance * cos(snappedAngle),
          start.dy + distance * sin(snappedAngle),
        );

      case RulerGuideMode.isometric:
        final angle = atan2(dy, dx);
        const isoAngles = [-150.0, -90.0, -30.0, 30.0, 90.0, 150.0];
        final currentDeg = angle * 180 / pi;
        double closest = isoAngles.first;
        double minDiff = (currentDeg - closest).abs();
        for (final a in isoAngles) {
          final diff = (currentDeg - a).abs();
          if (diff < minDiff) {
            minDiff = diff;
            closest = a;
          }
        }
        final snappedAngle = closest * pi / 180;
        return Offset(
          start.dx + distance * cos(snappedAngle),
          start.dy + distance * sin(snappedAngle),
        );

      case RulerGuideMode.grid:
        const gridSize = 20.0;
        final snappedX = (current.dx / gridSize).round() * gridSize;
        final snappedY = (current.dy / gridSize).round() * gridSize;
        return Offset(snappedX, snappedY);
    }
  }

  /// Start the QuickShape hold timer (triggers when user pauses stylus/finger for 420ms).
  void _startQuickShapeTimer() {
    _quickShapeTimer?.cancel();
    if (!ref.read(quickShapeEnabledProvider)) return;

    _quickShapeTimer = Timer(const Duration(milliseconds: 420), () {
      if (!mounted || !_isDrawing) return;
      final currentStroke = ref.read(currentStrokeProvider);
      if (currentStroke == null || currentStroke.points.length < 5) return;
      if (currentStroke.shapeType != ShapeType.none) return;

      final result = QuickShapeRecognizer.recognize(currentStroke.points);
      if (result != null) {
        _isQuickShapeSnapped = true;
        HapticFeedback.mediumImpact();
        SoundEffectService.instance.playPop();

        ref.read(currentStrokeProvider.notifier).state = currentStroke.copyWith(
          shapeType: result.shapeType,
          points: result.points,
        );
      }
    });
  }

  /// Reset QuickShape hold timer when pointer moves significantly.
  void _resetQuickShapeTimer(Offset currentPos) {
    if (_lastPointerMovePos == null) {
      _lastPointerMovePos = currentPos;
      _startQuickShapeTimer();
      return;
    }

    final dist = (currentPos - _lastPointerMovePos!).distance;
    if (dist > 8.0) {
      _lastPointerMovePos = currentPos;
      if (!_isQuickShapeSnapped) {
        _startQuickShapeTimer();
      }
    }
  }

  /// Snaps freehand point to nearest perspective ray if snapToGuide is enabled.
  Offset _snapToPerspective(
    Offset pt,
    DrawingGuideConfig guide,
    double canvasWidth,
    double canvasHeight,
  ) {
    final horizonY = canvasHeight * guide.horizonRatio;
    final vps = <Offset>[
      Offset(canvasWidth * guide.vp1Ratio, horizonY),
    ];
    if (guide.type == DrawingGuideType.perspective2P ||
        guide.type == DrawingGuideType.perspective3P) {
      vps.add(Offset(canvasWidth * guide.vp2Ratio, horizonY));
    }
    if (guide.type == DrawingGuideType.perspective3P) {
      vps.add(Offset(canvasWidth * 0.5, canvasHeight * guide.vp3Ratio));
    }

    Offset? nearestVp;
    double minVpDist = double.infinity;
    for (final vp in vps) {
      final d = (pt - vp).distance;
      if (d < minVpDist && d > 8.0) {
        minVpDist = d;
        nearestVp = vp;
      }
    }
    if (nearestVp == null) return pt;

    final vec = pt - nearestVp;
    final angle = atan2(vec.dy, vec.dx);
    final rayCount = guide.rayCount > 0 ? guide.rayCount : 14;
    final rayAngleStep = pi / rayCount;
    final snappedAngle = (angle / rayAngleStep).round() * rayAngleStep;
    final snappedDist = vec.distance;

    final snappedOffset = Offset(
      nearestVp.dx + cos(snappedAngle) * snappedDist,
      nearestVp.dy + sin(snappedAngle) * snappedDist,
    );

    if ((pt - snappedOffset).distance < 20.0) {
      return snappedOffset;
    }
    return pt;
  }

  void _onDoubleTapZoom() {
    final gestureSettings = ref.read(gestureSettingsProvider);
    if (!gestureSettings.doubleTapZoomReset) return;

    if (_lastViewportWidth <= 0 || _lastViewportHeight <= 0) return;
    final doc = ref.read(canvasDocumentProvider);
    final viewNotifier = ref.read(canvasViewProvider.notifier);
    final currentZoom = ref.read(canvasViewProvider).zoom;

    final scaleX = _lastViewportWidth / doc.width;
    final scaleY = _lastViewportHeight / doc.height;
    final fitZoom = ((scaleX < scaleY ? scaleX : scaleY) * 0.90)
        .clamp(CanvasDefaults.minZoom, CanvasDefaults.maxZoom);

    // If currently fitted (or close to it), zoom in for detail
    if ((currentZoom - fitZoom).abs() < 0.06 || currentZoom < fitZoom * 1.25) {
      viewNotifier.setZoom((fitZoom * 2.5).clamp(CanvasDefaults.minZoom, CanvasDefaults.maxZoom));
    } else {
      // If zoomed in, double-tap neatly fits and centers the artwork back to the screen!
      viewNotifier.fitToScreen(
        _lastViewportWidth,
        _lastViewportHeight,
        doc.width,
        doc.height,
      );
    }
  }

  /// Convert screen coordinates to canvas coordinates.
  Offset _screenToCanvas(Offset screenPoint, CanvasViewState viewState) {
    final zoom = _activeZoom > 0 ? _activeZoom : viewState.zoom;
    final panX = _activePanX != 0.0 ? _activePanX : viewState.panX;
    final panY = _activePanY != 0.0 ? _activePanY : viewState.panY;
    return Offset(
      (screenPoint.dx - panX) / zoom,
      (screenPoint.dy - panY) / zoom,
    );
  }

  /// Convert canvas coordinates to screen coordinates.
  Offset _canvasToScreen(Offset canvasPoint, CanvasViewState viewState) {
    final zoom = _activeZoom > 0 ? _activeZoom : viewState.zoom;
    final panX = _activePanX != 0.0 ? _activePanX : viewState.panX;
    final panY = _activePanY != 0.0 ? _activePanY : viewState.panY;
    return Offset(
      canvasPoint.dx * zoom + panX,
      canvasPoint.dy * zoom + panY,
    );
  }

  /// Prompt user with a dialog to enter text when tapping on an empty canvas.
  void _promptAddTextAt(Offset localPoint) {
    SoundEffectService.instance.playPop();
    showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _TextInputDialog(
        title: 'Add Text to Canvas',
        initialText: '',
        actionLabel: 'Add Text',
      ),
    ).then((enteredText) {
      if (enteredText != null && enteredText.trim().isNotEmpty && mounted) {
        final doc = ref.read(canvasDocumentProvider);
        final activeLayer = doc.activeLayer;
        if (activeLayer == null || activeLayer.isLocked) return;

        final font = ref.read(selectedFontProvider);
        final typoConfig = ref.read(typographyConfigProvider);
        final color = ref.read(activeColorProvider);
        final brush = ref.read(activeBrushProvider);
        final docNotifier = ref.read(canvasDocumentProvider.notifier);
        final undoNotifier = ref.read(undoRedoProvider.notifier);

        final textStroke = Stroke(
          points: [
            StrokePoint(
              x: localPoint.dx,
              y: localPoint.dy,
              pressure: 1.0,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          ],
          color: typoConfig.color != Colors.black ? typoConfig.color : color,
          brush: brush,
          shapeType: ShapeType.text,
          text: enteredText.trim(),
          fontFamily: font.name,
          fontSize: typoConfig.fontSize,
          isBold: typoConfig.isBold,
          isItalic: typoConfig.isItalic,
          textAlign: typoConfig.textAlign.name,
          textDecoration: typoConfig.textDecoration == TextDecoration.underline
              ? 'underline'
              : typoConfig.textDecoration == TextDecoration.lineThrough
                  ? 'strikethrough'
                  : 'none',
          hasShadow: typoConfig.hasShadow,
          textShadowOffsetX: typoConfig.shadowOffsetX,
          textShadowOffsetY: typoConfig.shadowOffsetY,
          textShadowBlur: typoConfig.shadowBlur,
          textLineHeight: typoConfig.lineHeight,
          textStrokeColor: typoConfig.strokeWidth > 0 ? typoConfig.strokeColor : null,
          textStrokeWidth: typoConfig.strokeWidth > 0 ? typoConfig.strokeWidth : null,
          textBackgroundColor: typoConfig.hasBackgroundBox ? typoConfig.backgroundColor : null,
        );

        docNotifier.addStroke(textStroke);
        undoNotifier.pushAction(
          StrokeAction(documentNotifier: docNotifier, stroke: textStroke),
        );
        ref.read(selectedTextStrokeIdProvider.notifier).state = textStroke.id;
        ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
        SoundEffectService.instance.playCelebration();
      }
    });
  }

  /// Open edit dialog for existing text stroke.
  void _editExistingText(Stroke textStroke) {
    SoundEffectService.instance.playPop();
    showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _TextInputDialog(
        title: 'Edit Text',
        initialText: textStroke.text ?? '',
        actionLabel: 'Update Text',
      ),
    ).then((updatedText) {
      if (updatedText != null && updatedText.trim().isNotEmpty && mounted) {
        final doc = ref.read(canvasDocumentProvider);
        final activeLayer = doc.activeLayer;
        if (activeLayer == null || activeLayer.isLocked) return;

        final oldStrokes = List<Stroke>.from(activeLayer.strokes);
        final updatedStroke = textStroke.copyWith(text: updatedText.trim());
        final updatedStrokes = activeLayer.strokes
            .map((s) => s.id == textStroke.id ? updatedStroke : s)
            .toList();

        ref.read(canvasDocumentProvider.notifier).updateActiveLayerStrokes(updatedStrokes);
        ref.read(undoRedoProvider.notifier).pushAction(
          LayerStrokesAction(
            documentNotifier: ref.read(canvasDocumentProvider.notifier),
            oldStrokes: oldStrokes,
            newStrokes: updatedStrokes,
          ),
        );
        ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
        SoundEffectService.instance.playCelebration();
      }
    });
  }

  /// Delete selected text stroke.
  void _deleteSelectedText(String strokeId) {
    final doc = ref.read(canvasDocumentProvider);
    final activeLayer = doc.activeLayer;
    if (activeLayer == null || activeLayer.isLocked) return;

    final oldStrokes = List<Stroke>.from(activeLayer.strokes);
    final updatedStrokes = activeLayer.strokes.where((s) => s.id != strokeId).toList();

    ref.read(canvasDocumentProvider.notifier).updateActiveLayerStrokes(updatedStrokes);
    ref.read(undoRedoProvider.notifier).pushAction(
      LayerStrokesAction(
        documentNotifier: ref.read(canvasDocumentProvider.notifier),
        oldStrokes: oldStrokes,
        newStrokes: updatedStrokes,
      ),
    );
    ref.read(selectedTextStrokeIdProvider.notifier).state = null;
    ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
    SoundEffectService.instance.playWhoosh();
    HapticFeedback.mediumImpact();
  }

  /// Apply typography changes from FontPickerDialog to the selected text stroke.
  void _applyTextToCanvasFromWidget(String text) {
    final selectedId = ref.read(selectedTextStrokeIdProvider);
    final doc = ref.read(canvasDocumentProvider);
    final activeLayer = doc.activeLayer;

    if (selectedId != null && activeLayer != null) {
      final existingIndex = activeLayer.strokes.indexWhere((s) => s.id == selectedId);
      if (existingIndex != -1) {
        final existing = activeLayer.strokes[existingIndex];
        final font = ref.read(selectedFontProvider);
        final typoConfig = ref.read(typographyConfigProvider);
        final updated = existing.copyWith(
          text: text.isNotEmpty ? text : existing.text,
          fontFamily: font.name,
          fontSize: typoConfig.fontSize,
          isBold: typoConfig.isBold,
          isItalic: typoConfig.isItalic,
          textAlign: typoConfig.textAlign.name,
          color: typoConfig.color != Colors.black ? typoConfig.color : existing.color,
          hasShadow: typoConfig.hasShadow,
          textShadowOffsetX: typoConfig.shadowOffsetX,
          textShadowOffsetY: typoConfig.shadowOffsetY,
          textShadowBlur: typoConfig.shadowBlur,
          textLineHeight: typoConfig.lineHeight,
          textStrokeColor: typoConfig.strokeWidth > 0 ? typoConfig.strokeColor : null,
          textStrokeWidth: typoConfig.strokeWidth > 0 ? typoConfig.strokeWidth : null,
          textBackgroundColor: typoConfig.hasBackgroundBox ? typoConfig.backgroundColor : null,
        );
        ref.read(canvasDocumentProvider.notifier).updateStroke(updated);
        ref.read(undoRedoProvider.notifier).pushAction(
          LayerStrokesAction(
            documentNotifier: ref.read(canvasDocumentProvider.notifier),
            oldStrokes: List<Stroke>.from(activeLayer.strokes),
            newStrokes: activeLayer.strokes.map((s) => s.id == selectedId ? updated : s).toList(),
          ),
        );
        ref.read(saveStatusProvider.notifier).state = SaveStatus.saving;
        SoundEffectService.instance.playCelebration();
      }
    }
  }

  /// Floating overlay showing selection bounding box and action controls for selected text.
  Widget _buildTextSelectionOverlay(
    BuildContext context,
    CanvasViewState viewState,
    CanvasDocument document,
  ) {
    final selectedId = ref.watch(selectedTextStrokeIdProvider);
    if (selectedId == null) return const SizedBox.shrink();

    final activeLayer = document.activeLayer;
    if (activeLayer == null) return const SizedBox.shrink();

    final selectedStroke = activeLayer.strokes.where((s) => s.id == selectedId).firstOrNull;
    if (selectedStroke == null || selectedStroke.shapeType != ShapeType.text) {
      return const SizedBox.shrink();
    }

    final start = selectedStroke.points.first;
    final fontSize = selectedStroke.fontSize ?? 24.0;
    final textLen = selectedStroke.text?.length ?? 5;
    final w = max(textLen * fontSize * 0.75, 48.0);
    final h = max(fontSize * 1.4, 32.0);
    final canvasRect = Rect.fromLTWH(start.x, start.y, w, h);

    final screenTopLeft = _canvasToScreen(canvasRect.topLeft, viewState);
    final screenBottomRight = _canvasToScreen(canvasRect.bottomRight, viewState);
    final screenRect = Rect.fromPoints(screenTopLeft, screenBottomRight);

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final pillTop = (screenRect.top > 90 ? screenRect.top - 46 : screenRect.bottom + 10)
        .clamp(60.0, mediaQuery.size.height - 180);
    final pillLeft = (screenRect.center.dx - 120).clamp(16.0, screenWidth - 260);

    return Positioned.fill(
      child: Stack(
        children: [
          // Bounding Box
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TextSelectionBoxPainter(rect: screenRect),
              ),
            ),
          ),

          // Floating Quick-Action Pill
          Positioned(
            left: pillLeft,
            top: pillTop,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TextOverlayActionBtn(
                      icon: Icons.edit_rounded,
                      label: 'Edit',
                      onTap: () => _editExistingText(selectedStroke),
                    ),
                    const SizedBox(width: 4),
                    _TextOverlayActionBtn(
                      icon: Icons.font_download_rounded,
                      label: 'Style',
                      onTap: () {
                        SoundEffectService.instance.playPop();
                        FontPickerDialog.show(
                          context,
                          initialText: selectedStroke.text,
                          onApplyText: (text, _) => _applyTextToCanvasFromWidget(text),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    _TextOverlayActionBtn(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      isDestructive: true,
                      onTap: () => _deleteSelectedText(selectedStroke.id),
                    ),
                    const SizedBox(width: 4),
                    _TextOverlayActionBtn(
                      icon: Icons.check_rounded,
                      label: 'Done',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(selectedTextStrokeIdProvider.notifier).state = null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating action button inside the text selection pill overlay.
class _TextOverlayActionBtn extends StatelessWidget {
  const _TextOverlayActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFFF6B6B) : Colors.white;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter for the dashed/solid bounding box and corner handles of selected text.
class _TextSelectionBoxPainter extends CustomPainter {
  const _TextSelectionBoxPainter({required this.rect});
  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    if (rect.isEmpty) return;

    // Glowing border
    final glowPaint = Paint()
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(6)), glowPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(6)), borderPaint);

    // 4 Corner dots
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = const Color(0xFF6C5CE7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    for (final corner in [
      rect.inflate(4).topLeft,
      rect.inflate(4).topRight,
      rect.inflate(4).bottomLeft,
      rect.inflate(4).bottomRight,
    ]) {
      canvas.drawCircle(corner, 4.5, handlePaint);
      canvas.drawCircle(corner, 4.5, handleBorder);
    }
  }

  @override
  bool shouldRepaint(_TextSelectionBoxPainter oldDelegate) => oldDelegate.rect != rect;
}

/// Dialog allowing user to type new text or edit existing text on canvas.
class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.initialText,
    required this.actionLabel,
  });

  final String title;
  final String initialText;
  final String actionLabel;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.title_rounded,
                    color: Color(0xFF6C5CE7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Type your text here...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF28283E) : const Color(0xFFF1F2F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6C5CE7),
                    width: 1.8,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  Navigator.of(context).pop(val.trim());
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop(text);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: Text(
                    widget.actionLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating circular loupe displaying the currently sampled color and hex code.
class _EyedropperLoupe extends StatelessWidget {
  const _EyedropperLoupe({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hexCode =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 3.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            hexCode,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

/// Renders a marching-ants style dashed bounding box for the selection tool.
class _SelectionMarqueePainter extends CustomPainter {
  const _SelectionMarqueePainter({required this.rect});
  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    if (rect.isEmpty) return;

    // Fill tint
    final fillPaint = Paint()
      ..color = const Color(0x22007AFF)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFF007AFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, borderPaint);

    // 4 Corner handles
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final handleBorder = Paint()
      ..color = const Color(0xFF007AFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      final handleRect = Rect.fromCenter(center: corner, width: 8, height: 8);
      canvas.drawRect(handleRect, handlePaint);
      canvas.drawRect(handleRect, handleBorder);
    }
  }

  @override
  bool shouldRepaint(_SelectionMarqueePainter oldDelegate) => oldDelegate.rect != rect;
}

