import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
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
        // Header
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
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
                      const Icon(Icons.chevron_right,
                          color: MohanaColors.tertiary, size: 18),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: MohanaSpacing.xs),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
          child: Text(
            'La emisora de las mujeres · 91.2 FM',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: MohanaColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: MohanaSpacing.base),

        // Horizontal scroll of podcast cards
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
            itemCount: podcasts.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: MohanaSpacing.md),
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

class _PodcastProgramCard extends StatelessWidget {
  final PodcastItem podcast;
  final VoidCallback? onTap;

  const _PodcastProgramCard({required this.podcast, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(MohanaSpacing.md),
        decoration: BoxDecoration(
          color: MohanaColors.surface,
          borderRadius: MohanaRadius.lgAll,
          boxShadow: [MohanaShadows.tonalCard],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or icon
            ClipRRect(
              borderRadius: MohanaRadius.smAll,
              child: podcast.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: podcast.imageUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _iconFallback(),
                      errorWidget: (_, _, _) => _iconFallback(),
                    )
                  : _iconFallback(),
            ),
            const Spacer(),
            Text(
              podcast.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: MohanaColors.onSurface,
                height: 1.2,
              ),
            ),
            const SizedBox(height: MohanaSpacing.xxs),
            Text(
              podcast.episodes != null
                  ? '${podcast.episodes} episodios'
                  : podcast.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: MohanaColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconFallback() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: MohanaColors.primary.withValues(alpha: 0.12),
        borderRadius: MohanaRadius.smAll,
      ),
      child: const Icon(Icons.podcasts, size: 20, color: MohanaColors.primary),
    );
  }
}
