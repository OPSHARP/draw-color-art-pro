import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'sound_generator.dart';

enum AmbientSoundscape {
  rain('Gentle Rain', 'Soft rain on leaves with distant calm'),
  pencilASMR('Pencil ASMR', 'Continuous rhythmic sketching & shading on paper'),
  campfire('Campfire Hearth', 'Cozy warm crackle and deep amber glow'),
  lofiChill('Lo-Fi Chill Drone', 'Mellow harmonic ambient chord progression'),
  forestBreeze('Forest Breeze', 'Wind whispering through trees and calm air');

  const AmbientSoundscape(this.title, this.description);
  final String title;
  final String description;
}

/// Service managing procedural ambient relaxation soundscapes for coloring & drawing.
class AmbientSoundService {
  AmbientSoundService._();
  static final AmbientSoundService instance = AmbientSoundService._();

  AudioPlayer? _player;
  AmbientSoundscape? _currentSoundscape;
  bool _isPlaying = false;
  double _volume = 0.6;
  final Map<AmbientSoundscape, Uint8List> _soundscapeBuffers = {};

  bool get isPlaying => _isPlaying;
  AmbientSoundscape? get currentSoundscape => _currentSoundscape;
  double get volume => _volume;

  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<AmbientSoundscape?> currentSoundscapeNotifier =
      ValueNotifier<AmbientSoundscape?>(null);

  Future<void> init() async {
    try {
      _player = AudioPlayer();
      await _player?.setReleaseMode(ReleaseMode.loop);
      await _player?.setVolume(_volume);
    } catch (_) {}
  }

  Future<void> playSoundscape(AmbientSoundscape soundscape) async {
    try {
      if (_player == null) await init();

      final bytes = _soundscapeBuffers[soundscape] ?? _synthesizeSoundscape(soundscape);
      _soundscapeBuffers[soundscape] = bytes;

      await _player?.stop();
      await _player?.setReleaseMode(ReleaseMode.loop);
      await _player?.setVolume(_volume);
      await _player?.play(BytesSource(bytes));

      _currentSoundscape = soundscape;
      _isPlaying = true;
      isPlayingNotifier.value = true;
      currentSoundscapeNotifier.value = soundscape;
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
      _isPlaying = false;
      isPlayingNotifier.value = false;
    } catch (_) {}
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    try {
      await _player?.setVolume(_volume);
    } catch (_) {}
  }

  /// Synthesizes a seamless 3.5-second loopable WAV buffer of the soundscape.
  Uint8List _synthesizeSoundscape(AmbientSoundscape type) {
    const sampleRate = SoundGenerator.sampleRate;
    const durationSeconds = 3.5;
    final numSamples = (sampleRate * durationSeconds).round();

    // Create 44-byte WAV header
    final result = Uint8List(44 + numSamples * 2);
    // Write standard header manually
    const byteRate = sampleRate * 2;
    final dataSize = numSamples * 2;
    final fileSize = 36 + dataSize;
    final headerData = ByteData(44);
    headerData.setUint8(0, 0x52); headerData.setUint8(1, 0x49); headerData.setUint8(2, 0x46); headerData.setUint8(3, 0x46);
    headerData.setUint32(4, fileSize, Endian.little);
    headerData.setUint8(8, 0x57); headerData.setUint8(9, 0x41); headerData.setUint8(10, 0x56); headerData.setUint8(11, 0x45);
    headerData.setUint8(12, 0x66); headerData.setUint8(13, 0x6D); headerData.setUint8(14, 0x74); headerData.setUint8(15, 0x20);
    headerData.setUint32(16, 16, Endian.little);
    headerData.setUint16(20, 1, Endian.little);
    headerData.setUint16(22, 1, Endian.little);
    headerData.setUint32(24, sampleRate, Endian.little);
    headerData.setUint32(28, byteRate, Endian.little);
    headerData.setUint16(32, 2, Endian.little);
    headerData.setUint16(34, 16, Endian.little);
    headerData.setUint8(36, 0x64); headerData.setUint8(37, 0x61); headerData.setUint8(38, 0x74); headerData.setUint8(39, 0x61);
    headerData.setUint32(40, dataSize, Endian.little);
    result.setRange(0, 44, headerData.buffer.asUint8List());

    final samples = ByteData.sublistView(result, 44);
    final random = Random(42);

    switch (type) {
      case AmbientSoundscape.rain:
        // Filtered pink noise with micro drop impulses
        double b0 = 0, b1 = 0, b2 = 0;
        for (int i = 0; i < numSamples; i++) {
          final white = (random.nextDouble() * 2 - 1);
          b0 = 0.99765 * b0 + white * 0.0990460;
          b1 = 0.96300 * b1 + white * 0.1345674;
          b2 = 0.57000 * b2 + white * 0.4900000;
          var sample = (b0 + b1 + b2 + white * 0.5362) * 0.14;
          // Random soft drop splatter
          if (random.nextDouble() < 0.003) sample += (random.nextDouble() * 0.35);
          final pcm = (sample.clamp(-1.0, 1.0) * 32767).round();
          samples.setInt16(i * 2, pcm, Endian.little);
        }
        break;

      case AmbientSoundscape.pencilASMR:
        // Rhythmic friction textured noise
        for (int i = 0; i < numSamples; i++) {
          final t = i / sampleRate;
          // Periodic stroke rhythm (~2.2 Hz)
          final strokeMod = 0.3 + 0.7 * pow(sin(t * 2.2 * 2 * pi).abs(), 2.0);
          final noise = (random.nextDouble() * 2 - 1) * 0.35;
          final sample = noise * strokeMod;
          final pcm = (sample.clamp(-1.0, 1.0) * 32767).round();
          samples.setInt16(i * 2, pcm, Endian.little);
        }
        break;

      case AmbientSoundscape.campfire:
        // Low warm rumble with random loud pop crackles
        double rumble = 0;
        for (int i = 0; i < numSamples; i++) {
          final white = (random.nextDouble() * 2 - 1);
          rumble = rumble * 0.94 + white * 0.06;
          var sample = rumble * 1.2;
          // Crackle bursts
          if (random.nextDouble() < 0.0012) {
            sample += (random.nextBool() ? 1 : -1) * (0.4 + random.nextDouble() * 0.4);
          }
          final pcm = (sample.clamp(-1.0, 1.0) * 32767).round();
          samples.setInt16(i * 2, pcm, Endian.little);
        }
        break;

      case AmbientSoundscape.lofiChill:
        // Warm meditative chord drone (C major 7 / Am9 harmonics: 130.8 Hz, 164.8 Hz, 196.0 Hz, 246.9 Hz)
        for (int i = 0; i < numSamples; i++) {
          final t = i / sampleRate;
          final s1 = sin(2 * pi * 130.81 * t) * 0.28;
          final s2 = sin(2 * pi * 164.81 * t) * 0.22;
          final s3 = sin(2 * pi * 196.00 * t) * 0.20;
          final s4 = sin(2 * pi * 246.94 * t) * 0.16;
          final vibrato = sin(2 * pi * 0.8 * t) * 0.05;
          final sample = (s1 + s2 + s3 + s4) * (1.0 + vibrato);
          final pcm = (sample.clamp(-1.0, 1.0) * 32767).round();
          samples.setInt16(i * 2, pcm, Endian.little);
        }
        break;

      case AmbientSoundscape.forestBreeze:
        // Slow-swelling gentle wind breath
        double windState = 0;
        for (int i = 0; i < numSamples; i++) {
          final t = i / sampleRate;
          final swell = 0.5 + 0.5 * sin(2 * pi * 0.4 * t);
          final white = (random.nextDouble() * 2 - 1);
          windState = windState * 0.96 + white * 0.04;
          final sample = windState * 1.5 * swell;
          final pcm = (sample.clamp(-1.0, 1.0) * 32767).round();
          samples.setInt16(i * 2, pcm, Endian.little);
        }
        break;
    }

    return result;
  }
}
