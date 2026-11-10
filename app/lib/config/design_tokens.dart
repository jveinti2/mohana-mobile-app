import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════
/// MOHANA DESIGN SYSTEM — Design Tokens
/// Extracted from Figma: Mohana App Design System
/// ════════════════════════════════════════════════════════════════

// ─── Color Palette ──────────────────────────────────────────────

class MohanaColors {
  MohanaColors._();

  // ── Brand Colors (corporate identity) ───────────────────────
  /// Primary brand purple — CTAs, active states, links, accents
  static const primary = Color(0xFF7B2E88);

  /// Secondary orange — secondary accents, highlights
  static const secondary = Color(0xFFE18F53);

  /// Tertiary deep purple — emphasis, dark accents, headers
  static const tertiary = Color(0xFF5C1F6A);

  /// Neutral — light background tint
  static const neutral = Color(0xFFF5F5F7);

  // ── Primary Purple Scale ───────────────────────────────────
  static const primary50 = Color(0xFFF5EAF6);
  static const primary100 = Color(0xFFE8D0EB);
  static const primary200 = Color(0xFFD4A3D6);
  static const primary300 = Color(0xFFC07DC0);
  static const primary400 = Color(0xFF9D47A4);
  static const primary500 = Color(0xFF7B2E88); // == primary
  static const primary600 = Color(0xFF6A2575);
  static const primary700 = Color(0xFF5C1F6A); // == tertiary
  static const primary800 = Color(0xFF4A155C);
  static const primary900 = Color(0xFF380B48);

  // ── Secondary Orange Scale ──────────────────────────────────
  static const secondary50 = Color(0xFFFDF3EB);
  static const secondary100 = Color(0xFFF8DCC7);
  static const secondary200 = Color(0xFFF2C5A3);
  static const secondary300 = Color(0xFFE18F53); // == secondary
  static const secondary400 = Color(0xFFD47A3D);
  static const secondary500 = Color(0xFFC76828);

  // ── Surface / Background ───────────────────────────────────
  static const background = Color(0xFFF8F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F3F7);
  static const surfaceContainer = Color(0xFFEDEDF2);
  static const surfaceContainerHigh = Color(0xFFE2E1E8);
  static const surfaceDim = Color(0xFFD4D3DC);

  // ── Fondo tonal del feed (gradiente monocromo de marca) ───────
  /// Lila de marca — cabecera del fondo tonal (home, podcasts).
  static const tonalTop = Color(0xFFD4A3D6);
  /// Paso intermedio del gradiente tonal.
  static const tonalMid = Color(0xFFE7D4EF);
  /// Lila casi blanco — pie del gradiente, bajo la barra del reproductor.
  static const tonalBottom = Color(0xFFF6EDF9);

  // ── On-colors (text/icons) ─────────────────────────────────
  static const onPrimary = Color(0xFFFFFFFF);
  static const onSecondary = Color(0xFF5C1F6A);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF1A1B21);
  static const onSurfaceVariant = Color(0xFF49454F);
  static const onBackground = Color(0xFF1A1B21);

  // ── Outline ────────────────────────────────────────────────
  static const outline = Color(0xFF79747E);
  static const outlineVariant = Color(0xFFCDCDD5);
  static const inputBorder = Color(0xFFE2E1E8);

  // ── Semantic ───────────────────────────────────────────────
  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF388E3C);
  static const warning = Color(0xFFF57C00);
  static const info = Color(0xFF1976D2);

  // ── Status / Live ──────────────────────────────────────────
  /// Punto del directo. Solo como mancha de color, nunca bajo texto.
  static const liveIndicator = Color(0xFFE91E63);

  /// Paso más oscuro del mismo rosa, para cuando la píldora del directo lleva
  /// texto encima: [liveIndicator] con blanco se queda en 3.97:1 y no llega al
  /// 4.5:1 que pide AA. Este da 5.4:1.
  static const liveIndicatorStrong = Color(0xFFC2185B);

  static const enVivoBadge = Color(0xFF7B2E88);

  // ── Misc UI ────────────────────────────────────────────────
  static const shimmer = Color(0xFFE2E1E8);
  static const divider = Color(0xFFEDEDF2);
  static const scrim = Color(0x521A1B21);
}

// ─── Category Tag Colors ────────────────────────────────────────

class MohanaCategoryColors {
  MohanaCategoryColors._();

  static const impactoSocial = Color(0xFF00897B);
  static const cultura = Color(0xFF2E7D32);
  static const salud = Color(0xFF00838F);
  static const medioAmbiente = Color(0xFF558B2F);
  static const musica = Color(0xFF7B2E88);
  static const comunidad = Color(0xFFAD1457);
  static const educacion = Color(0xFF1565C0);
  static const infraestructura = Color(0xFF6D4C41);
  static const podcastNuevo = Color(0xFFE91E63);

  /// Returns the background color for a category tag.
  static Color forCategory(String category) {
    switch (category.toLowerCase().trim()) {
      case 'impacto social':
        return impactoSocial;
      case 'cultura':
        return cultura;
      case 'salud':
        return salud;
      case 'medio ambiente':
        return medioAmbiente;
      case 'música':
      case 'musica':
        return musica;
      case 'comunidad':
        return comunidad;
      case 'educación':
      case 'educacion':
        return educacion;
      case 'infraestructura':
        return infraestructura;
      case 'podcast nuevo':
        return podcastNuevo;
      default:
        return MohanaColors.primary;
    }
  }
}

// ─── Gradients ──────────────────────────────────────────────────

class MohanaGradients {
  MohanaGradients._();

  /// CTA button gradient (Iniciar Sesión, Publicar, etc.)
  static const primaryButton = LinearGradient(
    colors: [Color(0xFFA855B8), Color(0xFF7B2E88)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Brand gradient — headers, hero areas
  static const brand = LinearGradient(
    colors: [MohanaColors.primary, MohanaColors.tertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Avatar ring gradient (profile screen)
  static const avatarRing = SweepGradient(
    colors: [
      Color(0xFF7B2E88),
      Color(0xFFE18F53),
      Color(0xFF5C1F6A),
      Color(0xFFE18F53),
      Color(0xFF7B2E88),
    ],
  );

  /// Subtle background wash (login, onboarding)
  static const backgroundSubtle = LinearGradient(
    colors: [Color(0xFFF8F8FA), Color(0xFFF0E6F2), Color(0xFFF8F8FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Home tonal background — monocromo de la escala primary: lila de marca
  /// arriba, aclarándose hasta casi blanco al pie. El stop intermedio
  /// concentra la intensidad en el tercio superior.
  /// Da identidad al feed; las cards van en blanco para contraste.
  static const homeTonal = LinearGradient(
    colors: [
      MohanaColors.tonalTop,
      MohanaColors.tonalMid,
      MohanaColors.tonalBottom,
    ],
    stops: [0.0, 0.45, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Fondo del reproductor de episodios — morado profundo, para distinguirlo
  /// de un vistazo del reproductor en vivo, que es claro.
  static const player = LinearGradient(
    colors: [Color(0xFF6A2575), Color(0xFF4A155C), Color(0xFF2E0B3A)],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Radio player screen background
  static const radioPlayer = LinearGradient(
    colors: [Color(0xFFF8F8FA), Color(0xFFF0E6F2), Color(0xFFF5EAF6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Audio visualizer bars
  static const visualizer = LinearGradient(
    colors: [Color(0xFF7B2E88), Color(0xFFE18F53), Color(0xFFD47A3D)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  /// Mini player background
  static const miniPlayer = LinearGradient(
    colors: [Color(0xFFF5EAF6), Color(0xFFEDEDF2)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

// ─── Spacing Scale (4px base unit) ──────────────────────────────

class MohanaSpacing {
  MohanaSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;

  /// Horizontal screen padding
  static const double screenH = 20;

  /// Card internal padding
  static const double cardPadding = 16;

  /// Vertical space between content sections
  static const double sectionGap = 32;
}

// ─── Border Radius ──────────────────────────────────────────────

class MohanaRadius {
  MohanaRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 100;

  static final smAll = BorderRadius.circular(sm);
  static final mdAll = BorderRadius.circular(md);
  static final lgAll = BorderRadius.circular(lg);
  static final xlAll = BorderRadius.circular(xl);
  static final xxlAll = BorderRadius.circular(xxl);
  static final pillAll = BorderRadius.circular(pill);
}

// ─── Shadows ────────────────────────────────────────────────────

class MohanaShadows {
  MohanaShadows._();

  /// Subtle ambient shadow for cards
  static final ambient = BoxShadow(
    color: MohanaColors.onSurface.withValues(alpha: 0.06),
    offset: const Offset(0, 8),
    blurRadius: 24,
    spreadRadius: -4,
  );

  /// Light card shadow
  static final card = BoxShadow(
    color: MohanaColors.onSurface.withValues(alpha: 0.04),
    offset: const Offset(0, 2),
    blurRadius: 12,
  );

  /// Tonal card shadow — sombra lila para cards blancas sobre el fondo
  /// tintado del home. Las hace "flotar" con identidad de marca.
  static final tonalCard = BoxShadow(
    color: MohanaColors.tertiary.withValues(alpha: 0.16),
    offset: const Offset(0, 6),
    blurRadius: 18,
  );

  /// Elevated element shadow (FABs, dialogs)
  static final elevated = BoxShadow(
    color: MohanaColors.onSurface.withValues(alpha: 0.10),
    offset: const Offset(0, 4),
    blurRadius: 16,
    spreadRadius: -2,
  );

  /// Bottom navigation shadow
  static final bottomNav = BoxShadow(
    color: MohanaColors.onSurface.withValues(alpha: 0.04),
    offset: const Offset(0, -4),
    blurRadius: 16,
  );

  /// Mini player purple glow
  static final miniPlayer = BoxShadow(
    color: MohanaColors.primary.withValues(alpha: 0.15),
    offset: const Offset(0, 4),
    blurRadius: 20,
    spreadRadius: -2,
  );
}

// ─── Pre-built Decorations ──────────────────────────────────────

class MohanaDecorations {
  MohanaDecorations._();

  /// Standard content card
  static BoxDecoration get card => BoxDecoration(
        color: MohanaColors.surface,
        borderRadius: MohanaRadius.lgAll,
        boxShadow: [MohanaShadows.card],
      );

  /// Card blanca con sombra lila, para el feed con fondo tonal (home).
  static BoxDecoration get tonalCard => BoxDecoration(
        color: MohanaColors.surface,
        borderRadius: MohanaRadius.lgAll,
        boxShadow: [MohanaShadows.tonalCard],
      );

  /// Glassmorphism panel (login form, overlays)
  static BoxDecoration get glass => BoxDecoration(
        color: MohanaColors.surfaceContainerLowest.withValues(alpha: 0.85),
        borderRadius: MohanaRadius.xlAll,
        boxShadow: [MohanaShadows.ambient],
      );

  /// Input field container
  static BoxDecoration get inputField => BoxDecoration(
        color: MohanaColors.surfaceContainerLow,
        borderRadius: MohanaRadius.mdAll,
        border: Border.all(color: MohanaColors.inputBorder, width: 1),
      );

  /// Category tag chip
  static BoxDecoration categoryTag(String category) => BoxDecoration(
        color: MohanaCategoryColors.forCategory(category),
        borderRadius: MohanaRadius.smAll,
      );

  /// "EN VIVO" badge
  static BoxDecoration get liveBadge => BoxDecoration(
        color: MohanaColors.enVivoBadge,
        borderRadius: MohanaRadius.smAll,
      );

  /// Profile avatar ring (gradient border)
  static BoxDecoration get avatarRing => BoxDecoration(
        shape: BoxShape.circle,
        gradient: MohanaGradients.avatarRing,
      );

  /// Bottom navigation bar
  static BoxDecoration get bottomNav => BoxDecoration(
        color: MohanaColors.surfaceContainerLowest,
        boxShadow: [MohanaShadows.bottomNav],
      );

  /// Mini player bar
  static BoxDecoration get miniPlayer => BoxDecoration(
        gradient: MohanaGradients.miniPlayer,
        borderRadius: MohanaRadius.lgAll,
        boxShadow: [MohanaShadows.miniPlayer],
      );

  /// Gradient CTA button
  static BoxDecoration get primaryButton => BoxDecoration(
        gradient: MohanaGradients.primaryButton,
        borderRadius: MohanaRadius.pillAll,
        boxShadow: [
          BoxShadow(
            color: MohanaColors.primary.withValues(alpha: 0.30),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      );

  /// Outlined secondary button
  static BoxDecoration get outlinedButton => BoxDecoration(
        color: Colors.transparent,
        borderRadius: MohanaRadius.pillAll,
        border: Border.all(color: MohanaColors.primary, width: 1.5),
      );

  /// Social login button (Google, Facebook)
  static BoxDecoration get socialButton => BoxDecoration(
        color: MohanaColors.surface,
        borderRadius: MohanaRadius.mdAll,
        border: Border.all(color: MohanaColors.outlineVariant, width: 1),
      );

  /// Image upload dashed area (Publish Note screen)
  static BoxDecoration get uploadArea => BoxDecoration(
        color: MohanaColors.surfaceContainerLow,
        borderRadius: MohanaRadius.lgAll,
        border: Border.all(
          color: MohanaColors.outlineVariant,
          width: 1.5,
        ),
      );

  /// Section divider line
  static BoxDecoration get dividerLine => const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MohanaColors.divider, width: 1),
        ),
      );
}
