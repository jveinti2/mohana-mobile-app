import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/podcast_episode.dart';
import '../models/podcast_item.dart';
import '../services/audio_service.dart';
import '../widgets/audio_player_bar.dart';
import '../widgets/entrance.dart';
import 'podcast_detail_screen.dart';
import 'radio_screen.dart';

/// Biblioteca de podcasts estilo Spotify / YouTube: programa destacado,
/// carrusel de episodios recientes y una cuadrícula con todos los programas.
class PodcastsLibraryScreen extends StatelessWidget {
  final List<PodcastItem> podcasts;

  const PodcastsLibraryScreen({super.key, required this.podcasts});

  /// Episodio más reciente de cada programa, ordenado por fecha (desc).
  List<_RecentEntry> get _recents {
    final entries = <_RecentEntry>[];
    for (final p in podcasts) {
      if (p.episodeList.isNotEmpty) {
        entries.add(_RecentEntry(program: p, episode: p.episodeList.first));
      }
    }
    entries.sort((a, b) {
      final da = a.episode.date;
      final db = b.episode.date;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return entries.take(10).toList();
  }

  void _openProgram(BuildContext context, PodcastItem p,
      {PodcastEpisode? episode}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PodcastDetailScreen(program: p, initialEpisode: episode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featured = podcasts.isNotEmpty ? podcasts.first : null;
    final recents = _recents;

    return Container(
      decoration: const BoxDecoration(gradient: MohanaGradients.homeTonal),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: MohanaColors.tertiary),
          title: Text(
            'Podcasts',
            style: GoogleFonts.breeSerif(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: MohanaColors.tertiary,
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: AudioPlayerBar(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RadioScreen()),
            ),
          ),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: MohanaSpacing.sm)),

            // Destacado
            if (featured != null) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: MohanaSpacing.base),
                  child: SectionEyebrow('Destacado'),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: MohanaSpacing.md),
              ),
              SliverToBoxAdapter(
                child: StaggeredEntrance(
                  index: 0,
                  child: _FeaturedCard(
                    program: featured,
                    onTap: () => _openProgram(context, featured),
                    onPlay: () {
                      if (featured.episodeList.isNotEmpty) {
                        final ep = featured.episodeList.first;
                        AudioService().playEpisode(
                          ep.audioUrl,
                          title: ep.title,
                          subtitle: featured.title,
                        );
                      }
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: MohanaSpacing.xl),
              ),
            ],

            // Episodios recientes (carrusel)
            if (recents.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: MohanaSpacing.base),
                  child: SectionEyebrow('Episodios recientes'),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: MohanaSpacing.md),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 178,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: MohanaSpacing.base),
                    itemCount: recents.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: MohanaSpacing.md),
                    itemBuilder: (_, i) => _RecentCard(
                      entry: recents[i],
                      onTap: () => _openProgram(
                        context,
                        recents[i].program,
                        episode: recents[i].episode,
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: MohanaSpacing.xl),
              ),
            ],

            // Todos los programas (grid)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: MohanaSpacing.base),
                child: SectionEyebrow('Todos los programas'),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: MohanaSpacing.md),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: MohanaSpacing.base,
              ),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: MohanaSpacing.md,
                  crossAxisSpacing: MohanaSpacing.md,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _GridCard(
                    program: podcasts[i],
                    onTap: () => _openProgram(context, podcasts[i]),
                  ),
                  childCount: podcasts.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: MohanaSpacing.xxl),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentEntry {
  final PodcastItem program;
  final PodcastEpisode episode;
  const _RecentEntry({required this.program, required this.episode});
}

// ─── Cards ──────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final PodcastItem program;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const _FeaturedCard({
    required this.program,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.base),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(MohanaSpacing.md),
          decoration: MohanaDecorations.tonalCard,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: MohanaRadius.lgAll,
                child: _Cover(url: program.imageUrl, size: 96),
              ),
              const SizedBox(width: MohanaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LO MÁS ESCUCHADO',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: MohanaColors.secondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: MohanaSpacing.xs),
                    Text(
                      program.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.breeSerif(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: MohanaColors.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: MohanaSpacing.sm),
                    GestureDetector(
                      onTap: onPlay,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MohanaSpacing.base,
                          vertical: MohanaSpacing.sm,
                        ),
                        decoration: MohanaDecorations.primaryButton,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: MohanaSpacing.xs),
                            Text(
                              'Reproducir',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
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

class _RecentCard extends StatelessWidget {
  final _RecentEntry entry;
  final VoidCallback onTap;

  const _RecentCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: MohanaRadius.lgAll,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: MohanaRadius.lgAll,
                  boxShadow: [MohanaShadows.tonalCard],
                ),
                child: _Cover(
                  url: entry.episode.imageUrl.isNotEmpty
                      ? entry.episode.imageUrl
                      : entry.program.imageUrl,
                  size: 130,
                ),
              ),
            ),
            const SizedBox(height: MohanaSpacing.sm),
            Text(
              entry.program.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: MohanaColors.onSurface,
                height: 1.2,
              ),
            ),
            const SizedBox(height: MohanaSpacing.xxs),
            Text(
              entry.episode.duration ?? 'Nuevo episodio',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: MohanaColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final PodcastItem program;
  final VoidCallback onTap;

  const _GridCard({required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(MohanaSpacing.sm),
        decoration: MohanaDecorations.tonalCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: MohanaRadius.mdAll,
                child: _Cover(url: program.imageUrl, size: double.infinity),
              ),
            ),
            const SizedBox(height: MohanaSpacing.sm),
            Text(
              program.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: MohanaColors.onSurface,
                height: 1.2,
              ),
            ),
            const SizedBox(height: MohanaSpacing.xxs),
            Text(
              program.episodes != null
                  ? '${program.episodes} episodios'
                  : program.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: MohanaColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carátula con fallback al gradiente de marca.
class _Cover extends StatelessWidget {
  final String url;
  final double size;

  const _Cover({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback();
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, _) => _fallback(),
      errorWidget: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(gradient: MohanaGradients.brand),
        child: const Icon(Icons.podcasts, color: Colors.white, size: 32),
      );
}
