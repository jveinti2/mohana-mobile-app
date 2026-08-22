import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'mohana_cover.dart';
import '../models/news_article.dart';

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
                Text(
                  article.category.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: categoryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: MohanaSpacing.xs),
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
                const SizedBox(height: MohanaSpacing.xs),
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
                const SizedBox(height: MohanaSpacing.sm),
                Text(
                  'LEER MÁS  →',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MohanaColors.primary,
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
