import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/canvas_providers.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// 2D Frame-by-frame Flipbook Animation Timeline with live playback and onion skinning.
class AnimationTimelineModal extends ConsumerStatefulWidget {
  const AnimationTimelineModal({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    SoundEffectService.instance.playPop();

    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AnimationTimelineModal(),
    );
  }

  @override
  ConsumerState<AnimationTimelineModal> createState() => _AnimationTimelineModalState();
}

class _AnimationTimelineModalState extends ConsumerState<AnimationTimelineModal> {
  bool _isPlaying = false;
  int _fps = 8;
  Timer? _playbackTimer;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startPlayback();
      } else {
        _playbackTimer?.cancel();
      }
    });
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    final intervalMs = (1000 / _fps).round();
    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final doc = ref.read(canvasDocumentProvider);
      if (doc.layers.isEmpty) return;

      final nextIndex = (doc.activeLayerIndex + 1) % doc.layers.length;
      ref.read(canvasDocumentProvider.notifier).setActiveLayer(nextIndex);
    });
  }

  void _onFpsChanged(int newFps) {
    setState(() {
      _fps = newFps;
      if (_isPlaying) {
        _startPlayback();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(canvasDocumentProvider);
    final onionSkin = ref.watch(onionSkinEnabledProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle Bar ──
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: IOSColors.brandPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.play_rectangle_fill,
                  size: 18,
                  color: IOSColors.brandPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flipbook Animation Timeline',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${doc.layers.length} Frames · $_fps FPS',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Onion skin quick toggle
              FilterChip(
                label: const Text('Onion Skin', style: TextStyle(fontSize: 11)),
                selected: onionSkin,
                selectedColor: IOSColors.brandPrimary.withValues(alpha: 0.25),
                checkmarkColor: IOSColors.brandPrimary,
                onSelected: (val) {
                  SoundEffectService.instance.playPop();
                  ref.read(onionSkinEnabledProvider.notifier).state = val;
                },
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
                onPressed: () => Navigator.pop(context),
                child: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey, size: 24),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Frame Scrubber Carousel ──
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: doc.layers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final isCurrent = doc.activeLayerIndex == idx;
                final layer = doc.layers[idx];

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    SoundEffectService.instance.playPop();
                    ref.read(canvasDocumentProvider.notifier).setActiveLayer(idx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 58,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF28283E) : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent
                            ? IOSColors.brandPrimary
                            : (isDark ? Colors.white12 : Colors.black12),
                        width: isCurrent ? 2.2 : 0.8,
                      ),
                      boxShadow: [
                        if (isCurrent)
                          BoxShadow(
                            color: IOSColors.brandPrimary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '#${idx + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? IOSColors.brandPrimary
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        Icon(
                          layer.strokes.isNotEmpty
                              ? CupertinoIcons.paintbrush_fill
                              : CupertinoIcons.doc,
                          size: 16,
                          color: isCurrent
                              ? IOSColors.brandPrimary
                              : (isDark ? Colors.white38 : Colors.black38),
                        ),
                        Text(
                          '${layer.strokes.length} strk',
                          style: TextStyle(
                            fontSize: 8,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // ── Playback Controls & Frame Actions ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous Frame
              IconButton(
                icon: const Icon(CupertinoIcons.backward_fill, size: 20),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final prev = (doc.activeLayerIndex - 1 + doc.layers.length) % doc.layers.length;
                  ref.read(canvasDocumentProvider.notifier).setActiveLayer(prev);
                },
              ),
              const SizedBox(width: 8),

              // Play / Pause Primary Button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                color: IOSColors.brandPrimary,
                borderRadius: BorderRadius.circular(24),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  SoundEffectService.instance.playPop();
                  _togglePlayback();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isPlaying ? 'Pause' : 'Play Loop',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Next Frame
              IconButton(
                icon: const Icon(CupertinoIcons.forward_fill, size: 20),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final next = (doc.activeLayerIndex + 1) % doc.layers.length;
                  ref.read(canvasDocumentProvider.notifier).setActiveLayer(next);
                },
              ),

              const Spacer(),

              // + Add Frame
              IconButton.filledTonal(
                icon: const Icon(CupertinoIcons.plus, size: 18),
                tooltip: 'Add Frame',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  SoundEffectService.instance.playPop();
                  ref.read(canvasDocumentProvider.notifier).addLayer(
                    name: 'Frame ${doc.layers.length + 1}',
                  );
                },
              ),
              const SizedBox(width: 4),

              // Duplicate Frame
              IconButton.filledTonal(
                icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
                tooltip: 'Duplicate Frame',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  SoundEffectService.instance.playPop();
                  ref.read(canvasDocumentProvider.notifier).duplicateLayer(doc.activeLayerIndex);
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Speed (FPS) Slider ──
          Row(
            children: [
              Text(
                'Speed: $_fps FPS',
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Slider(
                  value: _fps.toDouble(),
                  min: 1.0,
                  max: 24.0,
                  divisions: 23,
                  onChanged: (val) => _onFpsChanged(val.round()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
