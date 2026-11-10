import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';

/// Sección sobre la Organización Femenina Popular.
///
/// El texto es corto a propósito: cuenta de dónde viene la organización y qué
/// es la emisora, sin convertirse en un folleto. Las cifras están pendientes de
/// que la OFP las confirme (ver `PUBLICACION_IOS.md`).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Hitos que resumen la trayectoria. Van en un [Wrap] para que al ampliar la
  /// letra del sistema caigan en varias líneas en vez de desbordarse.
  static const _hitos = <({String dato, String etiqueta})>[
    (dato: '1972', etiqueta: 'Desde'),
    (dato: '+10', etiqueta: 'Municipios'),
    (dato: '2.700', etiqueta: 'Mujeres'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: MohanaGradients.homeTonal),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Nosotras',
            style: GoogleFonts.breeSerif(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: MohanaColors.tertiary,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MohanaSpacing.screenH,
            MohanaSpacing.sm,
            MohanaSpacing.screenH,
            MohanaSpacing.huge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _Encabezado(),
              SizedBox(height: MohanaSpacing.xl),
              _Hitos(),
              SizedBox(height: MohanaSpacing.xl),
              _Historia(),
              SizedBox(height: MohanaSpacing.base),
              _LaEmisora(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logotipo de la OFP sobre una tarjeta blanca, con el nombre completo debajo.
class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: MohanaDecorations.tonalCard,
      padding: const EdgeInsets.symmetric(
        horizontal: MohanaSpacing.cardPadding,
        vertical: MohanaSpacing.xl,
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo_ofp.png',
            height: 80,
            // Se pinta a 80 dp: evita decodificar el asset a tamaño completo.
            cacheHeight: 240,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: MohanaSpacing.base),
          Text(
            'Organización Femenina Popular',
            textAlign: TextAlign.center,
            style: GoogleFonts.breeSerif(
              fontSize: 22,
              height: 1.25,
              color: MohanaColors.tertiary,
            ),
          ),
          const SizedBox(height: MohanaSpacing.xs),
          Text(
            'Barrancabermeja · Magdalena Medio',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: MohanaColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tres cifras que resumen la trayectoria.
class _Hitos extends StatelessWidget {
  const _Hitos();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: MohanaSpacing.md,
      runSpacing: MohanaSpacing.md,
      children: [
        for (final hito in AboutScreen._hitos)
          Container(
            decoration: BoxDecoration(
              color: MohanaColors.surface.withValues(alpha: 0.72),
              borderRadius: MohanaRadius.lgAll,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: MohanaSpacing.base,
              vertical: MohanaSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hito.dato,
                  style: GoogleFonts.breeSerif(
                    fontSize: 22,
                    color: MohanaColors.primary,
                  ),
                ),
                Text(
                  hito.etiqueta,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: MohanaColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// De dónde viene la organización, en dos párrafos.
class _Historia extends StatelessWidget {
  const _Historia();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: MohanaDecorations.tonalCard,
      padding: const EdgeInsets.all(MohanaSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiénes somos',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: MohanaColors.tertiary,
            ),
          ),
          const SizedBox(height: MohanaSpacing.md),
          const _Parrafo(
            'Somos una organización de mujeres que nació en 1972 en el '
            'nororiente de Barrancabermeja. Empezamos reuniéndonos en los '
            'clubes de amas de casa y, desde 1988, caminamos de forma '
            'autónoma.',
          ),
          const SizedBox(height: MohanaSpacing.md),
          const _Parrafo(
            'En medio del conflicto armado del Magdalena Medio hemos sostenido '
            'la vida. En 1996 impulsamos el Movimiento Social de Mujeres contra '
            'la Guerra y por la Paz, y hoy las Casas de la Mujer reúnen a miles '
            'de mujeres en más de diez municipios de la región.',
          ),
        ],
      ),
    );
  }
}

/// Qué es la emisora dentro de la organización.
class _LaEmisora extends StatelessWidget {
  const _LaEmisora();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: MohanaGradients.brand,
        borderRadius: MohanaRadius.lgAll,
        boxShadow: [MohanaShadows.tonalCard],
      ),
      padding: const EdgeInsets.all(MohanaSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.radio_rounded,
                size: 20,
                color: MohanaColors.onPrimary,
              ),
              const SizedBox(width: MohanaSpacing.sm),
              Flexible(
                child: Text(
                  'La Mohana 91.2 FM',
                  style: GoogleFonts.breeSerif(
                    fontSize: 18,
                    color: MohanaColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MohanaSpacing.sm),
          Text(
            'Nuestra emisora: la voz con la que contamos lo que pasa en el '
            'territorio y lo que las mujeres tenemos para decir.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.55,
              color: MohanaColors.onPrimary.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

/// Párrafo de cuerpo con el interlineado del resto de la app.
class _Parrafo extends StatelessWidget {
  const _Parrafo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: GoogleFonts.poppins(
        fontSize: 14,
        height: 1.6,
        color: MohanaColors.onSurface,
      ),
    );
  }
}
