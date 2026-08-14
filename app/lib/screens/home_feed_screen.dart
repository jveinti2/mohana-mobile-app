import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/drive_config.dart';
import '../config/theme.dart';
import '../models/news_article.dart';
import '../models/podcast_item.dart';
import '../services/content_service.dart';
import '../services/ivoox_service.dart';
import '../widgets/mohana_app_bar.dart';
import '../widgets/featured_article_card.dart';
import '../widgets/article_list_card.dart';
import '../widgets/podcast_card.dart';
import '../widgets/ivoox_section.dart';
import '../widgets/entrance.dart';
import '../widgets/feed_skeleton.dart';
import 'article_detail_screen.dart';
import 'drive_diagnostic_screen.dart';
import 'podcast_detail_screen.dart';
import 'podcasts_library_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  HomeContent? _content;
  bool _loading = true;
  String? _error;

  /// IDs de artículos ya animados, para no re-animar al volver a hacer scroll.
  final Set<String> _seenIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    if (!DriveConfig.isConfigured) {
      setState(() {
        _loading = false;
        _error = 'Drive no configurado';
      });
      return;
    }

    try {
      final content = await ContentService.loadHomeContent();

      // Podcasts desde iVoox (reemplazan los de Drive si la carga funciona).
      // En web puede fallar por CORS; en ese caso se mantienen los de Drive.
      var podcasts = content.podcasts;
      var podcastDestacado = content.podcastDestacado;
      try {
        final ivoox = await IvooxService.fetchPrograms();
        if (ivoox.isNotEmpty) {
          podcasts = ivoox;
          podcastDestacado = ivoox.first;
        }
      } catch (_) {
        // Silencioso: se conserva el contenido de Drive como respaldo.
      }

      final merged = HomeContent(
        titular: content.titular,
        articulos: content.articulos,
        podcasts: podcasts,
        podcastDestacado: podcastDestacado,
      );

      if (mounted) {
        setState(() {
          _content = merged;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _openArticle(NewsArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArticleDetailScreen(article: article),
      ),
    );
  }

  void _openPodcast(PodcastItem podcast) {
    if (podcast.episodeList.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PodcastDetailScreen(program: podcast),
      ),
    );
  }

  void _openPodcastLibrary() {
    final podcasts = _content?.podcasts ?? const [];
    if (podcasts.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PodcastsLibraryScreen(podcasts: podcasts),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: MohanaGradients.homeTonal),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const MohanaAppBar(),
        body: _loading ? _buildLoading() : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return const FeedSkeleton();
  }

  Widget _buildContent() {
    final content = _content;
    if (content == null || _error != null) return _buildEmpty();

    return RefreshIndicator(
      color: MohanaColors.primary,
      onRefresh: () async {
        setState(() => _loading = true);
        await _loadContent();
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(height: MohanaSpacing.base),
          ),

          // Featured article (titular)
          if (content.titular != null) ...[
            const SliverToBoxAdapter(
              child: StaggeredEntrance(
                index: 0,
                child: SectionEyebrow('Destacado'),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: MohanaSpacing.md),
            ),
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                index: 1,
                child: PressableScale(
                  onTap: () => _openArticle(content.titular!),
                  child: FeaturedArticleCard(article: content.titular!),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: MohanaSpacing.xl),
            ),
          ],

          // Article list
          if (content.articulos.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: StaggeredEntrance(
                index: 2,
                child: SectionEyebrow('Lo más reciente'),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: MohanaSpacing.md),
            ),
            SliverList.separated(
              itemCount: content.articulos.length,
              itemBuilder: (_, index) {
                final article = content.articulos[index];
                final firstSeen = _seenIds.add(article.id);
                return StaggeredEntrance(
                  index: index,
                  animate: firstSeen,
                  child: PressableScale(
                    onTap: () => _openArticle(article),
                    child: ArticleListCard(article: article),
                  ),
                );
              },
              separatorBuilder: (_, _) =>
                  const SizedBox(height: MohanaSpacing.base),
            ),
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: MohanaSpacing.sectionGap),
          ),

          // Podcasts section
          if (content.podcasts.isNotEmpty)
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                index: 0,
                child: IvooxSection(
                  podcasts: content.podcasts,
                  onPodcastTap: _openPodcast,
                  onSeeAll: _openPodcastLibrary,
                ),
              ),
            ),

          if (content.podcasts.isNotEmpty)
            const SliverToBoxAdapter(
              child: SizedBox(height: MohanaSpacing.xl),
            ),

          // Featured podcast
          if (content.podcastDestacado != null)
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                index: 1,
                child: PressableScale(
                  onTap: () => _openPodcast(content.podcastDestacado!),
                  child: PodcastCard(podcast: content.podcastDestacado),
                ),
              ),
            ),

          // Bottom clearance
          const SliverToBoxAdapter(
            child: SizedBox(height: MohanaSpacing.xxl),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      color: MohanaColors.primary,
      onRefresh: () async {
        setState(() {
          _loading = true;
          _error = null;
        });
        await _loadContent();
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(MohanaSpacing.base),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _error != null ? Icons.cloud_off : Icons.article_outlined,
                      size: 48,
                      color: MohanaColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: MohanaSpacing.base),
                    Text(
                      _error != null
                          ? 'No se pudo cargar el contenido'
                          : 'No hay contenido disponible',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: MohanaColors.onSurfaceVariant,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: MohanaSpacing.sm),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 360),
                        padding: const EdgeInsets.all(MohanaSpacing.sm),
                        decoration: BoxDecoration(
                          color: MohanaColors.error.withValues(alpha: 0.08),
                          borderRadius: MohanaRadius.smAll,
                        ),
                        child: SelectableText(
                          _error!,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            color: MohanaColors.error,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: MohanaSpacing.base),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.bug_report_outlined, size: 18),
                        label: const Text('Ver diagnóstico'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DriveDiagnosticScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: MohanaSpacing.sm),
                    Text(
                      'Desliza hacia abajo para reintentar',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: MohanaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
