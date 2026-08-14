import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/news_article.dart';

class ArticleDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat("d 'de' MMMM, yyyy", 'es');

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero image with back button
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: MohanaColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: article.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: article.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: MohanaColors.surfaceContainerHigh,
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: MohanaColors.primary,
                        child: const Icon(Icons.image_outlined,
                            size: 48, color: Colors.white54),
                      ),
                    )
                  : Container(
                      color: MohanaColors.primary,
                      child: const Icon(Icons.article_outlined,
                          size: 64, color: Colors.white54),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(MohanaSpacing.screenH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: MohanaSpacing.md),

                  // Category tag
                  MohanaTheme.categoryTag(article.category),
                  const SizedBox(height: MohanaSpacing.md),

                  // Title
                  Text(
                    article.title,
                    style: GoogleFonts.breeSerif(
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                      color: MohanaColors.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: MohanaSpacing.base),

                  // Author & date
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: MohanaColors.primary50,
                        child: Icon(Icons.person,
                            size: 18, color: MohanaColors.primary),
                      ),
                      const SizedBox(width: MohanaSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.author,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: MohanaColors.onSurface,
                              ),
                            ),
                            Text(
                              dateFormat.format(article.publishedAt),
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

                  const SizedBox(height: MohanaSpacing.xl),
                  const Divider(),
                  const SizedBox(height: MohanaSpacing.xl),

                  // Body
                  Text(
                    article.body.isNotEmpty
                        ? article.body
                        : article.summary,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: MohanaColors.onSurface,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
