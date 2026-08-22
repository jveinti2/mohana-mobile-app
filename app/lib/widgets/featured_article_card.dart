import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'mohana_cover.dart';
import '../models/news_article.dart';

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
      height: 280,
      decoration: BoxDecoration(
        borderRadius: MohanaRadius.lgAll,
        boxShadow: [MohanaShadows.tonalCard],
      ),
      child: ClipRRect(
        borderRadius: MohanaRadius.lgAll,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            MohanaCover(url: article.imageUrl),
            // Dark gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.3, 1.0],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(MohanaSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MohanaTheme.categoryTag(article.category),
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
