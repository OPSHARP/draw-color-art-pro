import 'dart:math';
import 'dart:typed_data';

/// Procedural synthesizer that generates clean, royalty-free 16-bit PCM WAV audio.
class SoundGenerator {
  static const int sampleRate = 22050;

  /// Creates a standard 44-byte WAV header for mono 16-bit PCM.
  static Uint8List _createWavHeader(int numSamples) {
    const byteRate = sampleRate * 2; // 1 channel * 2 bytes per sample
    final dataSize = numSamples * 2;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);
    // RIFF chunk descriptor
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);  // 'W'
    header.setUint8(9, 0x41);  // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'

    // fmt sub-chunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk1Size
    header.setUint16(20, 1, Endian.little);  // AudioFormat (PCM = 1)
    header.setUint16(22, 1, Endian.little);  // NumChannels (Mono = 1)
    header.setUint32(24, sampleRate, Endian.little); // SampleRate
    header.setUint32(28, byteRate, Endian.little);   // ByteRate
    header.setUint16(32, 2, Endian.little);  // BlockAlign
    header.setUint16(34, 16, Endian.little); // BitsPerSample

    // data sub-chunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, dataSize, Endian.little);

    return header.buffer.asUint8List();
  }

  /// Satisfying UI click / tap pop (e.g. tool selection, button press)
  static Uint8List generatePop() {
    const durationMs = 45;
    final numSamples = (sampleRate * (durationMs / 1000)).round();
    final header = _createWavHeader(numSamples);
    final data = ByteData(numSamples * 2);

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      // Frequency drop from 750 Hz down to 180 Hz
      final freq = 750.0 - 570.0 * t;
      final envelope = exp(-7.0 * t); // Smooth fast exponential decay
      final sampleVal = (sin(2 * pi * freq * (i / sampleRate)) * envelope * 28000).round();
      data.setInt16(i * 2, sampleVal.clamp(-32768, 32767), Endian.little);
    }

    final bytes = BytesBuilder();
    bytes.add(header);
    bytes.add(data.buffer.asUint8List());
    return bytes.toBytes();
  }

  /// Gentle graphite pencil drawing scratch ASMR
  static Uint8List generatePencilStroke() {
    const durationMs = 120;
    final numSamples = (sampleRate * (durationMs / 1000)).round();
    final header = _createWavHeader(numSamples);
    final data = ByteData(numSamples * 2);
    final random = Random(42);

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      // Parabolic attack and decay envelope
      final envelope = sin(pi * t) * (1.0 - 0.3 * t);
      // Filtered noise with slight tonal resonance
      final noise = (random.nextDouble() * 2 - 1);
      final tone = sin(2 * pi * 800 * (i / sampleRate)) * 0.2;
      final sampleVal = ((noise * 0.8 + tone) * envelope * 12000).round();
      data.setInt16(i * 2, sampleVal.clamp(-32768, 32767), Endian.little);
    }

    final bytes = BytesBuilder();
    bytes.add(header);
    bytes.add(data.buffer.asUint8List());
    return bytes.toBytes();
  }

  /// Soft watercolor/brush swoosh
  static Uint8List generateBrushSwoosh() {
    const durationMs = 160;
    final numSamples = (sampleRate * (durationMs / 1000)).round();
    final header = _createWavHeader(numSamples);
    final data = ByteData(numSamples * 2);
    final random = Random(123);

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final envelope = sin(pi * t);
      // Soft low-frequency pink-ish noise
      final noise = (random.nextDouble() * 2 - 1);
      final sub = sin(2 * pi * 240 * (i / sampleRate)) * 0.4;
      final sampleVal = ((noise * 0.6 + sub) * envelope * 14000).round();
      data.setInt16(i * 2, sampleVal.clamp(-32768, 32767), Endian.little);
    }

    final bytes = BytesBuilder();
    bytes.add(header);
    bytes.add(data.buffer.asUint8List());
    return bytes.toBytes();
  }

  /// Rubber eraser friction sound
  static Uint8List generateEraser() {
    const durationMs = 100;
    final numSamples = (sampleRate * (durationMs / 1000)).round();
    final header = _createWavHeader(numSamples);
    final data = ByteData(numSamples * 2);
    final random = Random(999);

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final envelope = sin(pi * t);
      final noise = (random.nextDouble() * 2 - 1);
      final friction = sin(2 * pi * 320 * (i / sampleRate)) * 0.6;
      final sampleVal = ((noise * 0.5 + friction) * envelope * 15000).round();
      data.setInt16(i * 2, sampleVal.clamp(-32768, 32767), Endian.little);
    }

    final bytes = BytesBuilder();
    bytes.add(header);
    bytes.add(data.buffer.asUint8List());
    return bytes.toBytes();
  }

  /// Rewind / Undo paper flip sound
  static Uint8List generateWhoosh() {
    const durationMs = 90;
    final numSamples = (sampleRate * (durationMs / 1000)).round();
    final header = _createWavHeader(numSamples);
    final data = ByteData(numSamples * 2);

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final freq = 200.0 + 600.0 * (1.0 - t);
      final envelope = sin(pi * t);
      final sampleVal = (sin(2 * pi * freq * (i / sampleRate)) * envelope * 18000).round();
      data.setInt16(i * 2, sampleVal.clamp(-32768, 32767), Endian.little);
    }

    final bytes = BytesBuilder();
    bytes.add(header);
    bytes.add(data.buffer.asUint8List());
    return bytes.toBytes();
  }

  /// Harmonious multi-tone chime for save/export celebration
  static Uint8List generateCelebrationChime() {
    const durationMs = 450;
    final numSamples = (sampleRate * (durationMs / 1000)).round();
    final header = _createWavHeader(numSamples);
    final data = ByteData(numSamples * 2);

    // C5 (523.25 Hz), E5 (659.25 Hz), G5 (783.99 Hz), C6 (1046.5 Hz)
    const notes = [523.25, 659.25, 783.99, 1046.5];

    for (int i = 0; i < numSamples; i++) {
      final t = i / numSamples;
      final envelope = exp(-4.5 * t);
      double signal = 0.0;
      for (int n = 0; n < notes.length; n++) {
        final delay = n * 0.08;
        if (t >= delay) {
          final noteT = t - delay;
          signal += sin(2 * pi * notes[n] * (i / sampleRate)) * exp(-5.0 * noteT);
        }
      }
      final sampleVal = (signal * envelope * 9000).round();
      data.setInt16(i * 2, sampleVal.clamp(-32768, 32767), Endian.little);
    }

    final bytes = BytesBuilder();
    bytes.add(header);
    bytes.add(data.buffer.asUint8List());
    return bytes.toBytes();
  }

  // Aliases for convenience
  static Uint8List generatePencil() => generatePencilStroke();
  static Uint8List generateBrush() => generateBrushSwoosh();
  static Uint8List generateCelebration() => generateCelebrationChime();
}
