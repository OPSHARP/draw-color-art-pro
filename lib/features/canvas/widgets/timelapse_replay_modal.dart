import 'dart:async';
import 'package:flutter/material.dart';
import '../models/canvas_document.dart';
import '../models/stroke.dart';
import '../../../rendering/engine/stroke_renderer.dart';
import '../../../core/audio/sound_effect_service.dart';
import '../../../core/constants/design_tokens.dart';

/// Modal dialog that replays the artwork's creation stroke-by-stroke.
class TimelapseReplayModal extends StatefulWidget {
  const TimelapseReplayModal({super.key, required this.document});

  final CanvasDocument document;

  static void show(BuildContext context, CanvasDocument document) {
    SoundEffectService.instance.playPop();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => TimelapseReplayModal(document: document),
    );
  }

  @override
  State<TimelapseReplayModal> createState() => _TimelapseReplayModalState();
}

class _TimelapseReplayModalState extends State<TimelapseReplayModal> {
  late final List<Stroke> _allStrokes;
  int _currentStrokeIndex = 0;
  bool _isPlaying = false;
  double _speedMultiplier = 2.0;
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    // Gather all strokes across all layers in chronological order
    _allStrokes = [];
    for (final layer in widget.document.layers) {
      _allStrokes.addAll(layer.strokes);
    }
    // Start at beginning or halfway if long
    _currentStrokeIndex = _allStrokes.isNotEmpty ? 1 : 0;
    _startPlayback();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    if (_allStrokes.isEmpty) return;

    setState(() => _isPlaying = true);

    // Speed calculation: base tick interval
    final intervalMs = (80 / _speedMultiplier).round().clamp(10, 300);

    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_currentStrokeIndex >= _allStrokes.length) {
        timer.cancel();
        setState(() => _isPlaying = false);
        SoundEffectService.instance.playCelebration();
        return;
      }

      setState(() {
        _currentStrokeIndex++;
      });

      // Play soft ASMR audio tick occasionally
      if (_currentStrokeIndex % 4 == 0) {
        SoundEffectService.instance.playBrush();
      }
    });
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    SoundEffectService.instance.playPop();
    setState(() => _isPlaying = false);
  }

  void _restartPlayback() {
    _playbackTimer?.cancel();
    SoundEffectService.instance.playWhoosh();
    setState(() {
      _currentStrokeIndex = 0;
    });
    _startPlayback();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalStrokes = _allStrokes.length;
    final progress = totalStrokes > 0 ? _currentStrokeIndex / totalStrokes : 1.0;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
          child: Column(
            children: [
              // ── Top Header ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.movie_creation_rounded,
                      color: Color(0xFF6C5CE7),
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Timelapse Speedpaint Replay',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        SoundEffectService.instance.playPop();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── Canvas Preview Replay Area ──
              Expanded(
                child: Container(
                  color: Colors.black12,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: widget.document.width / widget.document.height,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.document.backgroundColor,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _TimelapsePainter(
                            strokes: _allStrokes.take(_currentStrokeIndex).toList(),
                            docWidth: widget.document.width.toDouble(),
                            docHeight: widget.document.height.toDouble(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),

              // ── Player Controls ──
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Slider scrubber
                    Row(
                      children: [
                        Text(
                          'Stroke $_currentStrokeIndex / $totalStrokes',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: totalStrokes > 0
                          ? _currentStrokeIndex.toDouble().clamp(0.0, totalStrokes.toDouble())
                          : 0.0,
                      min: 0,
                      max: totalStrokes > 0 ? totalStrokes.toDouble() : 1.0,
                      onChanged: (val) {
                        _pausePlayback();
                        setState(() {
                          _currentStrokeIndex = val.round();
                        });
                      },
                    ),

                    // Play / Pause / Speed buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Restart
                        IconButton(
                          icon: const Icon(Icons.replay_rounded),
                          tooltip: 'Restart',
                          onPressed: _restartPlayback,
                        ),
                        const SizedBox(width: AppSpacing.sm),

                        // Play / Pause FAB
                        FloatingActionButton.small(
                          backgroundColor: theme.colorScheme.primary,
                          onPressed: () {
                            if (_isPlaying) {
                              _pausePlayback();
                            } else {
                              if (_currentStrokeIndex >= totalStrokes) {
                                _currentStrokeIndex = 0;
                              }
                              _startPlayback();
                            }
                          },
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),

                        // Speed buttons
                        Wrap(
                          spacing: 4,
                          children: [1.0, 2.0, 5.0, 10.0].map((speed) {
                            final isSelected = _speedMultiplier == speed;
                            return ChoiceChip(
                              label: Text('${speed.toInt()}x'),
                              selected: isSelected,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : null,
                              ),
                              onSelected: (_) {
                                SoundEffectService.instance.playPop();
                                setState(() {
                                  _speedMultiplier = speed;
                                });
                                if (_isPlaying) {
                                  _startPlayback();
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
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

class _TimelapsePainter extends CustomPainter {
  _TimelapsePainter({
    required this.strokes,
    required this.docWidth,
    required this.docHeight,
  });

  final List<Stroke> strokes;
  final double docWidth;
  final double docHeight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Scale canvas to fit container
    final scaleX = size.width / docWidth;
    final scaleY = size.height / docHeight;
    canvas.scale(scaleX, scaleY);

    for (final stroke in strokes) {
      StrokeRenderer.renderStroke(canvas, stroke);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TimelapsePainter oldDelegate) {
    return strokes.length != oldDelegate.strokes.length;
  }
}
