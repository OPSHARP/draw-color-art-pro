/// Design tokens for Draw Color Art Pro — iOS HIG Edition.
///
/// All spacing, radii, blur, animation, color, and sizing values used
/// throughout the app follow Apple's Human Interface Guidelines.
library;

import 'dart:ui';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Corner Radii (iOS HIG standards)
// ─────────────────────────────────────────────────────────────────────────────

/// Corner radius tokens following iOS HIG.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
  static const double xxl = 38; // pill / capsule
  static const double sheet = 12; // bottom sheet top corners
  static const double card = 14; // iOS card style
  static const double button = 10; // iOS button corners
}

// ─────────────────────────────────────────────────────────────────────────────
// Spacing (dp)
// ─────────────────────────────────────────────────────────────────────────────

/// Spacing tokens (dp).
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ─────────────────────────────────────────────────────────────────────────────
// Touch Targets
// ─────────────────────────────────────────────────────────────────────────────

/// Touch target sizes (dp).
abstract final class AppTouchTarget {
  static const double minimum = 44;
  static const double standard = 48;
}

// ─────────────────────────────────────────────────────────────────────────────
// Frosted Glass / Blur
// ─────────────────────────────────────────────────────────────────────────────

/// Backdrop blur sigma values for iOS frosted-glass effects.
abstract final class AppBlur {
  static const double light = 20.0;
  static const double medium = 30.0;
  static const double heavy = 50.0;

  /// Standard iOS toolbar frosted glass.
  static ImageFilter get toolbar => ImageFilter.blur(
        sigmaX: medium,
        sigmaY: medium,
      );

  /// Standard iOS sheet frosted glass.
  static ImageFilter get sheet => ImageFilter.blur(
        sigmaX: heavy,
        sigmaY: heavy,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// iOS System Colors
// ─────────────────────────────────────────────────────────────────────────────

/// iOS HIG system color palette.
abstract final class IOSColors {
  // ── Accent Colors ──
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemIndigo = Color(0xFF5856D6);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemPink = Color(0xFFFF2D55);
  static const Color systemPurple = Color(0xFFAF52DE);
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemTeal = Color(0xFF5AC8FA);
  static const Color systemYellow = Color(0xFFFFCC00);
  static const Color systemMint = Color(0xFF00C7BE);
  static const Color systemCyan = Color(0xFF32ADE6);

  // ── Brand (Vibrant Sky Blue / Cyan / Royal Azure matching Feature Graphic) ──
  static const Color brandPrimary = Color(0xFF007AFF);
  static const Color brandSecondary = Color(0xFF00C6FF);
  static const Color brandAccent = Color(0xFF00E5FF);
  static const Color brandDeep = Color(0xFF0052CC);
  static const Color brandLight = Color(0xFFE3F2FD);

  // ── Gray Scale (iOS HIG) ──
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);

  // ── Light Mode Surfaces ──
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGroupedBackground = Color(0xFFF2F2F7);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightSeparator = Color(0x4D3C3C43); // 30% opacity

  // ── Dark Mode Surfaces (True Black OLED) ──
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkGroupedBackground = Color(0xFF000000);
  static const Color darkElevated = Color(0xFF2C2C2E);
  static const Color darkSeparator = Color(0x99545458); // 60% opacity

  // ── Frosted Glass Tints ──
  static const Color frostedLight = Color(0xBBF9F9F9); // 73% white
  static const Color frostedDark = Color(0xBB1C1C1E); // 73% dark surface
  static const Color frostedUltraThinLight = Color(0x80FFFFFF); // 50%
  static const Color frostedUltraThinDark = Color(0x801C1C1E); // 50%
}

// ─────────────────────────────────────────────────────────────────────────────
// iOS Shadows / Elevation
// ─────────────────────────────────────────────────────────────────────────────

/// iOS-style shadow presets.
abstract final class AppShadow {
  /// Subtle card shadow (iOS standard).
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  /// Elevated card/modal shadow.
  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Floating panel / popover shadow.
  static List<BoxShadow> get floating => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Animation
// ─────────────────────────────────────────────────────────────────────────────

/// Animation durations and curves following iOS motion.
abstract final class AppAnimation {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration dialog = Duration(milliseconds: 400);
  static const Duration page = Duration(milliseconds: 450);

  /// iOS spring curve (used for sheets, panels).
  static const Curve iosSpring = Curves.easeOutCubic;

  /// iOS interactive dismiss curve.
  static const Curve iosDecelerate = Curves.decelerate;
}

// ─────────────────────────────────────────────────────────────────────────────
// Canvas Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Canvas constants.
abstract final class CanvasDefaults {
  static const double minZoom = 0.01; // 1% (unlimited overview)
  static const double maxZoom = 100.0; // 10,000% (unlimited micro-zoom)
  static const double defaultZoom = 1.0; // 100%

  static const int defaultWidth = 1080;
  static const int defaultHeight = 1920;

  static const int tileSize = 256;

  static const int maxUndoHistory = 100;

  static const double defaultBrushSize = 8.0;
  static const double minBrushSize = 1.0;
  static const double maxBrushSize = 500.0;

  static const double defaultOpacity = 1.0;
  static const double defaultFlow = 1.0;
  static const double defaultHardness = 0.8;
}

/// Canvas preset category for tab grouping.
enum PresetCategory {
  artGeneral('Art & General'),
  socialMedia('Social Media');

  const PresetCategory(this.label);
  final String label;
}

/// Canvas preset sizes.
enum CanvasPreset {
  // ── Art & General ──
  square(1080, 1080, 'Square (1:1)', PresetCategory.artGeneral),
  portrait(1080, 1920, 'Portrait / Story (9:16)', PresetCategory.artGeneral),
  landscape(1920, 1080, 'Landscape / HD (16:9)', PresetCategory.artGeneral),
  phoneWallpaper(1080, 2400, 'Phone Wallpaper', PresetCategory.artGeneral),
  fourK(3840, 2160, '4K Ultra HD', PresetCategory.artGeneral),
  kidsPad(1280, 960, 'Kids Drawing Pad (4:3)', PresetCategory.artGeneral),
  comic(1800, 2700, 'Comic / Manga (2:3)', PresetCategory.artGeneral),
  socialPost(1080, 1080, 'Social Post', PresetCategory.artGeneral),
  a4Portrait(2480, 3508, 'A4 Portrait (Print)', PresetCategory.artGeneral),
  a4Landscape(3508, 2480, 'A4 Landscape (Print)', PresetCategory.artGeneral),

  // ── Social Media ──
  youtubeThumbnail(1280, 720, 'YouTube Thumbnail (16:9)', PresetCategory.socialMedia),
  youtubeChannelArt(2560, 1440, 'YouTube Banner', PresetCategory.socialMedia),
  instagramPost(1080, 1080, 'Instagram Post (1:1)', PresetCategory.socialMedia),
  instagramStory(1080, 1920, 'Instagram Story (9:16)', PresetCategory.socialMedia),
  tiktokVideo(1080, 1920, 'TikTok / Reels (9:16)', PresetCategory.socialMedia),
  facebookCover(820, 312, 'Facebook Cover', PresetCategory.socialMedia),
  facebookPost(1200, 630, 'Facebook Post', PresetCategory.socialMedia),
  twitterHeader(1500, 500, 'Twitter / X Header (3:1)', PresetCategory.socialMedia),
  twitterPost(1200, 675, 'Twitter / X Post (16:9)', PresetCategory.socialMedia),
  linkedInBanner(1584, 396, 'LinkedIn Banner (4:1)', PresetCategory.socialMedia),
  pinterestPin(1000, 1500, 'Pinterest Pin (2:3)', PresetCategory.socialMedia),
  twitchBanner(1200, 480, 'Twitch Banner', PresetCategory.socialMedia),

  // ── Custom ──
  custom(0, 0, 'Custom', PresetCategory.artGeneral);

  const CanvasPreset(this.width, this.height, this.label, this.category);
  final int width;
  final int height;
  final String label;
  final PresetCategory category;

  /// Aspect ratio of this preset (width / height).
  double get aspectRatio => height > 0 ? width / height : 1.0;

  /// All art & general presets (excluding custom).
  static List<CanvasPreset> get artPresets =>
      values.where((p) => p.category == PresetCategory.artGeneral && p != custom).toList();

  /// All social media presets.
  static List<CanvasPreset> get socialPresets =>
      values.where((p) => p.category == PresetCategory.socialMedia).toList();
}

