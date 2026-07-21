import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized design tokens and Material 3 theming for the app.
///
/// Keeping colors, shapes and component themes in one place means a rebrand
/// is a single-file change instead of scattered color literals.
class AppTheme {
  AppTheme._();

  /// Brand seed — a trustworthy teal, suited to a civic-services app.
  static const Color brandSeed = Color(0xFF0E8388);

  /// Light neutral scaffold background.
  static const Color lightBackground = Color(0xFFF2F6F6);

  /// Section-icon accent colors used across the home rails.
  static const Color accentTeal = Color(0xFF0E7C74);
  static const Color accentAmber = Color(0xFFD98A21);
  static const Color accentBlue = Color(0xFF2F6FE0);

  /// Pastel (background, foreground) pairs cycled across scheme cards.
  static const List<(Color, Color)> cardAccents = [
    (Color(0xFFE0F2F1), Color(0xFF0E7C74)), // teal
    (Color(0xFFE8F0FE), Color(0xFF2F6FE0)), // blue
    (Color(0xFFFDF3E3), Color(0xFFC8801C)), // amber
    (Color(0xFFFCEBEF), Color(0xFFC2416F)), // rose
  ];

  static const double _radius = 18;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: brandSeed,
      brightness: brightness,
    );
    final baseText =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: isDark ? scheme.surface : lightBackground,
      textTheme: GoogleFonts.interTextTheme(baseText),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? scheme.surface : lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
