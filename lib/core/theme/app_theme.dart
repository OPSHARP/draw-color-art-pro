import 'package:flutter/material.dart';
import '../constants/design_tokens.dart';

/// iOS-inspired app theme for Draw Color Art Pro.
///
/// Follows Apple Human Interface Guidelines:
/// - System fonts (SF Pro on iOS, Roboto on Android)
/// - True black OLED dark mode
/// - iOS system color palette
/// - Subtle shadows, no heavy gradients
/// - Frosted glass aesthetics
class AppTheme {
  AppTheme._();

  // ─── Brand Colors ───────────────────────────────────────────────
  static const Color brandPrimary = IOSColors.brandPrimary;
  static const Color brandSecondary = IOSColors.brandSecondary;
  static const Color brandAccent = IOSColors.brandAccent;

  // ─── Canvas Colors ─────────────────────────────────────────────
  static const Color canvasWhite = Color(0xFFFFFFFF);
  static const Color canvasCheckLight = Color(0xFFE8E8E8);
  static const Color canvasCheckDark = Color(0xFFC8C8C8);

  // ─── Text Theme (System Fonts) ─────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF000000);
    final Color secondaryText = brightness == Brightness.dark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF3C3C43);
    final Color tertiaryText = brightness == Brightness.dark
        ? const Color(0xFF48484A)
        : const Color(0xFFC7C7CC);

    // Use system default font (SF Pro on iOS, Roboto on Android)
    return TextTheme(
      // ── Large Titles ──
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0.37,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0.36,
        height: 1.2,
      ),
      // ── Title Styles ──
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0.35,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.38,
      ),
      headlineSmall: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.41,
      ),
      // ── Body / Callout ──
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.41,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.24,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: secondaryText,
        letterSpacing: -0.08,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: -0.41,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: -0.24,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondaryText,
        letterSpacing: -0.08,
      ),
      // ── Labels / Captions ──
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: -0.24,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryText,
        letterSpacing: 0,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: tertiaryText,
        letterSpacing: 0.07,
      ),
    );
  }

  // ─── Dark Theme (True Black OLED / iOS) ────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: '.SF Pro Text', // Fallback — system font is used
      colorScheme: const ColorScheme.dark(
        primary: IOSColors.brandPrimary,
        secondary: IOSColors.brandSecondary,
        tertiary: IOSColors.brandAccent,
        surface: IOSColors.darkSurface,
        surfaceContainerHighest: IOSColors.darkElevated,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: IOSColors.systemRed,
      ),
      scaffoldBackgroundColor: IOSColors.darkBackground,
      textTheme: _buildTextTheme(Brightness.dark),
      cardTheme: CardThemeData(
        color: IOSColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: const EdgeInsets.all(AppSpacing.xs),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.41,
        ),
        iconTheme: IconThemeData(color: IOSColors.brandPrimary, size: 22),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: IOSColors.brandPrimary,
        unselectedItemColor: IOSColors.systemGray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: IOSColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: IOSColors.brandPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: IOSColors.brandPrimary,
          side: const BorderSide(color: IOSColors.brandPrimary, width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: IOSColors.brandPrimary,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.41,
          ),
        ),
      ),
      iconTheme: const IconThemeData(
        color: IOSColors.systemGray,
        size: 22,
      ),
      dividerTheme: const DividerThemeData(
        color: IOSColors.darkSeparator,
        thickness: 0.5,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: IOSColors.brandPrimary,
        inactiveTrackColor: IOSColors.darkElevated,
        thumbColor: Colors.white,
        overlayColor: IOSColors.brandPrimary.withValues(alpha: 0.2),
        trackHeight: 4,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: IOSColors.darkElevated,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: const TextStyle(fontSize: 13, color: Colors.white),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IOSColors.systemGreen;
          }
          return IOSColors.darkElevated;
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: IOSColors.darkElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        elevation: 8,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: IOSColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        dragHandleColor: IOSColors.systemGray3,
        dragHandleSize: Size(36, 5),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: IOSColors.darkElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        elevation: 0,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        minVerticalPadding: AppSpacing.sm,
      ),
    );
  }

  // ─── Light Theme (Clean White / iOS) ───────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: '.SF Pro Text',
      colorScheme: const ColorScheme.light(
        primary: IOSColors.brandPrimary,
        secondary: IOSColors.brandSecondary,
        tertiary: IOSColors.brandAccent,
        surface: IOSColors.lightSurface,
        surfaceContainerHighest: IOSColors.systemGray6,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF000000),
        error: IOSColors.systemRed,
      ),
      scaffoldBackgroundColor: IOSColors.lightGroupedBackground,
      textTheme: _buildTextTheme(Brightness.light),
      cardTheme: CardThemeData(
        color: IOSColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: const EdgeInsets.all(AppSpacing.xs),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF000000),
          letterSpacing: -0.41,
        ),
        iconTheme: IconThemeData(color: IOSColors.brandPrimary, size: 22),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: IOSColors.brandPrimary,
        unselectedItemColor: IOSColors.systemGray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: IOSColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: IOSColors.brandPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: IOSColors.brandPrimary,
          side: const BorderSide(color: IOSColors.brandPrimary, width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: IOSColors.brandPrimary,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.41,
          ),
        ),
      ),
      iconTheme: const IconThemeData(
        color: IOSColors.systemGray,
        size: 22,
      ),
      dividerTheme: const DividerThemeData(
        color: IOSColors.lightSeparator,
        thickness: 0.5,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: IOSColors.brandPrimary,
        inactiveTrackColor: IOSColors.systemGray5,
        thumbColor: Colors.white,
        overlayColor: IOSColors.brandPrimary.withValues(alpha: 0.2),
        trackHeight: 4,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: const TextStyle(fontSize: 13, color: Colors.white),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IOSColors.systemGreen;
          }
          return IOSColors.systemGray4;
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: IOSColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        elevation: 8,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: IOSColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        dragHandleColor: IOSColors.systemGray3,
        dragHandleSize: Size(36, 5),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: IOSColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        elevation: 0,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        minVerticalPadding: AppSpacing.sm,
      ),
    );
  }
}
