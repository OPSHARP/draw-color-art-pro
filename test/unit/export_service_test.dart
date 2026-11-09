import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:draw_color_art_pro/features/canvas/models/canvas_document.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/features/brushes/default_brushes.dart';
import 'package:draw_color_art_pro/features/export/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportService tests', () {
    late CanvasDocument sampleDoc;

    setUp(() {
      final stroke = Stroke(
        points: const [
          StrokePoint(x: 10, y: 10),
          StrokePoint(x: 50, y: 50),
        ],
        color: Colors.red,
        brush: DefaultBrushes.pencil,
      );

      final layer = LayerModel(
        name: 'Art Layer',
        strokes: [stroke],
      );

      sampleDoc = CanvasDocument(
        name: 'TestExportArt',
        width: 100,
        height: 100,
        layers: [layer],
      );
    });

    test('renderToBytes produces valid PNG byte stream', () async {
      const config = ExportConfig(
        format: ExportFormat.png,
        scale: 1.0,
      );

      final bytes = await ExportService.instance.renderToBytes(sampleDoc, config);
      expect(bytes, isNotEmpty);
      // PNG header magic bytes: 0x89, 0x50, 0x4E, 0x47
      expect(bytes[0], equals(0x89));
      expect(bytes[1], equals(0x50));
      expect(bytes[2], equals(0x4E));
      expect(bytes[3], equals(0x47));
    });

    test('renderToBytes produces valid JPEG byte stream', () async {
      const config = ExportConfig(
        format: ExportFormat.jpeg,
        scale: 1.0,
        quality: 85,
      );

      final bytes = await ExportService.instance.renderToBytes(sampleDoc, config);
      expect(bytes, isNotEmpty);
      // JPEG header magic bytes: 0xFF, 0xD8
      expect(bytes[0], equals(0xFF));
      expect(bytes[1], equals(0xD8));
    });

    test('renderToBytes supports 2x resolution scaling', () async {
      const config = ExportConfig(
        format: ExportFormat.png,
        scale: 2.0,
      );

      final bytes = await ExportService.instance.renderToBytes(sampleDoc, config);
      expect(bytes, isNotEmpty);
    });

    test('saveToPhoneStorage writes file to disk and returns non-empty path', () async {
      const config = ExportConfig(
        format: ExportFormat.png,
        scale: 1.0,
      );

      final savedPath = await ExportService.instance.saveToPhoneStorage(
        sampleDoc,
        config,
        targetDirectory: Directory.systemTemp,
      );
      expect(savedPath, isNotEmpty);
      final file = File(savedPath);
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(0));

      // Clean up temporary test file
      await file.delete();
    });
  });
}
