import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';

/// Sección sobre la Organización Femenina Popular.
///
/// El contenido está por definir: de momento solo queda la sección creada y
/// accesible desde la navegación.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(MohanaSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo_ofp.png',
                  height: 72,
                  cacheHeight: 216,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: MohanaSpacing.lg),
                Text(
                  'Próximamente',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MohanaColors.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
