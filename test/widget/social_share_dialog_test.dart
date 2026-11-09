import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:draw_color_art_pro/features/canvas/models/canvas_document.dart';
import 'package:draw_color_art_pro/features/export/views/social_share_dialog.dart';

void main() {
  group('SocialShareDialog Widget Tests', () {
    testWidgets('renders all social media share options and action buttons', (tester) async {
      final doc = CanvasDocument(name: 'My Masterpiece', width: 1080, height: 1920);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialShareDialog(document: doc),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share Your Masterpiece'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Twitter / X'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('Pinterest'), findsOneWidget);

      expect(find.text('Save to Photos'), findsOneWidget);
      expect(find.text('Share All Apps'), findsOneWidget);
    });
  });
}
