import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:draw_color_art_pro/app.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DrawColorArtProApp(showOnboarding: true),
      ),
    );

    // Verify onboarding is shown
    expect(find.text('Draw Without\nLimits'), findsOneWidget);
  });
}
