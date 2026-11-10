import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'mohana_cover.dart';
import '../models/podcast_item.dart';

class IvooxSection extends StatelessWidget {
  final List<PodcastItem> podcasts;
  final ValueChanged<PodcastItem>? onPodcastTap;
  final VoidCallback? onSeeAll;

  const IvooxSection({
    super.key,
    required this.podcasts,
    this.onPodcastTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (podcasts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IvooxSectionHeader(onSeeAll: onSeeAll),
        const SizedBox(height: MohanaSpacing.base),

        // Horizontal scroll of podcast cards
        SizedBox(
          height: _PodcastProgramCard.heightFor(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: MohanaSpacing.screenH,
            ),
            itemCount: podcasts.length,
            separatorBuilder: (_, _) => const SizedBox(width: MohanaSpacing.md),
            itemBuilder: (_, index) => _PodcastProgramCard(
              podcast: podcasts[index],
              onTap: () => onPodcastTap?.call(podcasts[index]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Cabecera de la sección de podcasts. Separada del cuerpo para poder
/// mostrarla junto al esqueleto mientras llega el catálogo.
class IvooxSectionHeader extends StatelessWidget {
  final VoidCallback? onSeeAll;

  const IvooxSectionHeader({super.key, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MohanaSpacing.screenH,
          ),
          child: Row(
            children: [
              const Icon(Icons.podcasts, color: MohanaColors.primary, size: 22),
              const SizedBox(width: MohanaSpacing.sm),
              Expanded(
                child: Text(
                  'Podcasts La Mohana',
                  style: GoogleFonts.breeSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MohanaColors.onSurface,
                  ),
                ),
              ),
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Row(
                    children: [
                      Text(
                        'Ver todos',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: MohanaColors.tertiary,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: MohanaColors.tertiary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: MohanaSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MohanaSpacing.screenH,
          ),
          child: Text(
            'La emisora de las mujeres · 91.2 FM',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: MohanaColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de un programa en la fila del home.
///
/// La carátula es lo único que hace reconocible un programa de un vistazo, así
/// que manda: ocupa la tarjeta entera en vez de ir a 36 px dentro de una caja
/// blanca. Al quitar la caja, la tarjeta queda igual que la del carrusel de la
/// biblioteca: una sola forma para el mismo contenido en dos sitios.
class _PodcastProgramCard extends StatelessWidget {
  final PodcastItem podcast;
  final VoidCallback? onTap;

  const _PodcastProgramCard({required this.podcast, this.onTap});

  static const _cover = 130.0;
  static const _titleSize = 12.0;
  static const _subtitleSize = 10.0;

  /// Alto de la fila: carátula más el bloque de texto de dos líneas.
  ///
  /// Se calcula con el tamaño de letra real del sistema, igual que en
  /// [ProgramGridCard]: como constante se quedaba corto —hasta con la letra de
  /// fábrica— y el conteo de episodios se salía de la tarjeta.
  static double heightFor(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return _cover +
        MohanaSpacing.sm +
        scaler.scale(_titleSize) * 1.25 * 2 +
        2 +
        scaler.scale(_subtitleSize) * 1.4 +
        // Un pelo de holgura: el alto de línea real de una tipografía no cae
        // nunca exactamente en el múltiplo que se calcula aquí.
        4;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _cover,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: MohanaRadius.mdAll,
                boxShadow: [MohanaShadows.tonalCard],
              ),
              child: MohanaCover.square(
                url: podcast.imageUrl,
                size: _cover,
                borderRadius: MohanaRadius.mdAll,
              ),
            ),
            const SizedBox(height: MohanaSpacing.sm),
            Text(
              podcast.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: _titleSize,
                fontWeight: FontWeight.w700,
                color: MohanaColors.onSurface,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              podcast.episodesLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: _subtitleSize,
                fontWeight: FontWeight.w500,
                color: MohanaColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
