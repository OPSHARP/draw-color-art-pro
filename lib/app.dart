import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ads/ad_block_overlay.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

/// Root application widget for Draw Color Art Pro.
///
/// Uses MaterialApp with iOS-styled themes for the best of both worlds:
/// Material's rich widget library + iOS design aesthetics.
class DrawColorArtProApp extends ConsumerWidget {
  const DrawColorArtProApp({super.key, required this.showOnboarding});

  final bool showOnboarding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Draw Color Art Pro',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // iOS-style page transitions globally
      builder: (context, child) {
        return AdBlockToastOverlay(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: child!,
          ),
        );
      },
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}

/// iOS-style slide-from-right page route.
class IOSPageRoute<T> extends PageRouteBuilder<T> {
  IOSPageRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            final secondaryTween = Tween(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            return SlideTransition(
              position: animation.drive(tween),
              child: SlideTransition(
                position: secondaryAnimation.drive(secondaryTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
        );
}
