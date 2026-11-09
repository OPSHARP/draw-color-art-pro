import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../providers/canvas_providers.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Provider for active reference image file path (null if none loaded).
final referenceImageProvider = StateProvider<File?>((ref) => null);

/// Provider for whether reference eyedropper mode is active.
final isReferenceEyedropperActiveProvider = StateProvider<bool>((ref) => false);

/// Floating Draggable Picture-in-Picture Reference Image Window.
///
/// Gives artists a pro-level companion to view reference photos, zoom/pan,
/// and sample colors directly into their active palette while drawing on canvas.
class FloatingReferenceCompanion extends ConsumerStatefulWidget {
  const FloatingReferenceCompanion({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  ConsumerState<FloatingReferenceCompanion> createState() =>
      _FloatingReferenceCompanionState();
}

class _FloatingReferenceCompanionState
    extends ConsumerState<FloatingReferenceCompanion> {
  Offset _position = const Offset(16, 50);
  bool _isMinimized = false;
  final double _width = 220;
  final double _height = 240;
  final ImagePicker _picker = ImagePicker();

  // Cached decoded image for real-time pixel sampling
  img.Image? _decodedImage;
  File? _lastLoadedFile;

  @override
  Widget build(BuildContext context) {
    final refFile = ref.watch(referenceImageProvider);
    final isEyedropper = ref.watch(isReferenceEyedropperActiveProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isMinimized) {
      return Positioned(
        left: _position.dx,
        top: _position.dy,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _position += details.delta;
            });
          },
          onTap: () {
            SoundEffectService.instance.playPop();
            setState(() => _isMinimized = false);
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFFF6B9D)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.image_search_rounded, color: Colors.white, size: 22),
          ),
        ),
      );
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isDark ? const Color(0xFF3B3B5C) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header Handle ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161626) : const Color(0xFFF1F5F9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sm - 1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reference',
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    // Eyedropper toggle
                    if (refFile != null)
                      IconButton(
                        icon: Icon(
                          Icons.colorize_rounded,
                          size: 14,
                          color: isEyedropper ? theme.colorScheme.primary : null,
                        ),
                        tooltip: 'Sample Color',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          SoundEffectService.instance.playPop();
                          ref.read(isReferenceEyedropperActiveProvider.notifier).state = !isEyedropper;
                        },
                      ),
                    const SizedBox(width: 6),
                    // Minimize
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 14),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _isMinimized = true),
                    ),
                    const SizedBox(width: 6),
                    // Close
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 14),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),

              // ── Content Area ──
              Expanded(
                child: refFile == null
                    ? _buildEmptyState(context)
                    : _buildImageViewer(context, refFile, isEyedropper),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 6),
          Text('No Image Loaded', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () => _pickImage(ImageSource.gallery),
                child: const Text('Gallery', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 6),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () => _pickImage(ImageSource.camera),
                child: const Text('Camera', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer(BuildContext context, File file, bool isEyedropper) {
    _ensureDecoded(file);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.sm - 1)),
          child: InteractiveViewer(
            panEnabled: !isEyedropper,
            scaleEnabled: !isEyedropper,
            minScale: 0.5,
            maxScale: 4.0,
            child: GestureDetector(
              onTapDown: isEyedropper ? (d) => _samplePixelAt(d.localPosition) : null,
              child: Image.file(
                file,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
        if (isEyedropper)
          Positioned(
            bottom: 6,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Tap image to sample color',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.sync_rounded, size: 14, color: Colors.white),
            tooltip: 'Change Image',
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              minimumSize: const Size(22, 22),
            ),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Future<void> _ensureDecoded(File file) async {
    if (_lastLoadedFile?.path == file.path && _decodedImage != null) return;
    _lastLoadedFile = file;
    try {
      final bytes = await file.readAsBytes();
      _decodedImage = img.decodeImage(bytes);
    } catch (_) {}
  }

  void _samplePixelAt(Offset localOffset) {
    if (_decodedImage == null) return;
    final imgW = _decodedImage!.width;
    final imgH = _decodedImage!.height;
    final normX = (localOffset.dx / _width).clamp(0.0, 1.0);
    final normY = (localOffset.dy / (_height - 30)).clamp(0.0, 1.0);

    final px = (normX * imgW).round().clamp(0, imgW - 1);
    final py = (normY * imgH).round().clamp(0, imgH - 1);

    final pixel = _decodedImage!.getPixel(px, py);
    final sampledColor = Color.fromARGB(255, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());

    SoundEffectService.instance.playPop();
    ref.read(activeColorProvider.notifier).setColor(sampledColor);
    ref.read(isReferenceEyedropperActiveProvider.notifier).state = false;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      SoundEffectService.instance.playPop();
      ref.read(referenceImageProvider.notifier).state = File(picked.path);
    }
  }
}
