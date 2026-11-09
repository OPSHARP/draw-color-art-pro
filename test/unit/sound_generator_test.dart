import 'package:flutter_test/flutter_test.dart';
import 'package:draw_color_art_pro/core/audio/sound_generator.dart';

void main() {
  group('SoundGenerator Procedural WAV Tests', () {
    test('generateWav produces valid 44-byte RIFF WAVE header', () {
      final wavBytes = SoundGenerator.generatePop();

      expect(wavBytes.length, greaterThan(44));

      // Check 'RIFF' ASCII signature (0x52, 0x49, 0x46, 0x46)
      expect(wavBytes[0], equals(0x52));
      expect(wavBytes[1], equals(0x49));
      expect(wavBytes[2], equals(0x46));
      expect(wavBytes[3], equals(0x46));

      // Check 'WAVE' ASCII signature (0x57, 0x41, 0x56, 0x45)
      expect(wavBytes[8], equals(0x57));
      expect(wavBytes[9], equals(0x41));
      expect(wavBytes[10], equals(0x56));
      expect(wavBytes[11], equals(0x45));

      // Check 'fmt ' chunk (0x66, 0x6D, 0x74, 0x20)
      expect(wavBytes[12], equals(0x66));
      expect(wavBytes[13], equals(0x6D));
      expect(wavBytes[14], equals(0x74));
      expect(wavBytes[15], equals(0x20));
    });

    test('generatePop creates non-empty waveform', () {
      final pop = SoundGenerator.generatePop();
      expect(pop.isNotEmpty, isTrue);
    });

    test('generatePencil creates non-empty ASMR scratch waveform', () {
      final pencil = SoundGenerator.generatePencil();
      expect(pencil.isNotEmpty, isTrue);
    });

    test('generateBrush creates non-empty swoosh waveform', () {
      final brush = SoundGenerator.generateBrush();
      expect(brush.isNotEmpty, isTrue);
    });

    test('generateEraser creates non-empty rubber friction waveform', () {
      final eraser = SoundGenerator.generateEraser();
      expect(eraser.isNotEmpty, isTrue);
    });

    test('generateWhoosh creates non-empty undo waveform', () {
      final whoosh = SoundGenerator.generateWhoosh();
      expect(whoosh.isNotEmpty, isTrue);
    });

    test('generateCelebration creates non-empty harmonious chime waveform', () {
      final chime = SoundGenerator.generateCelebration();
      expect(chime.isNotEmpty, isTrue);
    });
  });
}
