import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/features/canvas/models/canvas_document.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/features/canvas/models/tools.dart';
import 'package:draw_color_art_pro/features/canvas/models/symmetry.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';
import 'package:draw_color_art_pro/features/export/services/export_service.dart';
import 'package:draw_color_art_pro/rendering/engine/stroke_renderer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:draw_color_art_pro/features/text/models/font_item.dart';
import 'package:draw_color_art_pro/features/text/services/font_catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Distinct Tool Selection and Configuration Tests', () {
    test('selecting pencil configures distinct sketching brush preset', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      toolNotifier.selectTool(DrawingTool.pencil);
      expect(container.read(activeToolProvider), equals(DrawingTool.pencil));

      final brush = container.read(activeBrushProvider);
      expect(brush.name, equals('Pencil'));
      expect(brush.category, equals(BrushCategory.basic));
      expect(brush.size, equals(3.5));
      expect(brush.hardness, equals(0.85));
      expect(brush.isEraser, isFalse);
    });

    test('selecting pen configures precision inking brush with smooth stabilizer', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      toolNotifier.selectTool(DrawingTool.pen);
      expect(container.read(activeToolProvider), equals(DrawingTool.pen));

      final brush = container.read(activeBrushProvider);
      expect(brush.name, equals('Ink'));
      expect(brush.category, equals(BrushCategory.ink));
      expect(brush.hardness, equals(1.0));
      expect(brush.stabilization, equals(StabilizationMode.smooth));
      expect(brush.size, equals(4.5));
    });

    test('selecting marker configures broad chisel tip with glazing transparency', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      toolNotifier.selectTool(DrawingTool.marker);
      expect(container.read(activeToolProvider), equals(DrawingTool.marker));

      final brush = container.read(activeBrushProvider);
      expect(brush.name, equals('Marker'));
      expect(brush.size, equals(26.0));
      expect(brush.opacity, equals(0.5));
      expect(brush.hardness, equals(0.9));
    });

    test('selecting eraser configures eraser preset with isEraser flag', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      toolNotifier.selectTool(DrawingTool.eraser);
      expect(container.read(activeToolProvider), equals(DrawingTool.eraser));

      final brush = container.read(activeBrushProvider);
      expect(brush.name, equals('Eraser'));
      expect(brush.isEraser, isTrue);
      expect(brush.size, equals(24.0));
    });

    test('selecting brush configures soft painting brush preset', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      // Switch to something else first
      toolNotifier.selectTool(DrawingTool.pencil);
      // Switch back to brush
      toolNotifier.selectTool(DrawingTool.brush);
      expect(container.read(activeToolProvider), equals(DrawingTool.brush));

      final brush = container.read(activeBrushProvider);
      expect(brush.name, equals('Soft Brush'));
      expect(brush.category, equals(BrushCategory.basic));
      expect(brush.size, equals(16.0));
      expect(brush.hardness, equals(0.35));
    });

    test('selecting glow neon configures glow brush with isGlow flag and high hardness', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      toolNotifier.selectTool(DrawingTool.glow);
      expect(container.read(activeToolProvider), equals(DrawingTool.glow));

      final brush = container.read(activeBrushProvider);
      expect(brush.isGlow, isTrue);
      expect(brush.hardness, equals(0.85));
      expect(brush.size, equals(16.0));
    });

    test('selecting spray airbrush configures airbrush preset with isSpray flag', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      toolNotifier.selectTool(DrawingTool.spray);
      expect(container.read(activeToolProvider), equals(DrawingTool.spray));

      final brush = container.read(activeBrushProvider);
      expect(brush.isSpray, isTrue);
      expect(brush.size, equals(36.0));
      expect(brush.flow, equals(0.45));
    });

    test('selecting symmetry tool auto-activates vertical symmetry when disabled', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      expect(container.read(symmetryProvider).isEnabled, isFalse);

      toolNotifier.selectTool(DrawingTool.symmetry);
      expect(container.read(activeToolProvider), equals(DrawingTool.symmetry));
      expect(container.read(symmetryProvider).isEnabled, isTrue);
      expect(container.read(symmetryProvider).mode, equals(SymmetryMode.vertical));
    });

    test('selecting ruler tool auto-activates straight ruler guide mode when off', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      container.read(rulerGuideModeProvider.notifier).state = RulerGuideMode.off;
      expect(container.read(rulerGuideModeProvider), equals(RulerGuideMode.off));

      toolNotifier.selectTool(DrawingTool.ruler);
      expect(container.read(activeToolProvider), equals(DrawingTool.ruler));
      expect(container.read(rulerGuideModeProvider), equals(RulerGuideMode.straight));
    });

    test('StrokeRenderer safely renders multi-pass neon glow and spray strokes', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      final glowStroke = Stroke(
        points: const [
          StrokePoint(x: 10, y: 10, pressure: 1.0),
          StrokePoint(x: 50, y: 50, pressure: 1.0),
          StrokePoint(x: 90, y: 30, pressure: 1.0),
        ],
        color: const Color(0xFF00F0FF),
        brush: BrushPreset(
          name: 'Glow Neon',
          category: BrushCategory.effects,
          size: 20.0,
          isGlow: true,
          hardness: 0.85,
        ),
      );

      final sprayStroke = Stroke(
        points: const [
          StrokePoint(x: 20, y: 20, pressure: 1.0),
          StrokePoint(x: 60, y: 60, pressure: 1.0),
        ],
        color: const Color(0xFFFF007F),
        brush: BrushPreset(
          name: 'Airbrush',
          category: BrushCategory.effects,
          size: 30.0,
          isSpray: true,
          flow: 0.5,
        ),
      );

      // Rendering should execute cleanly without exceptions
      StrokeRenderer.renderStroke(canvas, glowStroke);
      StrokeRenderer.renderStroke(canvas, sprayStroke);

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });

    test('selecting smudge tool configures blending soft brush preset', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      toolNotifier.selectTool(DrawingTool.smudge);
      expect(container.read(activeToolProvider), equals(DrawingTool.smudge));

      final brush = container.read(activeBrushProvider);
      expect(brush.name, equals('Soft Brush'));
      expect(brush.size, equals(28.0));
      expect(brush.opacity, equals(0.5));
      expect(brush.hardness, equals(0.2));
    });

    test('selecting blur tool configures ultra-soft blur preset', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      toolNotifier.selectTool(DrawingTool.blur);
      expect(container.read(activeToolProvider), equals(DrawingTool.blur));

      final brush = container.read(activeBrushProvider);
      expect(brush.name, equals('Soft Brush'));
      expect(brush.size, equals(32.0));
      expect(brush.opacity, equals(0.35));
      expect(brush.hardness, equals(0.05));
    });

    test('selecting highlighter configures chisel highlighter preset', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      toolNotifier.selectTool(DrawingTool.highlighter);
      expect(container.read(activeToolProvider), equals(DrawingTool.highlighter));

      final brush = container.read(activeBrushProvider);
      expect(brush.name, equals('Highlighter'));
      expect(brush.isHighlighter, isTrue);
      expect(brush.size, equals(24.0));
      expect(brush.opacity, equals(0.55));
    });

    test('selecting rainbow configures dynamic rainbow brush preset', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      toolNotifier.selectTool(DrawingTool.rainbow);
      expect(container.read(activeToolProvider), equals(DrawingTool.rainbow));

      final brush = container.read(activeBrushProvider);
      expect(brush.name, equals('Rainbow Brush'));
      expect(brush.isRainbow, isTrue);
      expect(brush.size, equals(14.0));
    });

    test('selecting gradient tool selects DrawingTool.gradient', () {
      final container = ProviderContainer();
      final toolNotifier = container.read(activeToolProvider.notifier);

      toolNotifier.selectTool(DrawingTool.gradient);
      expect(container.read(activeToolProvider), equals(DrawingTool.gradient));
      expect(container.read(gradientTypeProvider), equals(GradientType.linear));
    });

    test('QuickPaletteTheme cycles through all themes and provides distinct color sets', () {
      final container = ProviderContainer();
      expect(container.read(quickPaletteThemeProvider), equals(QuickPaletteTheme.classic));
      expect(container.read(quickPaletteThemeProvider).colors.length, greaterThanOrEqualTo(6));

      for (int i = 0; i < QuickPaletteTheme.values.length; i++) {
        final current = container.read(quickPaletteThemeProvider);
        expect(current.colors, isNotEmpty);
        container.read(quickPaletteThemeProvider.notifier).state = current.nextTheme;
      }
      expect(container.read(quickPaletteThemeProvider), equals(QuickPaletteTheme.classic));
    });

    test('Stroke.bounds calculates accurate bounding box with brush padding', () {
      final stroke = Stroke(
        points: const [
          StrokePoint(x: 20, y: 30),
          StrokePoint(x: 100, y: 150),
        ],
        color: Colors.blue,
        brush: BrushPreset(name: 'Test', category: BrushCategory.basic, size: 10.0),
      );

      final bounds = stroke.bounds;
      expect(bounds.left, equals(15.0)); // 20 - 5
      expect(bounds.top, equals(25.0)); // 30 - 5
      expect(bounds.right, equals(105.0)); // 100 + 5
      expect(bounds.bottom, equals(155.0)); // 150 + 5
    });

    test('StrokeRenderer renders highlighter, rainbow, and gradient fills without errors', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Highlighter stroke
      final hlStroke = Stroke(
        points: const [StrokePoint(x: 10, y: 20), StrokePoint(x: 80, y: 20)],
        color: const Color(0xFFFFE600),
        brush: BrushPreset(name: 'HL', category: BrushCategory.basic, size: 24.0, isHighlighter: true),
      );
      StrokeRenderer.renderStroke(canvas, hlStroke);

      // Rainbow stroke with all rainbow modes
      for (final mode in RainbowMode.values) {
        final rbStroke = Stroke(
          points: const [StrokePoint(x: 10, y: 50), StrokePoint(x: 50, y: 80), StrokePoint(x: 90, y: 60)],
          color: Colors.red,
          brush: BrushPreset(name: 'RB', category: BrushCategory.basic, size: 16.0, isRainbow: true),
          rainbowMode: mode,
        );
        StrokeRenderer.renderStroke(canvas, rbStroke);
      }

      // Linear Gradient Fill
      final linearGradStroke = Stroke(
        points: const [StrokePoint(x: 0, y: 0), StrokePoint(x: 100, y: 100)],
        color: Colors.blue,
        secondaryColor: Colors.pink,
        gradientType: GradientType.linear,
        shapeType: ShapeType.gradientFill,
        brush: BrushPreset(name: 'Grad', category: BrushCategory.basic),
      );
      StrokeRenderer.renderStroke(canvas, linearGradStroke);

      // Radial Gradient Fill
      final radialGradStroke = Stroke(
        points: const [StrokePoint(x: 50, y: 50), StrokePoint(x: 100, y: 50)],
        color: Colors.amber,
        secondaryColor: Colors.deepPurple,
        gradientType: GradientType.radial,
        shapeType: ShapeType.gradientFill,
        brush: BrushPreset(name: 'Grad', category: BrushCategory.basic),
      );
      StrokeRenderer.renderStroke(canvas, radialGradStroke);

      // Rounded rectangle shape fill and outline
      final roundRectOutline = Stroke(
        points: const [StrokePoint(x: 10, y: 10), StrokePoint(x: 80, y: 60)],
        color: Colors.teal,
        shapeType: ShapeType.roundedRectangle,
        isFilled: false,
        brush: BrushPreset(name: 'Shape', category: BrushCategory.basic, size: 4.0),
      );
      StrokeRenderer.renderStroke(canvas, roundRectOutline);

      final roundRectFilled = Stroke(
        points: const [StrokePoint(x: 10, y: 10), StrokePoint(x: 80, y: 60)],
        color: Colors.teal,
        shapeType: ShapeType.roundedRectangle,
        isFilled: true,
        brush: BrushPreset(name: 'Shape', category: BrushCategory.basic, size: 4.0),
      );
      StrokeRenderer.renderStroke(canvas, roundRectFilled);

      // All 6 Pattern Stamp Types
      for (final stamp in PatternStampType.values) {
        final stampStroke = Stroke(
          points: const [StrokePoint(x: 25, y: 25), StrokePoint(x: 75, y: 75)],
          color: Colors.orange,
          brush: BrushPreset(name: 'Stamp', category: BrushCategory.effects, size: 30.0, isPatternStamp: true),
          stampType: stamp,
        );
        StrokeRenderer.renderStroke(canvas, stampStroke);
      }

      final pic = recorder.endRecording();
      expect(pic, isNotNull);
      pic.dispose();
    });

    test('StrokeRenderer safely handles zero/negative sizes, text strokes, and reversed flood fills', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Edge case 1: zero brush size
      final zeroSizeStroke = Stroke(
        points: const [StrokePoint(x: 10, y: 10), StrokePoint(x: 20, y: 20)],
        color: Colors.blue,
        brush: BrushPreset(name: 'Zero Brush', category: BrushCategory.basic, size: 0.0, hardness: 0.1),
      );
      StrokeRenderer.renderStroke(canvas, zeroSizeStroke);

      // Edge case 2: text stroke with opacity
      final textStroke = Stroke(
        points: const [StrokePoint(x: 50, y: 50)],
        color: Colors.red,
        brush: BrushPreset(name: 'Text', category: BrushCategory.basic, size: 12.0, opacity: 1.0),
        shapeType: ShapeType.text,
        text: 'Hello World',
        fontSize: 24.0,
      );
      StrokeRenderer.renderStroke(canvas, textStroke, layerOpacity: 1.0);

      // Edge case 3: flood fill with reversed span endpoints (p1.x > p2.x)
      final fillStroke = Stroke(
        points: const [
          StrokePoint(x: 80, y: 30),
          StrokePoint(x: 20, y: 30), // reversed
        ],
        color: Colors.green,
        brush: BrushPreset(name: 'Fill', category: BrushCategory.basic, size: 2.0),
        shapeType: ShapeType.floodFill,
      );
      StrokeRenderer.renderStroke(canvas, fillStroke);

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });

    test('ExportService renders document to valid PNG bytes cleanly', () async {
      final doc = CanvasDocument(
        name: 'Test Doc',
        width: 100,
        height: 100,
        layers: [
          LayerModel(
            name: 'Layer 1',
            strokes: [
              Stroke(
                points: const [StrokePoint(x: 10, y: 10), StrokePoint(x: 50, y: 50)],
                color: Colors.purple,
                brush: BrushPreset(name: 'Pen', category: BrushCategory.basic, size: 4.0),
              ),
            ],
          ),
        ],
      );

      final bytes = await ExportService.instance.renderToBytes(
        doc,
        const ExportConfig(format: ExportFormat.png),
      );
      expect(bytes, isNotEmpty);
      // PNG header magic bytes: 0x89, 0x50, 0x4E, 0x47
      expect(bytes[0], equals(0x89));
      expect(bytes[1], equals(0x50));
      expect(bytes[2], equals(0x4E));
      expect(bytes[3], equals(0x47));
    });
  });

  group('Shape and Flood Fill Stroke Serialization Tests', () {
    test('stroke with ShapeType.rectangle and isFilled = true roundtrips JSON', () {
      final stroke = Stroke(
        points: const [
          StrokePoint(x: 10, y: 15),
          StrokePoint(x: 120, y: 85),
        ],
        color: const Color(0xFFFF5722),
        brush: BrushPreset(name: 'Shape Brush', category: BrushCategory.basic, size: 4.0),
        shapeType: ShapeType.rectangle,
        isFilled: true,
      );

      final json = stroke.toJson();
      expect(json['shapeType'], equals('rectangle'));
      expect(json['isFilled'], isTrue);

      final deserialized = Stroke.fromJson(json);
      expect(deserialized.shapeType, equals(ShapeType.rectangle));
      expect(deserialized.isFilled, isTrue);
      expect(deserialized.points.length, equals(2));
      expect(deserialized.color.toARGB32(), equals(const Color(0xFFFF5722).toARGB32()));
    });

    test('stroke with ShapeType.floodFill roundtrips JSON', () {
      final stroke = Stroke(
        points: const [
          StrokePoint(x: 5, y: 10),
          StrokePoint(x: 25, y: 10),
          StrokePoint(x: 5, y: 11),
          StrokePoint(x: 30, y: 11),
        ],
        color: const Color(0xFF4CAF50),
        brush: BrushPreset(name: 'Flood Fill', category: BrushCategory.basic, size: 1.0),
        shapeType: ShapeType.floodFill,
        isFilled: true,
      );

      final json = stroke.toJson();
      expect(json['shapeType'], equals('floodFill'));
      expect(json['isFilled'], isTrue);

      final deserialized = Stroke.fromJson(json);
      expect(deserialized.shapeType, equals(ShapeType.floodFill));
      expect(deserialized.points.length, equals(4));
    });

    test('stroke with ShapeType.text and typography metadata roundtrips JSON', () {
      final stroke = Stroke(
        points: const [StrokePoint(x: 150, y: 300)],
        color: const Color(0xFF9C27B0),
        brush: BrushPreset(name: 'Text Stamp', category: BrushCategory.basic),
        shapeType: ShapeType.text,
        text: 'Masterpiece Art',
        fontFamily: 'Dancing Script',
        fontSize: 36.0,
        isBold: true,
        isItalic: true,
      );

      final json = stroke.toJson();
      expect(json['shapeType'], equals('text'));
      expect(json['text'], equals('Masterpiece Art'));
      expect(json['fontFamily'], equals('Dancing Script'));
      expect(json['fontSize'], equals(36.0));
      expect(json['isBold'], isTrue);
      expect(json['isItalic'], isTrue);

      final deserialized = Stroke.fromJson(json);
      expect(deserialized.shapeType, equals(ShapeType.text));
      expect(deserialized.text, equals('Masterpiece Art'));
      expect(deserialized.fontFamily, equals('Dancing Script'));
      expect(deserialized.fontSize, equals(36.0));
      expect(deserialized.isBold, isTrue);
      expect(deserialized.isItalic, isTrue);
      expect(deserialized.points.length, equals(1));
    });

    test('all ShapeType values serialize and deserialize accurately', () {
      for (final type in ShapeType.values) {
        final stroke = Stroke(
          points: const [StrokePoint(x: 0, y: 0), StrokePoint(x: 10, y: 10)],
          color: const Color(0xFF000000),
          brush: BrushPreset(name: 'Test', category: BrushCategory.basic),
          shapeType: type,
          isFilled: false,
        );

        final json = stroke.toJson();
        final deserialized = Stroke.fromJson(json);
        expect(deserialized.shapeType, equals(type));
      }
    });

    test('stroke with stampType, secondaryColor, gradientType, and rainbowMode roundtrips JSON', () {
      final stroke = Stroke(
        points: const [StrokePoint(x: 10, y: 10), StrokePoint(x: 100, y: 100)],
        color: const Color(0xFFFF0055),
        secondaryColor: const Color(0xFF00FFCC),
        gradientType: GradientType.radial,
        rainbowMode: RainbowMode.sunset,
        stampType: PatternStampType.heart,
        brush: BrushPreset(
          name: 'Super Brush',
          category: BrushCategory.effects,
          isHighlighter: true,
          isRainbow: true,
          isGradient: true,
        ),
      );

      final json = stroke.toJson();
      expect(json['stampType'], equals('heart'));
      expect(json['gradientType'], equals('radial'));
      expect(json['rainbowMode'], equals('sunset'));
      expect(json['secondaryColor'], equals(const Color(0xFF00FFCC).toARGB32()));

      final deserialized = Stroke.fromJson(json);
      expect(deserialized.stampType, equals(PatternStampType.heart));
      expect(deserialized.gradientType, equals(GradientType.radial));
      expect(deserialized.rainbowMode, equals(RainbowMode.sunset));
      expect(deserialized.secondaryColor, equals(const Color(0xFF00FFCC)));
      expect(deserialized.brush.isHighlighter, isTrue);
      expect(deserialized.brush.isRainbow, isTrue);
      expect(deserialized.brush.isGradient, isTrue);
    });
  });

  group('FontCatalogService and Typography Tests', () {
    test('font catalog loads over 100 fonts', () {
      final service = FontCatalogService.instance;
      expect(service.totalCount, greaterThanOrEqualTo(100));
      expect(service.allFonts.length, equals(service.totalCount));
    });

    test('font lookup by name is case-insensitive and falls back to defaultFont', () {
      final service = FontCatalogService.instance;

      final poppins = service.getFontByName('poppins');
      expect(poppins.name, equals('Poppins'));

      final robotoUpper = service.getFontByName('ROBOTO');
      expect(robotoUpper.name, equals('Roboto'));

      final pacifico = service.getFontByName('Pacifico');
      expect(pacifico.name, equals('Pacifico'));

      // Unknown font falls back safely
      final unknown = service.getFontByName('NonExistentFont123');
      expect(unknown.name, equals(service.defaultFont.name));
    });

    test('filter by category returns only fonts belonging to that category', () {
      final service = FontCatalogService.instance;
      final scriptFonts = service.filter(category: FontCategory.script);
      expect(scriptFonts, isNotEmpty);
      for (final font in scriptFonts) {
        expect(font.category, equals(FontCategory.script));
      }
    });

    test('FontItem applyStyle gracefully handles builder errors and returns fallback', () {
      final failingFont = FontItem(
        name: 'FaultyFont',
        category: FontCategory.sansSerif,
        builder: ({textStyle}) => throw Exception('Network/offline font fetch error'),
      );

      const base = TextStyle(fontSize: 20, color: Colors.blue);
      final resolved = failingFont.applyStyle(base);
      expect(resolved.fontSize, equals(20));
      expect(resolved.fontFamily, equals('FaultyFont'));
    });
  });

  group('LayerStrokesAction and Senior Flutter Audit Tests', () {
    test('LayerStrokesAction undo and redo restores previous and updated layer strokes', () {
      final docNotifier = CanvasDocumentNotifier();
      final stroke1 = Stroke(
        points: const [StrokePoint(x: 10, y: 10), StrokePoint(x: 50, y: 50)],
        color: Colors.red,
        brush: BrushPreset(name: 'Brush', category: BrushCategory.basic),
      );
      final stroke2 = Stroke(
        points: const [StrokePoint(x: 30, y: 30), StrokePoint(x: 80, y: 80)],
        color: Colors.blue,
        brush: BrushPreset(name: 'Brush', category: BrushCategory.basic),
      );
      final stroke3 = Stroke(
        points: const [StrokePoint(x: 50, y: 50), StrokePoint(x: 100, y: 100)],
        color: Colors.green,
        brush: BrushPreset(name: 'Brush', category: BrushCategory.basic),
      );

      // Add initial strokes
      docNotifier.addStroke(stroke1);
      docNotifier.addStroke(stroke2);
      final initialStrokes = docNotifier.state.activeLayer!.strokes;
      expect(initialStrokes.length, equals(2));

      // Batch update (e.g. after transform or color adjust)
      final transformedStrokes = [stroke3];
      docNotifier.updateActiveLayerStrokes(transformedStrokes);
      expect(docNotifier.state.activeLayer!.strokes.length, equals(1));
      expect(docNotifier.state.activeLayer!.strokes.first, equals(stroke3));

      // Create action and test undo
      final action = LayerStrokesAction(
        documentNotifier: docNotifier,
        oldStrokes: initialStrokes,
        newStrokes: transformedStrokes,
      );

      action.undo();
      expect(docNotifier.state.activeLayer!.strokes.length, equals(2));
      expect(docNotifier.state.activeLayer!.strokes.first, equals(stroke1));
      expect(docNotifier.state.activeLayer!.strokes.last, equals(stroke2));

      // Test redo
      action.redo();
      expect(docNotifier.state.activeLayer!.strokes.length, equals(1));
      expect(docNotifier.state.activeLayer!.strokes.first, equals(stroke3));
    });

    test('UndoRedoNotifier manages LayerStrokesAction in undo/redo stack', () {
      final docNotifier = CanvasDocumentNotifier();
      final undoNotifier = UndoRedoNotifier();

      final s1 = Stroke(
        points: const [StrokePoint(x: 0, y: 0), StrokePoint(x: 10, y: 10)],
        color: Colors.black,
        brush: BrushPreset(name: 'Pen', category: BrushCategory.basic),
      );
      final s2 = Stroke(
        points: const [StrokePoint(x: 20, y: 20), StrokePoint(x: 30, y: 30)],
        color: Colors.purple,
        brush: BrushPreset(name: 'Pen', category: BrushCategory.basic),
      );

      docNotifier.addStroke(s1);
      final oldStrokes = [s1];
      final newStrokes = [s1, s2];
      docNotifier.updateActiveLayerStrokes(newStrokes);

      final action = LayerStrokesAction(
        documentNotifier: docNotifier,
        oldStrokes: oldStrokes,
        newStrokes: newStrokes,
      );

      undoNotifier.pushAction(action);
      expect(undoNotifier.state.canUndo, isTrue);
      expect(undoNotifier.state.canRedo, isFalse);

      undoNotifier.undo();
      expect(docNotifier.state.activeLayer!.strokes.length, equals(1));
      expect(undoNotifier.state.canUndo, isFalse);
      expect(undoNotifier.state.canRedo, isTrue);

      undoNotifier.redo();
      expect(docNotifier.state.activeLayer!.strokes.length, equals(2));
      expect(undoNotifier.state.canUndo, isTrue);
      expect(undoNotifier.state.canRedo, isFalse);
    });

    test('Stroke.bounds calculates accurate bounding box for ShapeType.text', () {
      final textStroke = Stroke(
        points: const [StrokePoint(x: 100, y: 200)],
        color: Colors.amber,
        brush: BrushPreset(name: 'Text', category: BrushCategory.basic),
        shapeType: ShapeType.text,
        text: 'Hello Senior Flutter Dev',
        fontSize: 24.0,
      );

      final bounds = textStroke.bounds;
      expect(bounds.left, equals(100.0));
      expect(bounds.top, equals(200.0));
      expect(bounds.width, greaterThan(0.0));
      expect(bounds.height, greaterThan(0.0));
      expect(bounds.bottom, greaterThan(200.0));
    });

    test('StrokeRenderer handles zero-distance gradients without crashing', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Distance = 0 gradient
      final zeroGrad = Stroke(
        points: const [StrokePoint(x: 50, y: 50), StrokePoint(x: 50, y: 50)],
        color: Colors.blue,
        secondaryColor: Colors.red,
        shapeType: ShapeType.gradientFill,
        gradientType: GradientType.linear,
        brush: BrushPreset(name: 'Grad', category: BrushCategory.basic),
      );

      // Should return early safely without zero-vector error in ui.Gradient
      StrokeRenderer.renderStroke(canvas, zeroGrad);

      final pic = recorder.endRecording();
      expect(pic, isNotNull);
      pic.dispose();
    });

    test('StrokeRenderer renders single-point pattern stamps and single-point highlighters', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Single point highlighter
      final hlPoint = Stroke(
        points: const [StrokePoint(x: 40, y: 40)],
        color: Colors.yellow,
        brush: BrushPreset(name: 'HL', category: BrushCategory.basic, size: 20.0, isHighlighter: true),
      );
      StrokeRenderer.renderStroke(canvas, hlPoint);

      // Single point pattern stamps for all types
      for (final type in PatternStampType.values) {
        final stampPoint = Stroke(
          points: const [StrokePoint(x: 50, y: 50)],
          color: Colors.purple,
          brush: BrushPreset(name: 'Stamp', category: BrushCategory.effects, size: 30.0, isPatternStamp: true),
          stampType: type,
        );
        StrokeRenderer.renderStroke(canvas, stampPoint);
      }

      final pic = recorder.endRecording();
      expect(pic, isNotNull);
      pic.dispose();
    });
  });
}
