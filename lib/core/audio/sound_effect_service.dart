import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_generator.dart';

enum SoundType { pop, pencil, brush, eraser, whoosh, celebration }

/// Sound Effect & ASMR Audio Manager.
///
/// Provides zero-latency, royalty-free sound effects for drawing and UI interactions.
class SoundEffectService {
  SoundEffectService._();
  static final SoundEffectService instance = SoundEffectService._();

  static const String _sfxKey = 'settings_sfx_enabled';
  bool _sfxEnabled = true;
  double _volume = 0.8;

  AudioPlayer? _player;
  final Map<SoundType, Uint8List> _soundCache = {};

  bool get isSfxEnabled => _sfxEnabled;
  double get volume => _volume;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sfxEnabled = prefs.getBool(_sfxKey) ?? true;

      // Pre-synthesize sound buffers in memory
      _soundCache[SoundType.pop] = SoundGenerator.generatePop();
      _soundCache[SoundType.pencil] = SoundGenerator.generatePencilStroke();
      _soundCache[SoundType.brush] = SoundGenerator.generateBrushSwoosh();
      _soundCache[SoundType.eraser] = SoundGenerator.generateEraser();
      _soundCache[SoundType.whoosh] = SoundGenerator.generateWhoosh();
      _soundCache[SoundType.celebration] = SoundGenerator.generateCelebrationChime();

      _player = AudioPlayer();
      await _player?.setVolume(_volume);
    } catch (_) {
      // Audio initialization skipped in unsupported environments
    }
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _sfxEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sfxKey, enabled);
    } catch (_) {}
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _player?.setVolume(_volume);
    } catch (_) {}
  }

  Future<void> play(SoundType type, {bool triggerHaptic = true}) async {
    if (!_sfxEnabled) return;

    if (triggerHaptic) {
      try {
        switch (type) {
          case SoundType.pop:
            HapticFeedback.selectionClick();
            break;
          case SoundType.pencil:
          case SoundType.brush:
            HapticFeedback.lightImpact();
            break;
          case SoundType.eraser:
            HapticFeedback.mediumImpact();
            break;
          case SoundType.whoosh:
            HapticFeedback.lightImpact();
            break;
          case SoundType.celebration:
            HapticFeedback.heavyImpact();
            break;
        }
      } catch (_) {}
    }

    try {
      final bytes = _soundCache[type] ?? _generateOnDemand(type);
      if (_player != null) {
        await _player!.play(BytesSource(bytes));
      }
    } catch (_) {
      // Non-critical if audio device unavailable in background/test
    }
  }

  Uint8List _generateOnDemand(SoundType type) {
    final bytes = switch (type) {
      SoundType.pop => SoundGenerator.generatePop(),
      SoundType.pencil => SoundGenerator.generatePencilStroke(),
      SoundType.brush => SoundGenerator.generateBrushSwoosh(),
      SoundType.eraser => SoundGenerator.generateEraser(),
      SoundType.whoosh => SoundGenerator.generateWhoosh(),
      SoundType.celebration => SoundGenerator.generateCelebrationChime(),
    };
    _soundCache[type] = bytes;
    return bytes;
  }

  void playPop() => play(SoundType.pop);
  void playPencil() => play(SoundType.pencil);
  void playBrush() => play(SoundType.brush);
  void playEraser() => play(SoundType.eraser);
  void playUndo() => play(SoundType.whoosh);
  void playWhoosh() => play(SoundType.whoosh);
  void playCelebration() => play(SoundType.celebration);

  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
