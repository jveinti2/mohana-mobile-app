import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/news_article.dart';
import '../utils/dates.dart';
import 'mohana_cover.dart';

class ArticleListCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback? onTap;

  const ArticleListCard({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    final categoryColor = MohanaCategoryColors.forCategory(article.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
      padding: const EdgeInsets.all(MohanaSpacing.md),
      decoration: MohanaDecorations.tonalCard,
      child: Row(
        children: [
          // Thumbnail
          MohanaCover.square(
            url: article.imageUrl,
            size: 100,
            borderRadius: MohanaRadius.mdAll,
          ),
          const SizedBox(width: MohanaSpacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categoría y fecha en la misma línea. La fecha estaba en el
                // modelo desde el principio pero no se veía: una noticia de
                // hace ocho meses se leía igual que la de ayer.
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        article.category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: categoryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const _Separador(),
                    // También flexible: con la letra ampliada, una fecha
                    // larga ("14 de marzo de 2025") empujaba la fila fuera de
                    // la tarjeta en un teléfono estrecho.
                    Flexible(
                      child: Text(
                        fechaRelativa(article.publishedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: MohanaColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MohanaSpacing.xs + 2),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.breeSerif(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: MohanaColors.onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: MohanaSpacing.xs + 2),
                // Sin "LEER MÁS": se repetía en cada fila sin decir nada, y la
                // tarjeta entera ya lleva al artículo.
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: MohanaColors.onSurfaceVariant,
                    height: 1.4,
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

/// Punto de separación entre categoría y fecha. Sustituye a la barra vertical:
/// una línea de 1 px partiría la regla de no seccionar con trazos.
class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: MohanaSpacing.xs + 2),
      decoration: const BoxDecoration(
        color: MohanaColors.outlineVariant,
        shape: BoxShape.circle,
      ),
    );
  }
}
