import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
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
            ClipRRect(
              borderRadius: MohanaRadius.mdAll,
              child: p.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: p.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _iconFallback(),
                      errorWidget: (_, _, _) => _iconFallback(),
                    )
                  : _iconFallback(),
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
                      Text(
                        'PODCAST DESTACADO',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: MohanaCategoryColors.podcastNuevo,
                          letterSpacing: 0.5,
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
                    p.description,
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

  Widget _iconFallback() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: MohanaColors.surfaceContainerLow,
        borderRadius: MohanaRadius.mdAll,
      ),
      child: const Icon(
        Icons.mic,
        color: MohanaColors.primary,
        size: 28,
      ),
    );
  }
}
