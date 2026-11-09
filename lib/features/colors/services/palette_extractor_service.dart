import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ExtractedPalette {
  const ExtractedPalette({
    required this.name,
    required this.colors,
    this.sourcePath,
  });

  final String name;
  final List<Color> colors;
  final String? sourcePath;
}

class PaletteExtractorService {
  PaletteExtractorService._();
  static final PaletteExtractorService instance = PaletteExtractorService._();

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera and extract dominant color palette.
  Future<ExtractedPalette?> pickAndExtract({
    ImageSource source = ImageSource.gallery,
    int maxColors = 8,
  }) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return null;

      final bytes = await File(file.path).readAsBytes();
      final colors = await extractFromBytes(bytes, maxColors: maxColors);
      final filename = file.name.split('.').first;
      final paletteName = filename.length > 16 ? filename.substring(0, 16) : filename;

      return ExtractedPalette(
        name: paletteName.isNotEmpty ? paletteName : 'Photo Palette',
        colors: colors,
        sourcePath: file.path,
      );
    } catch (_) {
      return null;
    }
  }

  /// Extract dominant harmonious colors from raw image bytes.
  Future<List<Color>> extractFromBytes(Uint8List bytes, {int maxColors = 8}) async {
    final image = img.decodeImage(bytes);
    if (image == null) {
      return _fallbackPalette();
    }

    // Downscale for fast, efficient color analysis
    final resized = img.copyResize(image, width: 64, height: 64);
    final List<Color> samples = [];

    for (int y = 0; y < resized.height; y += 2) {
      for (int x = 0; x < resized.width; x += 2) {
        final pixel = resized.getPixel(x, y);
        final a = pixel.a.toInt();
        if (a < 128) continue; // Skip transparent pixels

        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Skip nearly pure white or nearly pure black to prioritize aesthetic tones
        final luminance = (0.299 * r + 0.587 * g + 0.114 * b);
        if (luminance > 250 || luminance < 10) continue;

        samples.add(Color.fromARGB(255, r, g, b));
      }
    }

    if (samples.isEmpty) {
      return _fallbackPalette();
    }

    // Cluster colors by chromatic distance
    final List<_ColorCluster> clusters = [];
    for (final color in samples) {
      bool matched = false;
      for (final cluster in clusters) {
        if (cluster.isClose(color, tolerance: 48.0)) {
          cluster.add(color);
          matched = true;
          break;
        }
      }
      if (!matched && clusters.length < 64) {
        clusters.add(_ColorCluster(color));
      }
    }

    // Sort clusters by count (prominence) and vibrancy
    clusters.sort((a, b) {
      final aScore = a.count * (0.6 + a.saturation * 0.4);
      final bScore = b.count * (0.6 + b.saturation * 0.4);
      return bScore.compareTo(aScore);
    });

    final extracted = clusters.take(maxColors).map((c) => c.averageColor).toList();

    if (extracted.isEmpty) {
      return _fallbackPalette();
    }

    // Ensure we have at least 4 colors
    while (extracted.length < 6 && extracted.isNotEmpty) {
      final last = extracted.last;
      final hsv = HSVColor.fromColor(last);
      final varied = HSVColor.fromAHSV(
        1.0,
        (hsv.hue + 30) % 360,
        (hsv.saturation * 0.8).clamp(0.1, 1.0),
        (hsv.value * 0.9).clamp(0.1, 1.0),
      ).toColor();
      extracted.add(varied);
    }

    return extracted.take(maxColors).toList();
  }

  static List<Color> _fallbackPalette() => const [
    Color(0xFFE63946),
    Color(0xFFF1FAEE),
    Color(0xFFA8DADC),
    Color(0xFF457B9D),
    Color(0xFF1D3557),
    Color(0xFFFFB703),
  ];
}

class _ColorCluster {
  _ColorCluster(Color initial)
      : averageColor = initial,
        count = 1,
        _totalR = initial.r.toInt(),
        _totalG = initial.g.toInt(),
        _totalB = initial.b.toInt(),
        saturation = HSVColor.fromColor(initial).saturation;

  Color averageColor;
  int count;
  int _totalR;
  int _totalG;
  int _totalB;
  double saturation;

  bool isClose(Color other, {required double tolerance}) {
    final dr = averageColor.r.toInt() - other.r.toInt();
    final dg = averageColor.g.toInt() - other.g.toInt();
    final db = averageColor.b.toInt() - other.b.toInt();
    final dist = sqrt(dr * dr + dg * dg + db * db);
    return dist < tolerance;
  }

  void add(Color color) {
    count++;
    _totalR += color.r.toInt();
    _totalG += color.g.toInt();
    _totalB += color.b.toInt();
    final r = (_totalR / count).round().clamp(0, 255);
    final g = (_totalG / count).round().clamp(0, 255);
    final b = (_totalB / count).round().clamp(0, 255);
    averageColor = Color.fromARGB(255, r, g, b);
    saturation = HSVColor.fromColor(averageColor).saturation;
  }
}
