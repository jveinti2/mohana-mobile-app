import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/news_article.dart';
import '../utils/dates.dart';
import 'mohana_cover.dart';

class FeaturedArticleCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback? onTap;

  const FeaturedArticleCard({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
      // 280 es el alto de diseño, pero como mínimo, no como tope: con la letra
      // ampliada por accesibilidad el bloque de texto pasaba de esa altura y
      // se salía de la tarjeta. Ahora la tarjeta crece lo que haga falta.
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        borderRadius: MohanaRadius.lgAll,
        boxShadow: [MohanaShadows.tonalCard],
      ),
      child: ClipRRect(
        borderRadius: MohanaRadius.lgAll,
        child: Stack(
          // La imagen se estira a lo que mida el texto; el texto se apoya
          // abajo, que es donde estaba con el alto fijo.
          alignment: Alignment.bottomLeft,
          children: [
            // Image
            Positioned.fill(child: MohanaCover(url: article.imageUrl)),
            // Dark gradient overlay
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.3, 1.0],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(MohanaSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // La firma y la fecha acompañan a la categoría: en un
                  // titular, quién lo escribe y cuándo es parte de la noticia.
                  Row(
                    children: [
                      // Las dos ceden: con la letra ampliada, la etiqueta
                      // sola ya no cabía en el ancho de la tarjeta.
                      Flexible(
                        child: MohanaTheme.categoryTag(article.category),
                      ),
                      const SizedBox(width: MohanaSpacing.sm),
                      Flexible(
                        child: Text(
                          '${fechaRelativa(article.publishedAt)} · ${article.author}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MohanaSpacing.sm),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.breeSerif(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: MohanaSpacing.xs),
                  Text(
                    article.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: MohanaSpacing.sm),
                  Text(
                    'Leer Más  →',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
