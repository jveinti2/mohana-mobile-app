import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Re-export design tokens so existing `import 'config/theme.dart'` keeps working
export 'design_tokens.dart';

import 'design_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// MOHANA THEME — MaterialApp ThemeData + Component Themes
/// ════════════════════════════════════════════════════════════════

/// Global theme mode controller
class ThemeController {
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.light);

  static void toggle() {
    mode.value =
        mode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  static bool get isDark => mode.value == ThemeMode.dark;
}

class MohanaTheme {
  MohanaTheme._();

  // ─── Light Theme ───────────────────────────────────────────

  static ThemeData get light => _buildTheme(isDark: false);

  // ─── Dark Theme ────────────────────────────────────────────

  static ThemeData get dark => _buildTheme(isDark: true);

  // ─── Legacy alias ──────────────────────────────────────────

  static ThemeData get theme => light;

  static ThemeData _buildTheme({required bool isDark}) {
    final bg = isDark ? const Color(0xFF121215) : MohanaColors.background;
    final surface = isDark ? const Color(0xFF1E1D22) : MohanaColors.surface;
    final surfaceLow =
        isDark ? const Color(0xFF2A292F) : MohanaColors.surfaceContainerLow;
    final onSurface =
        isDark ? const Color(0xFFE8E7EC) : MohanaColors.onSurface;
    final onSurfaceVariant =
        isDark ? const Color(0xFFB0AFB8) : MohanaColors.onSurfaceVariant;
    final divider =
        isDark ? const Color(0xFF3A393F) : MohanaColors.divider;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: MohanaColors.primary,
              primaryContainer: MohanaColors.primary400,
              secondary: MohanaColors.secondary,
              tertiary: MohanaColors.tertiary,
              surface: Color(0xFF1E1D22),
              onSurface: Color(0xFFE8E7EC),
              onSurfaceVariant: Color(0xFFB0AFB8),
              outlineVariant: Color(0xFF3A393F),
              onPrimary: MohanaColors.onPrimary,
              error: MohanaColors.error,
            )
          : const ColorScheme.light(
              primary: MohanaColors.primary,
              primaryContainer: MohanaColors.primary400,
              secondary: MohanaColors.secondary,
              secondaryContainer: MohanaColors.secondary100,
              tertiary: MohanaColors.tertiary,
              tertiaryContainer: MohanaColors.primary800,
              surface: MohanaColors.background,
              onSurface: MohanaColors.onSurface,
              onSurfaceVariant: MohanaColors.onSurfaceVariant,
              outlineVariant: MohanaColors.outlineVariant,
              onPrimary: MohanaColors.onPrimary,
              onSecondary: MohanaColors.onSecondary,
              onTertiary: MohanaColors.onTertiary,
              error: MohanaColors.error,
            ),
      textTheme: _buildTextTheme(onSurface, onSurfaceVariant),
      appBarTheme: _appBarTheme.copyWith(backgroundColor: bg),
      cardTheme: _cardTheme.copyWith(color: surface),
      inputDecorationTheme: _buildInputTheme(surfaceLow, onSurfaceVariant),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      chipTheme: _chipTheme,
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(MohanaRadius.xxl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: MohanaRadius.xlAll,
        ),
      ),
    );
  }

  // ─── Typography ────────────────────────────────────────────

  static TextTheme _buildTextTheme(Color onSurface, Color onSurfaceVariant) =>
      TextTheme(
        displayLarge: GoogleFonts.breeSerif(
            fontSize: 56, fontWeight: FontWeight.w400, color: onSurface, height: 1.1),
        displayMedium: GoogleFonts.breeSerif(
            fontSize: 45, fontWeight: FontWeight.w400, color: onSurface, height: 1.15),
        displaySmall: GoogleFonts.breeSerif(
            fontSize: 36, fontWeight: FontWeight.w400, color: onSurface, height: 1.2),
        headlineLarge: GoogleFonts.breeSerif(
            fontSize: 32, fontWeight: FontWeight.w400, color: onSurface, height: 1.2),
        headlineMedium: GoogleFonts.breeSerif(
            fontSize: 28, fontWeight: FontWeight.w400, color: onSurface, height: 1.25),
        headlineSmall: GoogleFonts.breeSerif(
            fontSize: 24, fontWeight: FontWeight.w400, color: onSurface, height: 1.3),
        titleLarge: GoogleFonts.montserrat(
            fontSize: 22, fontWeight: FontWeight.w600, color: onSurface),
        titleMedium: GoogleFonts.montserrat(
            fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
        titleSmall: GoogleFonts.montserrat(
            fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
        bodyLarge: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w400, color: onSurface, height: 1.6),
        bodyMedium: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w400, color: onSurface, height: 1.6),
        bodySmall: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w400, color: onSurfaceVariant, height: 1.5),
        labelLarge: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
        labelMedium: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceVariant),
        labelSmall: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w500, color: onSurfaceVariant, letterSpacing: 0.5),
      );

  // ─── AppBar ────────────────────────────────────────────────

  static final _appBarTheme = AppBarTheme(
    backgroundColor: MohanaColors.background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.breeSerif(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: MohanaColors.primary,
    ),
    iconTheme: const IconThemeData(
      color: MohanaColors.onSurface,
      size: 24,
    ),
  );

  // ─── Card ──────────────────────────────────────────────────

  static final _cardTheme = CardThemeData(
    color: MohanaColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: MohanaRadius.lgAll,
    ),
    margin: EdgeInsets.zero,
  );

  // ─── Input Fields ──────────────────────────────────────────

  static InputDecorationTheme _buildInputTheme(
          Color fillColor, Color hintColor) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MohanaSpacing.base,
          vertical: MohanaSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: MohanaRadius.mdAll,
          borderSide: const BorderSide(color: MohanaColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: MohanaRadius.mdAll,
          borderSide: const BorderSide(color: MohanaColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: MohanaRadius.mdAll,
          borderSide:
              const BorderSide(color: MohanaColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: MohanaRadius.mdAll,
          borderSide: const BorderSide(color: MohanaColors.error),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: hintColor,
          letterSpacing: 1.2,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: hintColor,
        ),
        prefixIconColor: hintColor,
        suffixIconColor: hintColor,
      );

  // ─── Elevated Button (solid purple) ────────────────────────

  static final _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: MohanaColors.primary,
      foregroundColor: MohanaColors.onPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: MohanaSpacing.xxl,
        vertical: MohanaSpacing.base,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: MohanaRadius.pillAll,
      ),
      textStyle: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  // ─── Outlined Button ──────────────────────────────────────

  static final _outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: MohanaColors.primary,
      side: const BorderSide(color: MohanaColors.primary, width: 1.5),
      padding: const EdgeInsets.symmetric(
        horizontal: MohanaSpacing.xl,
        vertical: MohanaSpacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: MohanaRadius.pillAll,
      ),
      textStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // ─── Text Button (links: "LEER MÁS →", "Regístrate") ─────

  static final _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: MohanaColors.primary,
      padding: EdgeInsets.zero,
      textStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  // ─── Chips (category tags, interest tags) ──────────────────

  static final _chipTheme = ChipThemeData(
    backgroundColor: MohanaColors.primary,
    labelStyle: GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: MohanaColors.onPrimary,
      letterSpacing: 0.5,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: MohanaSpacing.sm,
      vertical: MohanaSpacing.xs,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: MohanaRadius.smAll,
    ),
    side: BorderSide.none,
  );

  // ─── Utility: Gradient Button Widget Helper ────────────────

  /// Builds a gradient CTA button matching the Figma design.
  /// Use this instead of ElevatedButton when a gradient is needed.
  ///
  /// ```dart
  /// MohanaTheme.gradientButton(
  ///   onPressed: () {},
  ///   label: 'Iniciar Sesión',
  /// )
  /// ```
  static Widget gradientButton({
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    double? width,
  }) {
    return Container(
      width: width ?? double.infinity,
      decoration: onPressed != null
          ? MohanaDecorations.primaryButton
          : BoxDecoration(
              color: MohanaColors.surfaceDim,
              borderRadius: MohanaRadius.pillAll,
            ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: MohanaRadius.pillAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: MohanaSpacing.base,
              horizontal: MohanaSpacing.xxl,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: MohanaColors.onPrimary, size: 20),
                  const SizedBox(width: MohanaSpacing.sm),
                ],
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onPressed != null
                        ? MohanaColors.onPrimary
                        : MohanaColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds an "EN VIVO" badge matching the Figma design.
  static Widget liveBadge({double fontSize = 10}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MohanaSpacing.sm,
        vertical: MohanaSpacing.xxs,
      ),
      decoration: MohanaDecorations.liveBadge,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: MohanaColors.onPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: MohanaSpacing.xs),
          Text(
            'EN VIVO',
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: MohanaColors.onPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a category tag chip matching the Figma news feed.
  static Widget categoryTag(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MohanaSpacing.sm,
        vertical: MohanaSpacing.xs,
      ),
      decoration: MohanaDecorations.categoryTag(category),
      child: Text(
        category.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
