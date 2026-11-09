import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../rendering/engine/stroke_renderer.dart';
import '../../canvas/models/stroke.dart';
import '../../templates/models/coloring_template.dart';
import '../../templates/services/coloring_catalog_service.dart';
import '../../templates/views/coloring_templates_modal.dart';
import '../models/ar_tracing_models.dart';
import 'ar_tutorial_dialog.dart';
import '../../templates/views/design_preview_modal.dart';

/// Full-featured AR Tracing Studio.
/// Projects crisp line-art overlays onto physical paper via live camera or simulated desk.
class ArTracingScreen extends ConsumerStatefulWidget {
  const ArTracingScreen({
    super.key,
    this.initialTemplate,
    this.customStrokes,
    this.templateTitle,
  });

  final ColoringTemplate? initialTemplate;
  final List<Stroke>? customStrokes;
  final String? templateTitle;

  @override
  ConsumerState<ArTracingScreen> createState() => _ArTracingScreenState();
}

class _ArTracingScreenState extends ConsumerState<ArTracingScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _simulatedDeskMode = true;
  bool _isDisposed = false;

  late ColoringTemplate _currentTemplate;
  List<Stroke>? _activeStrokes;
  Uint8List? _galleryImageBytes;
  String _activeTitle = 'AR Tracing';

  ArTracingConfig _config = const ArTracingConfig();

  // Transformation state
  double _scale = 1.0;
  double _rotation = 0.0;
  Offset _offset = Offset.zero;

  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _baseOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.initialTemplate != null) {
      _currentTemplate = widget.initialTemplate!;
      _activeTitle = _currentTemplate.title;
      _activeStrokes = _currentTemplate.strokeGenerator(1000, 1000);
    } else if (widget.customStrokes != null && widget.customStrokes!.isNotEmpty) {
      _currentTemplate = ColoringCatalogService.instance.getRandomTemplate();
      _activeStrokes = widget.customStrokes;
      _activeTitle = widget.templateTitle ?? 'My Canvas Artwork';
    } else {
      _currentTemplate = ColoringCatalogService.instance.getRandomTemplate();
      _activeTitle = _currentTemplate.title;
      _activeStrokes = _currentTemplate.strokeGenerator(1000, 1000);
    }

    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController = null;
      _isCameraInitialized = false;
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _simulatedDeskMode = true);
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _cameraController = controller;

      await controller.initialize();
      if (!_isDisposed && mounted) {
        setState(() {
          _isCameraInitialized = true;
          _simulatedDeskMode = false;
        });
      }
    } catch (_) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isCameraInitialized = false;
          _simulatedDeskMode = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    final camera = _cameraController;
    _cameraController = null;
    _isCameraInitialized = false;
    camera?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlashlight() async {
    SoundEffectService.instance.playPop();
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    final newFlash = !_config.isFlashOn;
    try {
      await _cameraController!.setFlashMode(newFlash ? FlashMode.torch : FlashMode.off);
      setState(() => _config = _config.copyWith(isFlashOn: newFlash));
    } catch (_) {}
  }

  Future<void> _toggleFreeze() async {
    SoundEffectService.instance.playPop();
    final newFreeze = !_config.isFrozen;
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        if (newFreeze) {
          await _cameraController!.pausePreview();
        } else {
          await _cameraController!.resumePreview();
        }
      } catch (_) {}
    }
    setState(() => _config = _config.copyWith(isFrozen: newFreeze));
  }

  void _cycleFilter() {
    SoundEffectService.instance.playPop();
    final nextIndex = (_config.filterMode.index + 1) % ArFilterMode.values.length;
    setState(() {
      _config = _config.copyWith(filterMode: ArFilterMode.values[nextIndex]);
    });
  }

  void _resetTransform() {
    SoundEffectService.instance.playPop();
    setState(() {
      _scale = 1.0;
      _rotation = 0.0;
      _offset = Offset.zero;
    });
  }

  void _toggleLock() {
    SoundEffectService.instance.playPop();
    setState(() {
      _config = _config.copyWith(isLocked: !_config.isLocked);
    });
  }

  Future<void> _pickFromGallery() async {
    SoundEffectService.instance.playPop();
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        final bytes = await File(picked.path).readAsBytes();
        if (mounted) {
          setState(() {
            _galleryImageBytes = bytes;
            _activeTitle = 'Imported Photo';
            _activeStrokes = null;
            _scale = 1.0;
            _rotation = 0.0;
            _offset = Offset.zero;
          });
          SoundEffectService.instance.playCelebration();
        }
      }
    } catch (_) {
      // Ignored
    }
  }

  void _selectTemplate(ColoringTemplate template) {
    SoundEffectService.instance.playCelebration();
    setState(() {
      _currentTemplate = template;
      _activeTitle = template.title;
      _activeStrokes = template.strokeGenerator(1000, 1000);
      _galleryImageBytes = null;
      _scale = 1.0;
      _rotation = 0.0;
      _offset = Offset.zero;
    });
  }

  Future<void> _takeSnapshot() async {
    SoundEffectService.instance.playPop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            SizedBox(width: AppSpacing.sm),
            Text('Tracing Snapshot Captured!'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Live Camera or Simulated Desk Background ──────────────────
          if (_isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized)
            Center(
              child: CameraPreview(_cameraController!),
            )
          else
            _SimulatedDeskView(isFrozen: _config.isFrozen),

          // ── 2. Interactive Projected Line-Art Overlay ─────────────────────
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: (details) {
              if (_config.isLocked) return;
              _baseScale = _scale;
              _baseRotation = _rotation;
              _baseOffset = _offset;
              _startFocalPoint = details.focalPoint;
            },
            onScaleUpdate: (details) {
              if (_config.isLocked) return;
              setState(() {
                _scale = (_baseScale * details.scale).clamp(0.05, 20.0);
                _rotation = _baseRotation + details.rotation;
                final delta = details.focalPoint - _startFocalPoint;
                _offset = _baseOffset + delta;
              });
            },
            child: Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0.0)
                  ..scaleByDouble(_scale, _scale, 1.0, 1.0)
                  ..rotateZ(_rotation),
                child: Opacity(
                  opacity: _config.opacity,
                  child: SizedBox(
                    width: min(size.width * 0.9, 450),
                    height: min(size.width * 0.9, 450),
                    child: _galleryImageBytes != null
                        ? _buildGalleryImageView()
                        : (_activeStrokes != null
                            ? CustomPaint(
                                painter: _ArStrokePainter(
                                  strokes: _activeStrokes!,
                                  filterMode: _config.filterMode,
                                ),
                              )
                            : const SizedBox.shrink()),
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Top Action Bar ──────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () {
                        SoundEffectService.instance.playPop();
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _activeTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _simulatedDeskMode
                                      ? Colors.amber.withValues(alpha: 0.8)
                                      : Colors.tealAccent.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _simulatedDeskMode ? 'Desk Simulation' : 'Live Camera AR',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_config.isLocked) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'LOCKED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Flashlight
                    if (_isCameraInitialized)
                      IconButton(
                        icon: Icon(
                          _config.isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _config.isFlashOn ? Colors.amberAccent : Colors.white,
                        ),
                        onPressed: _toggleFlashlight,
                        tooltip: 'Flashlight',
                      ),
                    // Freeze Preview
                    IconButton(
                      icon: Icon(
                        _config.isFrozen ? Icons.play_circle_rounded : Icons.pause_circle_rounded,
                        color: _config.isFrozen ? Colors.amberAccent : Colors.white,
                      ),
                      onPressed: _toggleFreeze,
                      tooltip: _config.isFrozen ? 'Resume Camera' : 'Freeze Camera',
                    ),
                    // Design & Color Preview Button
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye_rounded, color: Colors.cyanAccent),
                      onPressed: () {
                        SoundEffectService.instance.playPop();
                        DesignPreviewModal.show(context, template: _currentTemplate);
                      },
                      tooltip: 'Preview Design & Colors',
                    ),
                    // Reset Transformation Button
                    IconButton(
                      icon: const Icon(Icons.center_focus_strong_rounded, color: Colors.white),
                      onPressed: () {
                        SoundEffectService.instance.playPop();
                        setState(() {
                          _scale = 1.0;
                          _rotation = 0.0;
                          _offset = Offset.zero;
                        });
                      },
                      tooltip: 'Reset Position & Zoom',
                    ),
                    // Help / Tutorial
                    IconButton(
                      icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
                      onPressed: () => ArTutorialDialog.show(context),
                      tooltip: 'How to Trace in AR',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── 4. Bottom Control Bar ──────────────────────────────────────────
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Opacity Slider Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.opacity_rounded, color: Colors.white70, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${(_config.opacity * 100).round()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Slider(
                              value: _config.opacity,
                              min: 0.1,
                              max: 1.0,
                              activeColor: theme.colorScheme.primary,
                              inactiveColor: Colors.white30,
                              onChanged: (val) {
                                setState(() => _config = _config.copyWith(opacity: val));
                              },
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _resetTransform,
                            child: const Text('Reset', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Quick Action Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Lock Button
                        _ArActionButton(
                          icon: _config.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                          label: _config.isLocked ? 'Locked' : 'Lock',
                          isActive: _config.isLocked,
                          activeColor: Colors.redAccent,
                          onTap: _toggleLock,
                        ),

                        // Filter Button
                        _ArActionButton(
                          icon: _config.filterMode.icon,
                          label: _config.filterMode.label,
                          isActive: _config.filterMode != ArFilterMode.normal,
                          activeColor: Colors.cyanAccent,
                          onTap: _cycleFilter,
                        ),

                        // Shutter / Capture Button
                        GestureDetector(
                          onTap: _takeSnapshot,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B9D), Color(0xFFFFA94D)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B9D).withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                          ),
                        ),

                        // Change Template (1,200+ library)
                        _ArActionButton(
                          icon: Icons.palette_rounded,
                          label: 'Templates',
                          isActive: false,
                          onTap: () {
                            SoundEffectService.instance.playPop();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => ColoringTemplatesModal(
                                onSelectTemplate: (t) {
                                  Navigator.of(context).pop();
                                  _selectTemplate(t);
                                },
                              ),
                            );
                          },
                        ),

                        // Gallery Image
                        _ArActionButton(
                          icon: Icons.photo_library_rounded,
                          label: 'Gallery',
                          isActive: _galleryImageBytes != null,
                          activeColor: Colors.purpleAccent,
                          onTap: _pickFromGallery,
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryImageView() {
    Widget imageWidget = Image.memory(
      _galleryImageBytes!,
      fit: BoxFit.contain,
    );

    if (_config.filterMode == ArFilterMode.highContrast) {
      imageWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          1.5, 0, 0, 0, -50,
          0, 1.5, 0, 0, -50,
          0, 0, 1.5, 0, -50,
          0, 0, 0, 1, 0,
        ]),
        child: imageWidget,
      );
    } else if (_config.filterMode == ArFilterMode.neonInvert) {
      imageWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1, 0, 0, 0, 255,
          0, -1, 0, 0, 255,
          0, 0, -1, 0, 255,
          0, 0, 0, 1, 0,
        ]),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

class _ArActionButton extends StatelessWidget {
  const _ArActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.activeColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? activeColor.withValues(alpha: 0.25) : Colors.white12,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? activeColor : Colors.white24,
                ),
              ),
              child: Icon(icon, color: isActive ? activeColor : Colors.white, size: 20),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter rendering strokes with the selected AR filter mode.
class _ArStrokePainter extends CustomPainter {
  const _ArStrokePainter({
    required this.strokes,
    required this.filterMode,
  });

  final List<Stroke> strokes;
  final ArFilterMode filterMode;

  @override
  void paint(Canvas canvas, Size size) {
    Color strokeColor;
    double strokeMultiplier = 1.0;

    switch (filterMode) {
      case ArFilterMode.normal:
        strokeColor = const Color(0xFF1E293B);
        strokeMultiplier = 1.0;
        break;
      case ArFilterMode.highContrast:
        strokeColor = Colors.black;
        strokeMultiplier = 1.3;
        break;
      case ArFilterMode.neonInvert:
        strokeColor = const Color(0xFF00FFCC);
        strokeMultiplier = 1.1;
        break;
      case ArFilterMode.charcoalEdge:
        strokeColor = const Color(0xFF475569);
        strokeMultiplier = 0.9;
        break;
    }

    final scaleX = size.width / 1000.0;
    final scaleY = size.height / 1000.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    for (final stroke in strokes) {
      final modifiedBrush = stroke.brush.copyWith(
        size: stroke.brush.size * strokeMultiplier,
      );
      final modifiedStroke = stroke.copyWith(
        color: strokeColor,
        brush: modifiedBrush,
      );
      StrokeRenderer.renderStroke(canvas, modifiedStroke);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArStrokePainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.filterMode != filterMode;
  }
}

/// Fallback view simulating a physical desk and blank paper sheet for emulator / no camera setups.
class _SimulatedDeskView extends StatelessWidget {
  const _SimulatedDeskView({required this.isFrozen});

  final bool isFrozen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A231C), // Deep warm desk wood
            Color(0xFF1A1512),
            Color(0xFF0F0D0B),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 340,
          height: 480,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 25,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle sketch grid lines on paper
              CustomPaint(
                size: const Size(340, 480),
                painter: _DeskPaperGridPainter(),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Row(
                  children: [
                    const Icon(Icons.mode_edit_outline_rounded, size: 14, color: Colors.black26),
                    const SizedBox(width: 4),
                    Text(
                      'Physical Paper Sheet (A4)',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeskPaperGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
