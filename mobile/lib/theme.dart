import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color forestGreen = Color(0xFF0A5F44);
  static const Color deepGreen = Color(0xFF073D2C);
  static const Color xafGold = Color(0xFFCA9000);
  static const Color warmBackground = Color(0xFFF1F6F3);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F1916);
  static const Color textMuted = Color(0xFF4D6E61);

  static const Color moduleClients = Color(0xFF1455A4);
  static const Color moduleCatalog = Color(0xFFBF360C);
  static const Color moduleSales = Color(0xFF0A5F44);
  static const Color moduleStock = Color(0xFF4A148C);
  static const Color moduleProofs = Color(0xFFB56000);

  static ColorScheme _lightScheme() => const ColorScheme(
        brightness: Brightness.light,
        primary: forestGreen,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFB2DCCF),
        onPrimaryContainer: Color(0xFF002716),
        secondary: xafGold,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFFE0A0),
        onSecondaryContainer: Color(0xFF3A2500),
        tertiary: Color(0xFF005B8E),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFB8DAFF),
        onTertiaryContainer: Color(0xFF001D33),
        error: Color(0xFFB3261E),
        onError: Colors.white,
        errorContainer: Color(0xFFF9DEDC),
        onErrorContainer: Color(0xFF410E0B),
        surface: warmBackground,
        onSurface: textPrimary,
        surfaceContainerHighest: Color(0xFFDCEBE3),
        surfaceContainer: cardWhite,
        outline: Color(0xFF7DA898),
        outlineVariant: Color(0xFFBDD6CC),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Color(0xFF1E3329),
        onInverseSurface: Color(0xFFECF3EE),
        inversePrimary: Color(0xFF7EC8AC),
      );

  static ThemeData light() {
    final scheme = _lightScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: warmBackground,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 57,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
            height: 1.1),
        headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.25),
        headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.3),
        headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1.3),
        titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
            height: 1.35),
        titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            height: 1.4),
        titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            height: 1.4),
        bodyLarge:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.55),
        bodyMedium:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
            height: 1.5,
            color: textMuted),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: textMuted),
        labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        centerTitle: false,
        titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.2),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEEF4F1),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: forestGreen, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB3261E), width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle:
            const TextStyle(color: textMuted, fontWeight: FontWeight.w500),
        floatingLabelStyle:
            const TextStyle(color: forestGreen, fontWeight: FontWeight.w600),
        prefixIconColor: textMuted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forestGreen,
          side: const BorderSide(color: forestGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: forestGreen,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: const Color(0xFFE8F0EC),
          selectedBackgroundColor: forestGreen,
          selectedForegroundColor: Colors.white,
          foregroundColor: textPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE8F0EC),
        selectedColor: forestGreen.withValues(alpha: 0.18),
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
        checkmarkColor: forestGreen,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: deepGreen,
        contentTextStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
          color: Color(0xFFE4EDE8), thickness: 1, space: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
