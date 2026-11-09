import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:draw_color_art_pro/features/canvas/models/drawing_guides.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/features/canvas/models/tools.dart';
import 'package:draw_color_art_pro/features/colors/services/color_harmony_service.dart';
import 'package:draw_color_art_pro/rendering/engine/quick_shape_recognizer.dart';
import 'package:draw_color_art_pro/rendering/engine/stroke_renderer.dart';
import 'package:draw_color_art_pro/core/constants/app_version.dart';
import 'package:draw_color_art_pro/core/services/display_service.dart';
import 'package:draw_color_art_pro/core/ads/ad_service.dart';

void main() {
  group('QuickShape Auto-Shape Recognizer Tests', () {
    test('Recognizes straight horizontal line', () {
      final points = <StrokePoint>[
        for (int i = 0; i <= 20; i++)
          StrokePoint(x: 10.0 + i * 10.0, y: 50.0 + (i % 2 == 0 ? 0.5 : -0.5)),
      ];

      final result = QuickShapeRecognizer.recognize(points);
      expect(result, isNotNull);
      expect(result!.shapeType, equals(ShapeType.line));
      expect(result.points.length, equals(2));
    });

    test('Recognizes straight diagonal line', () {
      final points = <StrokePoint>[
        for (int i = 0; i <= 20; i++)
          StrokePoint(x: 10.0 + i * 8.0, y: 10.0 + i * 8.0),
      ];

      final result = QuickShapeRecognizer.recognize(points);
      expect(result, isNotNull);
      expect(result!.shapeType, equals(ShapeType.line));
    });

    test('Recognizes circle with circular points', () {
      const cx = 150.0;
      const cy = 150.0;
      const r = 50.0;
      final points = <StrokePoint>[
        for (int i = 0; i <= 36; i++)
          StrokePoint(
            x: cx + r * cos(i * 10 * pi / 180),
            y: cy + r * sin(i * 10 * pi / 180),
          ),
      ];

      final result = QuickShapeRecognizer.recognize(points);
      expect(result, isNotNull);
      expect(result!.shapeType, equals(ShapeType.circle));
      expect(result.isClosed, isTrue);
    });

    test('Recognizes ellipse with oval aspect ratio', () {
      const cx = 200.0;
      const cy = 150.0;
      const rx = 80.0;
      const ry = 40.0;
      final points = <StrokePoint>[
        for (int i = 0; i <= 36; i++)
          StrokePoint(
            x: cx + rx * cos(i * 10 * pi / 180),
            y: cy + ry * sin(i * 10 * pi / 180),
          ),
      ];

      final result = QuickShapeRecognizer.recognize(points);
      expect(result, isNotNull);
      // Oval/ellipse shapes map to ShapeType.circle with rectangular aspect ratio
      expect(result!.shapeType, equals(ShapeType.circle));
    });
  });

  group('Streamline Brush Stabilizer Tests', () {
    test('Streamline lags point towards previous point smoothly', () {
      final history = [
        const StrokePoint(x: 10.0, y: 10.0, pressure: 1.0),
      ];
      const rawTarget = StrokePoint(x: 50.0, y: 50.0, pressure: 1.0);

      final stabilizedLow = StrokeRenderer.stabilize(
        rawTarget,
        history,
        StabilizationMode.off,
        streamline: 0.1,
      );

      final stabilizedHigh = StrokeRenderer.stabilize(
        rawTarget,
        history,
        StabilizationMode.off,
        streamline: 0.9,
      );

      // Higher streamline should stay closer to history.last (more rope lag)
      expect((stabilizedHigh.offset - history.first.offset).distance,
          lessThan((stabilizedLow.offset - history.first.offset).distance));
    });

    test('BrushPreset stores and serializes streamline correctly', () {
      final preset = BrushPreset(
        name: 'Inking Pen',
        category: BrushCategory.ink,
        streamline: 0.65,
      );
      expect(preset.streamline, equals(0.65));

      final json = preset.toJson();
      expect(json['streamline'], equals(0.65));

      final copy = preset.copyWith(streamline: 0.85);
      expect(copy.streamline, equals(0.85));

      final fromJson = BrushPreset.fromJson(json);
      expect(fromJson.streamline, equals(0.65));
    });
  });

  group('Color Harmony Engine Tests', () {
    test('Computes complementary color with 180 degree hue shift', () {
      const pureRed = Color(0xFFFF0000); // Hue = 0
      final harmonies = ColorHarmonyService.getHarmonies(
        pureRed,
        ColorHarmonyType.complementary,
      );
      expect(harmonies.length, equals(4));
      // Complement of pure red (hue 0) is pure cyan (hue 180)
      final compHsv = HSVColor.fromColor(harmonies[1]);
      expect(compHsv.hue, closeTo(180.0, 1.0));
    });

    test('Computes triadic colors with 120 and 240 degree hue shifts', () {
      const pureRed = Color(0xFFFF0000);
      final harmonies = ColorHarmonyService.getHarmonies(
        pureRed,
        ColorHarmonyType.triadic,
      );
      expect(harmonies.length, equals(4));
      final h1 = HSVColor.fromColor(harmonies[1]).hue;
      final h2 = HSVColor.fromColor(harmonies[2]).hue;
      expect(h1, closeTo(120.0, 1.0));
      expect(h2, closeTo(240.0, 1.0));
    });

    test('Computes analogous and tetradic color palettes', () {
      const baseBlue = Color(0xFF0055FF);
      final analogous = ColorHarmonyService.getHarmonies(
        baseBlue,
        ColorHarmonyType.analogous,
      );
      expect(analogous.length, equals(5));

      final tetradic = ColorHarmonyService.getHarmonies(
        baseBlue,
        ColorHarmonyType.tetradic,
      );
      expect(tetradic.length, equals(4));
    });
  });

  group('3-Point Perspective Guides Tests', () {
    test('DrawingGuideConfig supports 3P perspective and snapToGuide', () {
      const config = DrawingGuideConfig(
        type: DrawingGuideType.perspective3P,
        horizonRatio: 0.45,
        vp1Ratio: 0.1,
        vp2Ratio: 0.9,
        vp3Ratio: 0.15,
        snapToGuide: true,
      );
      expect(config.type, equals(DrawingGuideType.perspective3P));
      expect(config.vp3Ratio, equals(0.15));
      expect(config.snapToGuide, isTrue);

      final copy = config.copyWith(snapToGuide: false);
      expect(copy.snapToGuide, isFalse);
    });
  });

  group('All 26 Drawing Tools Enum Verification', () {
    test('Every drawing tool has valid label and representation', () {
      expect(DrawingTool.values.length, equals(26));
      for (final tool in DrawingTool.values) {
        expect(tool.label.isNotEmpty, isTrue);
      }
      expect(DrawingTool.values.contains(DrawingTool.brush), isTrue);
      expect(DrawingTool.values.contains(DrawingTool.smudge), isTrue);
      expect(DrawingTool.values.contains(DrawingTool.blur), isTrue);
      expect(DrawingTool.values.contains(DrawingTool.highlighter), isTrue);
      expect(DrawingTool.values.contains(DrawingTool.rainbow), isTrue);
    });
  });

  group('AppVersion Metadata Tests', () {
    test('AppVersion contains valid version name and build number', () {
      expect(AppVersion.appName, equals('Draw Color Art Pro'));
      expect(AppVersion.version, equals('1.0.2'));
      expect(AppVersion.buildNumber, equals(3));
      expect(AppVersion.fullVersion, equals('v1.0.2 (3)'));
      expect(AppVersion.versionWithBuild, equals('Version 1.0.2 (Build 3)'));
    });
  });

  group('DisplayRefreshRateService Tests', () {
    test('Default fallback and service properties initialize safely', () async {
      final service = DisplayRefreshRateService.instance;
      expect(service.currentFps, greaterThanOrEqualTo(60.0));
      expect(service.supportedRates, isNotEmpty);
      expect(service.supportedRates.first, greaterThanOrEqualTo(60.0));
    });
  });

  group('AdService Responsive & Cooldown Policy Tests', () {
    test('AdService live unit IDs are configured and non-empty', () {
      expect(AdService.bannerAdUnitId, isNotEmpty);
      expect(AdService.interstitialAdUnitId, isNotEmpty);
      expect(AdService.appOpenAdUnitId, isNotEmpty);
    });

    test('AdService live banner ID matches user configured ID', () {
      expect(AdService.liveBannerAdUnitId, equals('ca-app-pub-6089131009548737/9721683513'));
      expect(AdService.liveInterstitialAdUnitId, equals('ca-app-pub-6089131009548737/6240680067'));
      expect(AdService.liveAppOpenAdUnitId, equals('ca-app-pub-6089131009548737/3598953287'));
    });
  });

  group('Direct Element Drag & Translation Tests', () {
    test('Stroke points translate correctly by delta offset', () {
      final stroke = Stroke(
        points: const [
          StrokePoint(x: 100, y: 150, pressure: 1.0, timestamp: 0),
          StrokePoint(x: 120, y: 170, pressure: 1.0, timestamp: 10),
        ],
        color: Colors.black,
        brush: BrushPreset(
          name: 'Pen',
          category: BrushCategory.sketching,
          size: 10,
          opacity: 1.0,
        ),
      );

      const delta = Offset(25, -15);
      final translatedPts = stroke.points
          .map((p) => p.copyWith(x: p.x + delta.dx, y: p.y + delta.dy))
          .toList();
      final movedStroke = stroke.copyWith(points: translatedPts);

      expect(movedStroke.points[0].x, equals(125.0));
      expect(movedStroke.points[0].y, equals(135.0));
      expect(movedStroke.points[1].x, equals(145.0));
      expect(movedStroke.points[1].y, equals(155.0));
    });
  });
}

