import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'mohana_cover.dart';
import '../models/podcast_item.dart';

class PodcastCard extends StatelessWidget {
  final PodcastItem? podcast;
  final VoidCallback? onTap;

  const PodcastCard({super.key, this.podcast, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (podcast == null) return const SizedBox.shrink();
    final p = podcast!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
        padding: const EdgeInsets.all(MohanaSpacing.base),
        decoration: MohanaDecorations.tonalCard,
        child: Row(
          children: [
            // Podcast cover or icon
            MohanaCover.square(
              url: p.imageUrl,
              size: 56,
              borderRadius: MohanaRadius.mdAll,
            ),
            const SizedBox(width: MohanaSpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: MohanaCategoryColors.podcastNuevo,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: MohanaSpacing.xs),
                      // Flexible: la etiqueta es larga y, junto a la carátula
                      // de 56, no cabía en un teléfono estrecho ni con la
                      // letra de fábrica.
                      Flexible(
                        child: Text(
                          'PODCAST DESTACADO',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: MohanaCategoryColors.podcastNuevo,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MohanaSpacing.xs),
                  Text(
                    p.title,
                    style: GoogleFonts.breeSerif(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MohanaColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: MohanaSpacing.xxs),
                  Text(
                    _subtitle(p),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
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

  /// Descripción del programa; si viene del catálogo (aún sin feed) se usa el
  /// conteo de episodios y, en último caso, una invitación a escucharlo.
  String _subtitle(PodcastItem p) {
    if (p.description.isNotEmpty) return p.description;
    final label = p.episodesLabel;
    return label.isNotEmpty ? label : 'Escucha los episodios del programa';
  }
}
