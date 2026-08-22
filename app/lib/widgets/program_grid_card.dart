import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/podcast_item.dart';
import 'entrance.dart';
import 'mohana_cover.dart';

/// Tarjeta de un programa dentro de la cuadrícula de "Todos los programas".
///
/// Su alto se calcula ([extentFor]) en vez de dejarlo a una proporción fija:
/// con una proporción, el conteo de episodios se salía de la tarjeta en cuanto
/// el título ocupaba dos líneas o el sistema ampliaba la letra.
class ProgramGridCard extends StatelessWidget {
  final PodcastItem program;
  final VoidCallback onTap;

  const ProgramGridCard({super.key, required this.program, required this.onTap});

  static const _padding = MohanaSpacing.sm;
  static const _titleSize = 13.0;
  static const _subtitleSize = 11.0;
  static const _titleLines = 2;

  /// Alto que necesita una tarjeta: la carátula cuadrada más el bloque de
  /// texto. Se calcula con el tamaño de letra real del sistema para que nada
  /// se salga de la tarjeta.
  static double extentFor(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final gridWidth =
        MediaQuery.sizeOf(context).width - MohanaSpacing.base * 2;
    final cell = (gridWidth - MohanaSpacing.md) / 2;
    final cover = cell - _padding * 2;
    final title = scaler.scale(_titleSize) * 1.25 * _titleLines;
    final subtitle = scaler.scale(_subtitleSize) * 1.4;
    return _padding * 2 +
        cover +
        MohanaSpacing.sm +
        title +
        MohanaSpacing.xxs +
        subtitle;
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(_padding),
        decoration: MohanaDecorations.tonalCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: MohanaRadius.mdAll,
                child: MohanaCover(url: program.imageUrl),
              ),
            ),
            const SizedBox(height: MohanaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      program.title,
                      maxLines: _titleLines,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: _titleSize,
                        fontWeight: FontWeight.w700,
                        color: MohanaColors.onSurface,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: MohanaSpacing.xxs),
                  Text(
                    program.episodesLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: _subtitleSize,
                      color: MohanaColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
