import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/hygraph_config.dart';
import '../config/ivoox_config.dart';
import '../config/theme.dart';
import '../models/news_article.dart';
import '../models/podcast_item.dart';
import '../services/content_service.dart';
import '../services/ivoox_service.dart';
import '../services/schedule_service.dart';
import '../widgets/mohana_app_bar.dart';
import '../widgets/featured_article_card.dart';
import '../widgets/article_list_card.dart';
import '../widgets/load_notice.dart';
import '../widgets/podcast_card.dart';
import '../widgets/ivoox_section.dart';
import '../widgets/entrance.dart';
import '../widgets/feed_skeleton.dart';
import '../widgets/mohana_bottom_nav.dart';
import '../widgets/on_air_card.dart';
import 'article_detail_screen.dart';
import 'cms_diagnostic_screen.dart';
import 'podcast_detail_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  HomeContent? _content;
  bool _loading = true;
  String? _error;

  /// Catálogo de programas de iVoox. Solo nombre y carátula: los episodios se
  /// descargan al abrir cada programa, no en el arranque.
  List<IvooxProgramRef> _catalog = const [];
  bool _podcastsLoading = false;
  bool _catalogStale = false;

  /// IDs de artículos ya animados, para no re-animar al volver a hacer scroll.
  final Set<String> _seenIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  /// Carga en dos fases para que la pantalla no espere a lo más lento:
  /// primero los artículos del CMS (y muere el esqueleto), después el
  /// catálogo de iVoox, que va rellenando la fila de podcasts según llega.
  Future<void> _loadContent({bool force = false}) async {
    setState(() => _podcastsLoading = true);

    // La parrilla es un archivo pequeño y opcional: se pide aparte para que un
    // fallo suyo no arrastre al resto del feed.
    unawaited(
      ScheduleService.load(forceRefresh: force).then((_) {
        if (mounted) setState(() {});
      }),
    );

    if (!HygraphConfig.isConfigured) {
      setState(() {
        _loading = false;
        _error = 'CMS no configurado';
      });
    } else {
      try {
        final content = await ContentService.loadHomeContent(
          forceRefresh: force,
        );
        if (!mounted) return;
        setState(() {
          _content = content;
          _loading = false;
          _error = null;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }

    // Los podcasts vienen de iVoox: se cargan aunque el CMS falle.
    await _loadCatalog(force: force);
  }

  Future<void> _loadCatalog({bool force = false}) async {
    final catalog = await IvooxService.loadCatalog(
      forceRefresh: force,
      // Cada página del catálogo que llega se pinta ya, sin esperar al resto.
      onProgress: (partial) {
        if (!mounted) return;
        setState(() => _catalog = partial);
      },
    );
    if (!mounted) return;
    setState(() {
      _catalog = catalog.programs;
      _catalogStale = catalog.isStale;
      _podcastsLoading = false;
    });
  }

  /// Programas del catálogo como tarjetas (con episodios si ya se cargaron).
  List<PodcastItem> get _podcasts => [
    for (final ref in _catalog) IvooxService.stubFor(ref),
  ];

  /// Podcast destacado: el primero del catálogo de iVoox (la emisora lo ordena
  /// por actividad reciente). Si iVoox no respondió, el del CMS.
  PodcastItem? get _featuredPodcast => _catalog.isNotEmpty
      ? IvooxService.stubFor(_catalog.first)
      : _content?.podcastDestacado;

  void _openArticle(NewsArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
    );
  }

  void _openPodcast(PodcastItem podcast) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PodcastDetailScreen(program: podcast)),
    );
  }

  /// "Ver todos" lleva a la pestaña de Podcasts, no a otra pantalla apilada.
  void _openPodcastLibrary() => AppTabs.go(MohanaTab.podcasts);

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

    final podcasts = _podcasts;

    return RefreshIndicator(
      color: MohanaColors.primary,
      // No se vuelve al esqueleto completo: el indicador ya da feedback y el
      // contenido actual sigue visible mientras se revalida.
      onRefresh: () => _loadContent(force: true),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: MohanaSpacing.md)),

          // El directo primero: es una emisora, y hasta ahora el stream solo
          // vivía en la barra de abajo.
          const SliverToBoxAdapter(
            child: StaggeredEntrance(index: 0, child: OnAirCard()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: MohanaSpacing.xl)),

          // Featured article (titular)
          if (content.titular != null) ...[
            const SliverToBoxAdapter(
              child: StaggeredEntrance(
                index: 1,
                child: SectionEyebrow('Destacado'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: MohanaSpacing.md)),
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                index: 2,
                child: PressableScale(
                  onTap: () => _openArticle(content.titular!),
                  child: FeaturedArticleCard(article: content.titular!),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: MohanaSpacing.xl)),
          ],

          // Article list
          if (content.articulos.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: StaggeredEntrance(
                index: 3,
                child: SectionEyebrow('Lo más reciente'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: MohanaSpacing.md)),
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

          // Podcasts: cabecera + fila. Mientras llega el catálogo se muestra
          // su propio esqueleto, sin bloquear el resto del feed.
          if (_podcastsLoading && podcasts.isEmpty) ...[
            const SliverToBoxAdapter(child: IvooxSectionHeader()),
            const SliverToBoxAdapter(
              child: SizedBox(height: MohanaSpacing.base),
            ),
            const SliverToBoxAdapter(child: PodcastRowSkeleton()),
          ] else if (podcasts.isNotEmpty)
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                index: 0,
                child: IvooxSection(
                  podcasts: podcasts,
                  onPodcastTap: _openPodcast,
                  onSeeAll: _openPodcastLibrary,
                ),
              ),
            ),

          if (_catalogStale) ...[
            const SliverToBoxAdapter(
              child: SizedBox(height: MohanaSpacing.base),
            ),
            SliverToBoxAdapter(
              child: LoadNotice(
                message: 'No se pudo actualizar la lista de programas',
                detail: 'Se muestra la última que se guardó en el dispositivo.',
                onRetry: () => _loadCatalog(force: true),
                busy: _podcastsLoading,
              ),
            ),
          ],

          if (podcasts.isNotEmpty || _podcastsLoading)
            const SliverToBoxAdapter(child: SizedBox(height: MohanaSpacing.xl)),

          // Featured podcast
          if (_featuredPodcast != null)
            SliverToBoxAdapter(
              child: StaggeredEntrance(
                index: 1,
                child: PressableScale(
                  onTap: () => _openPodcast(_featuredPodcast!),
                  child: PodcastCard(podcast: _featuredPodcast),
                ),
              ),
            ),

          // Bottom clearance
          const SliverToBoxAdapter(child: SizedBox(height: MohanaSpacing.xxl)),
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
        await _loadContent(force: true);
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
                              builder: (_) => const CmsDiagnosticScreen(),
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
