import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'app.dart';
import 'core/ads/ad_service.dart';
import 'core/audio/sound_effect_service.dart';
import 'core/services/display_service.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Enable modern Android System Photo Picker (MediaStore.ACTION_PICK_IMAGES)
    // strictly complying with Google Play Console Photo & Video Permissions policy
    try {
      final imagePickerPlatform = ImagePickerPlatform.instance;
      if (imagePickerPlatform is ImagePickerAndroid) {
        imagePickerPlatform.useAndroidPhotoPicker = true;
      }
    } catch (_) {}

    // Catch framework errors gracefully
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.presentError(details);
        debugPrint('DrawColorArtPro FlutterError: ${details.exceptionAsString()}');
      }
    };

    // Catch uncaught platform/engine errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('DrawColorArtPro PlatformDispatcher error: $error\n$stack');
      }
      return true;
    };

    // 1. Non-blocking UI system configuration (runs in parallel, does not block first frame)
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge).catchError((_) {}));
    unawaited(SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]).catchError((_) {}));
    unawaited(DisplayRefreshRateService.instance.init().catchError((_) {}));

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
    );

    // 2. Fast check for onboarding status (<10ms)
    bool showOnboarding = false;
    try {
      showOnboarding = !(await OnboardingScreen.isOnboardingComplete());
    } catch (_) {
      showOnboarding = false;
    }

    // 3. Render UI IMMEDIATELY! First frame renders NOW without delay!
    runApp(
      ProviderScope(
        child: DrawColorArtProApp(showOnboarding: showOnboarding),
      ),
    );

    // 4. Background initialization of heavy services (audio & ads)
    // Runs after UI is mounted and rendering, completely eliminating startup delay!
    unawaited(_initHeavyServices());
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('DrawColorArtPro uncaught top-level error: $error\n$stack');
    }
  });
}

Future<void> _initHeavyServices() async {
  // Initialize sound effects in background
  try {
    await SoundEffectService.instance.init();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('DrawColorArtPro: SoundEffectService background init warning: $e');
    }
  }

  // Initialize AdMob in background
  try {
    await AdService.instance.init();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('DrawColorArtPro: AdService background init warning: $e');
    }
  }

  // Ensure high refresh rate display mode is locked in
  try {
    await DisplayRefreshRateService.instance.init();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('DrawColorArtPro: DisplayRefreshRateService background init warning: $e');
    }
  }
}
