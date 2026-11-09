import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:draw_color_art_pro/features/canvas/models/stroke.dart';
import 'package:draw_color_art_pro/features/canvas/providers/canvas_providers.dart';
import 'package:draw_color_art_pro/features/brushes/default_brushes.dart';

void main() {
  group('UndoRedoNotifier tests', () {
    late CanvasDocumentNotifier docNotifier;
    late UndoRedoNotifier undoNotifier;

    setUp(() {
      docNotifier = CanvasDocumentNotifier();
      docNotifier.createNew(
        name: 'Undo Test',
        width: 500,
        height: 500,
      );
      undoNotifier = UndoRedoNotifier();
    });

    test('initial state has empty undo and redo stacks', () {
      expect(undoNotifier.state.canUndo, isFalse);
      expect(undoNotifier.state.canRedo, isFalse);
    });

    test('pushing action enables undo', () {
      final stroke = Stroke(
        points: const [StrokePoint(x: 10, y: 10)],
        color: Colors.black,
        brush: DefaultBrushes.pencil,
      );
      docNotifier.addStroke(stroke);

      undoNotifier.pushAction(
        StrokeAction(documentNotifier: docNotifier, stroke: stroke),
      );

      expect(undoNotifier.state.canUndo, isTrue);
      expect(undoNotifier.state.canRedo, isFalse);
    });

    test('undo removes stroke and enables redo', () {
      final stroke = Stroke(
        points: const [StrokePoint(x: 10, y: 10)],
        color: Colors.black,
        brush: DefaultBrushes.pencil,
      );
      docNotifier.addStroke(stroke);
      expect(docNotifier.state.activeLayer?.strokes.length, equals(1));

      undoNotifier.pushAction(
        StrokeAction(documentNotifier: docNotifier, stroke: stroke),
      );

      undoNotifier.undo();
      expect(docNotifier.state.activeLayer?.strokes.isEmpty, isTrue);
      expect(undoNotifier.state.canUndo, isFalse);
      expect(undoNotifier.state.canRedo, isTrue);

      undoNotifier.redo();
      expect(docNotifier.state.activeLayer?.strokes.length, equals(1));
      expect(undoNotifier.state.canUndo, isTrue);
      expect(undoNotifier.state.canRedo, isFalse);
    });

    test('clear wipes both stacks', () {
      final stroke = Stroke(
        points: const [StrokePoint(x: 10, y: 10)],
        color: Colors.black,
        brush: DefaultBrushes.pencil,
      );
      undoNotifier.pushAction(
        StrokeAction(documentNotifier: docNotifier, stroke: stroke),
      );
      undoNotifier.clear();
      expect(undoNotifier.state.canUndo, isFalse);
      expect(undoNotifier.state.canRedo, isFalse);
    });
  });
}
