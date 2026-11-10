import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/ivoox_config.dart';
import '../config/theme.dart';
import '../models/podcast_episode.dart';
import '../models/podcast_item.dart';
import '../services/audio_service.dart';
import '../services/ivoox_service.dart';
import '../services/resume_store.dart';
import '../utils/dates.dart';
import '../widgets/audio_player_bar.dart';
import '../widgets/entrance.dart';
import '../widgets/feed_skeleton.dart';
import '../widgets/load_notice.dart';
import '../widgets/mohana_cover.dart';
import '../widgets/program_grid_card.dart';
import 'episode_player_screen.dart';
import 'podcast_detail_screen.dart';

/// Biblioteca de podcasts estilo Spotify / YouTube: programa destacado,
/// carrusel de episodios recientes y una cuadrícula con todos los programas.
///
/// La cuadrícula se llena por páginas a medida que se hace scroll, y los feeds
/// (que es lo pesado) solo se descargan para los programas que el usuario
/// llega a ver.
class PodcastsLibraryScreen extends StatefulWidget {
  /// `true` cuando vive dentro de la navegación por pestañas: no lleva flecha
  /// de volver ni reproductor propio, los pone el contenedor.
  final bool embedded;

  const PodcastsLibraryScreen({super.key, this.embedded = false});

  @override
  State<PodcastsLibraryScreen> createState() => _PodcastsLibraryScreenState();
}

class _PodcastsLibraryScreenState extends State<PodcastsLibraryScreen> {
  /// Programas por página de la cuadrícula.
  static const _pageSize = 12;

  int _visible = _pageSize;
  bool _loadingMore = false;
  bool _loadingCatalog = false;

  late List<IvooxProgramRef> _catalog;

  final _searchController = TextEditingController();

  /// Texto del buscador. Con 27 programas de nombres largos, recorrer la
  /// cuadrícula a ciegas era la única forma de encontrar algo.
  String _query = '';

  /// Programas cuyo feed ya se descargó, por feedId.
  final Map<String, PodcastItem> _loaded = {};
  final Set<String> _requested = {};
  final List<IvooxProgramRef> _failed = [];
  bool _fetchingFeeds = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _catalog = const [];
    _loadCatalog();
    // El avance del episodio se anota mientras suena: al pausar o cambiar de
    // pista hay que repintar la tarjeta de "seguir escuchando".
    AudioService().addListener(_onAudioChanged);
  }

  @override
  void dispose() {
    AudioService().removeListener(_onAudioChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onAudioChanged() {
    if (mounted) setState(() {});
  }

  /// Carga el catálogo cuando la pantalla se abre por su cuenta. La caché hace
  /// que normalmente aparezca ya pintado.
  Future<void> _loadCatalog() async {
    setState(() => _loadingCatalog = true);
    final catalog = await IvooxService.loadCatalog(
      onProgress: (partial) {
        if (!mounted) return;
        setState(() => _catalog = partial);
      },
    );
    if (!mounted) return;
    setState(() {
      _catalog = catalog.programs;
      _loadingCatalog = false;
    });
    await _fetchVisibleFeeds();
  }

  /// Programas que se muestran: todos, o los que casan con la búsqueda.
  List<IvooxProgramRef> get _refs {
    if (_query.trim().isEmpty) return _catalog;
    final q = _plano(_query);
    return _catalog.where((r) => _plano(r.name).contains(q)).toList();
  }

  bool get _buscando => _query.trim().isNotEmpty;

  /// Minúsculas y sin tildes: nadie escribe "Zona Púrpura" con tilde en el
  /// buscador de un móvil.
  static String _plano(String input) {
    const acentos = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const planos = 'aaaaaeeeeiiiiooooouuuunc';
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final i = acentos.indexOf(char);
      buffer.write(i == -1 ? char : planos[i]);
    }
    return buffer.toString();
  }

  bool get _hasMore => _visible < _refs.length;

  /// Programa listo para pintar: con episodios si ya llegó su feed, y si no
  /// con lo que da el catálogo (nombre + carátula).
  PodcastItem _itemFor(IvooxProgramRef ref) =>
      _loaded[ref.feedId] ?? IvooxService.stubFor(ref);

  /// Episodio más reciente de cada programa ya cargado, más nuevo primero.
  List<_RecentEntry> get _recents {
    final entries = <_RecentEntry>[];
    for (final ref in _refs) {
      final program = _loaded[ref.feedId];
      final episode = program?.latestEpisode;
      if (program != null && episode != null) {
        entries.add(_RecentEntry(program: program, episode: episode));
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
    return entries;
  }

  /// Descarga los feeds de los programas visibles que aún no se hayan pedido.
  /// El coste de red crece con lo que el usuario explora, no de golpe.
  Future<void> _fetchVisibleFeeds({bool force = false}) async {
    final pending = <IvooxProgramRef>[];
    for (final ref in _refs.take(_visible)) {
      if (!force && !_requested.add(ref.feedId)) continue;
      if (force) _requested.add(ref.feedId);
      pending.add(ref);
    }
    if (pending.isEmpty) return;

    setState(() => _fetchingFeeds = true);
    final result = await IvooxService.loadPrograms(
      pending,
      forceRefresh: force,
      onProgram: (program) {
        if (!mounted) return;
        // Cada feed que llega se pinta ya: la fila de recientes se va
        // completando y reordenando sola.
        setState(() => _loaded[program.id] = program);
      },
    );
    if (!mounted) return;
    setState(() {
      _fetchingFeeds = false;
      _failed
        ..removeWhere((r) => _loaded.containsKey(r.feedId))
        ..addAll(result.failed.where((r) => !_failed.contains(r)));
    });
  }

  Future<void> _retryFailed() async {
    if (_failed.isEmpty || _retrying) return;
    final pending = List<IvooxProgramRef>.from(_failed);
    setState(() => _retrying = true);
    final result = await IvooxService.loadPrograms(
      pending,
      forceRefresh: true,
      onProgram: (program) {
        if (!mounted) return;
        setState(() => _loaded[program.id] = program);
      },
    );
    if (!mounted) return;
    setState(() {
      _retrying = false;
      _failed
        ..clear()
        ..addAll(result.failed);
    });
  }

  void _loadMore() {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    // El centinela se construye durante el layout: diferir el setState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _visible = (_visible + _pageSize).clamp(0, _refs.length);
        _loadingMore = false;
      });
      _fetchVisibleFeeds();
    });
  }

  void _openProgram(PodcastItem p, {PodcastEpisode? episode}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PodcastDetailScreen(program: p, initialEpisode: episode),
      ),
    );
  }

  /// Reproduce el episodio más reciente del programa, cargando su feed si
  /// todavía no está.
  Future<void> _playLatest(IvooxProgramRef ref) async {
    var program = _loaded[ref.feedId];
    if (program == null) {
      final loaded = await IvooxService.fetchProgram(ref);
      if (loaded == null || !mounted) return;
      program = loaded;
      setState(() => _loaded[loaded.id] = loaded);
    }
    final episode = program.latestEpisode;
    if (episode == null) return;
    AudioService().playEpisode(
      episode.audioUrl,
      title: episode.title,
      subtitle: program.title,
      imageUrl: episode.imageUrl.isNotEmpty
          ? episode.imageUrl
          : program.imageUrl,
      queue: program.episodeList,
      queueIndex: program.episodeList.indexOf(episode),
    );
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EpisodePlayerScreen()));
  }

  /// Retoma el episodio a medias. Si su programa ya está cargado se pasa la
  /// cola entera, para no perder el anterior/siguiente por venir de aquí.
  void _resumeEntry(ResumeEntry entry) {
    PodcastItem? program;
    for (final item in _loaded.values) {
      if (item.title == entry.program) {
        program = item;
        break;
      }
    }
    final queue = program?.episodeList ?? const <PodcastEpisode>[];

    AudioService().playEpisode(
      entry.audioUrl,
      title: entry.title,
      subtitle: entry.program,
      // La marca de avance puede venir de antes de que se guardara la
      // carátula; en ese caso se toma la del programa si ya está cargado.
      imageUrl: entry.imageUrl.isNotEmpty
          ? entry.imageUrl
          : (program?.imageUrl ?? ''),
      queue: queue,
      queueIndex: queue.indexWhere((e) => e.audioUrl == entry.audioUrl),
    );
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EpisodePlayerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final featured = _refs.isNotEmpty ? _refs.first : null;
    final resume = ResumeStore.latest;
    final loadingFirstPage = _loadingCatalog && _refs.isEmpty;
    final recents = _recents;
    final visibleRefs = _refs.take(_visible).toList();

    return Container(
      decoration: const BoxDecoration(gradient: MohanaGradients.homeTonal),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: !widget.embedded,
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
        bottomNavigationBar: widget.embedded
            ? null
            : const SafeArea(child: AudioPlayerBar()),
        body: RefreshIndicator(
          color: MohanaColors.primary,
          onRefresh: () => _fetchVisibleFeeds(force: true),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: MohanaSpacing.sm),
              ),

              SliverToBoxAdapter(
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: MohanaSpacing.lg),
              ),

              // Primera carga del catálogo: esqueleto en lugar de vacío.
              if (loadingFirstPage && !_buscando)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: MohanaSpacing.base),
                    child: PodcastRowSkeleton(height: 178, cardWidth: 130),
                  ),
                ),

              // Seguir escuchando ocupa el sitio del destacado cuando hay un
              // episodio a medias: quien vuelve a la app viene a terminarlo.
              if (!_buscando && resume != null) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MohanaSpacing.base,
                    ),
                    child: SectionEyebrow('Seguir escuchando'),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: MohanaSpacing.md),
                ),
                SliverToBoxAdapter(
                  child: StaggeredEntrance(
                    index: 0,
                    child: _ResumeCard(
                      entry: resume,
                      onTap: () => _resumeEntry(resume),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: MohanaSpacing.xl),
                ),
              ]
              // Destacado
              else if (!_buscando && featured != null) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MohanaSpacing.base,
                    ),
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
                      program: _itemFor(featured),
                      onTap: () => _openProgram(_itemFor(featured)),
                      onPlay: () => _playLatest(featured),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: MohanaSpacing.xl),
                ),
              ],

              // Aviso de programas que no cargaron
              if (_failed.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: LoadNotice(
                    message: _failed.length == 1
                        ? 'Un programa no se pudo cargar'
                        : '${_failed.length} programas no se pudieron cargar',
                    detail: _failed.map((r) => r.name).join(', '),
                    onRetry: _retryFailed,
                    busy: _retrying,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: MohanaSpacing.xl),
                ),
              ],

              // Episodios recientes (carrusel)
              if (!_buscando) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: MohanaSpacing.base),
                  child: SectionEyebrow('Episodios recientes'),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: MohanaSpacing.md),
              ),
              if (recents.isEmpty)
                const SliverToBoxAdapter(
                  child: PodcastRowSkeleton(height: 178, cardWidth: 130),
                )
              else
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 178,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: MohanaSpacing.base,
                      ),
                      itemCount: recents.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: MohanaSpacing.md),
                      itemBuilder: (_, i) => _RecentCard(
                        entry: recents[i],
                        onTap: () => _openProgram(
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MohanaSpacing.base,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SectionEyebrow(
                          _buscando ? 'Resultados' : 'Todos los programas',
                        ),
                      ),
                      Text(
                        '${_refs.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: MohanaColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: MohanaSpacing.md),
              ),
              if (_buscando && _refs.isEmpty)
                SliverToBoxAdapter(child: _SinResultados(query: _query)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MohanaSpacing.base,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: MohanaSpacing.md,
                    crossAxisSpacing: MohanaSpacing.md,
                    // Altura exacta en lugar de una proporción fija: así el
                    // texto cabe siempre, también con el tamaño de letra
                    // ampliado por accesibilidad.
                    mainAxisExtent: ProgramGridCard.extentFor(context),
                  ),
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final item = _itemFor(visibleRefs[i]);
                    return ProgramGridCard(
                      program: item,
                      onTap: () => _openProgram(item),
                    );
                  }, childCount: visibleRefs.length),
                ),
              ),

              // Centinela: al asomarse pide la siguiente página del catálogo.
              if (_hasMore)
                SliverToBoxAdapter(
                  child: _LoadMoreSentinel(onReached: _loadMore),
                ),

              if (_fetchingFeeds && _failed.isEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(height: MohanaSpacing.base),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: MohanaSpacing.xxl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Buscador del catálogo.
///
/// Va en blanco y no en el relleno gris del tema: `surfaceContainerLow` sobre
/// el lila del fondo tonal se ve sucio.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.base),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: MohanaColors.onSurface,
        ),
        decoration: InputDecoration(
          fillColor: MohanaColors.surface,
          hintText: 'Buscar programa',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

/// Episodio a medias, listo para retomar donde se dejó.
class _ResumeCard extends StatelessWidget {
  final ResumeEntry entry;
  final VoidCallback onTap;

  const _ResumeCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: MohanaSpacing.base),
        padding: const EdgeInsets.all(MohanaSpacing.md),
        decoration: MohanaDecorations.tonalCard,
        child: Row(
          children: [
            MohanaCover.square(
              url: entry.imageUrl,
              size: 56,
              borderRadius: MohanaRadius.mdAll,
            ),
            const SizedBox(width: MohanaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entry.program.isNotEmpty) ...[
                    Text(
                      entry.program,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: MohanaColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: MohanaSpacing.xs),
                  ],
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.breeSerif(
                      fontSize: 14,
                      color: MohanaColors.onSurface,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: MohanaSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: entry.fraction,
                            minHeight: 3,
                            backgroundColor: MohanaColors.outlineVariant
                                .withValues(alpha: 0.45),
                            valueColor: const AlwaysStoppedAnimation(
                              MohanaColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: MohanaSpacing.sm),
                      Text(
                        entry.remainingLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: MohanaColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: MohanaSpacing.md),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                gradient: MohanaGradients.brand,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Búsqueda sin coincidencias. Dice qué se buscó, para que se vea la errata.
class _SinResultados extends StatelessWidget {
  final String query;

  const _SinResultados({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MohanaSpacing.base,
        vertical: MohanaSpacing.xl,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 40,
            color: MohanaColors.onSurfaceVariant,
          ),
          const SizedBox(height: MohanaSpacing.md),
          Text(
            'Ningún programa se llama «$query»',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: MohanaColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentEntry {
  final PodcastItem program;
  final PodcastEpisode episode;
  const _RecentEntry({required this.program, required this.episode});
}

/// Fila final de la lista: al construirse (entra en el viewport o en su
/// `cacheExtent`) pide el siguiente lote.
class _LoadMoreSentinel extends StatefulWidget {
  final VoidCallback onReached;

  const _LoadMoreSentinel({required this.onReached});

  @override
  State<_LoadMoreSentinel> createState() => _LoadMoreSentinelState();
}

class _LoadMoreSentinelState extends State<_LoadMoreSentinel> {
  @override
  void initState() {
    super.initState();
    widget.onReached();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: MohanaColors.primary,
          ),
        ),
      ),
    );
  }
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
                child: MohanaCover.square(url: program.imageUrl, size: 96),
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
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
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

  /// "21 may · 48 min", con lo que haya: el feed no siempre trae las dos.
  static String _meta(_RecentEntry entry) {
    final partes = <String>[
      if (entry.episode.date != null) fechaRelativa(entry.episode.date!),
      if (entry.episode.duration != null) entry.episode.duration!,
    ];
    return partes.isEmpty ? 'Nuevo episodio' : partes.join(' · ');
  }

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
                child: MohanaCover.square(
                  url: entry.episode.imageUrl.isNotEmpty
                      ? entry.episode.imageUrl
                      : entry.program.imageUrl,
                  size: 130,
                ),
              ),
            ),
            const SizedBox(height: MohanaSpacing.sm),
            // La sección es de episodios, así que manda el título del
            // episodio; el programa ya se reconoce por la carátula.
            Text(
              entry.episode.title,
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
              _meta(entry),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: MohanaColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

