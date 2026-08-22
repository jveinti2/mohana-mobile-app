import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../config/theme.dart';
import '../models/podcast_episode.dart';
import '../models/podcast_item.dart';
import '../services/audio_service.dart';
import '../services/ivoox_service.dart';
import '../widgets/audio_player_bar.dart';
import '../widgets/entrance.dart';
import '../widgets/feed_skeleton.dart';
import '../widgets/load_notice.dart';
import '../widgets/mohana_cover.dart';
import 'episode_player_screen.dart';

/// Pantalla de un programa de podcast. La cabecera (carátula + nombre +
/// descripción) refleja el episodio activo, y debajo se listan todos los
/// episodios para ir cambiando entre ellos. Mantiene el estilo tonal del home.
class PodcastDetailScreen extends StatefulWidget {
  final PodcastItem program;

  /// Episodio con el que abrir inicialmente (por defecto, el más reciente).
  final PodcastEpisode? initialEpisode;

  const PodcastDetailScreen({
    super.key,
    required this.program,
    this.initialEpisode,
  });

  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen> {
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ofp.lamohanaradio';

  /// Episodios que se renderizan de una vez. El feed completo vive en memoria
  /// (son objetos pequeños); lo caro sería construir 740 filas de golpe.
  static const _pageSize = 20;

  late PodcastItem _program;
  late PodcastEpisode _selected;

  int _visible = _pageSize;
  bool _loadingMore = false;
  bool _loadingEpisodes = false;
  bool _loadFailed = false;

  List<PodcastEpisode> get _episodes => _program.episodeList;

  bool get _hasMore => _visible < _episodes.length;

  @override
  void initState() {
    super.initState();
    _program = widget.program;
    _selected =
        widget.initialEpisode ??
        (_episodes.isNotEmpty
            ? _episodes.first
            : const PodcastEpisode(title: '', audioUrl: ''));
    _openWindowTo(_selected);
    if (_episodes.isEmpty) {
      _loadEpisodes();
    } else if (!_program.hasAllEpisodes) {
      // La caché guarda solo los episodios recientes: se completa la lista sin
      // esconder lo que ya está en pantalla.
      _loadEpisodes(background: true);
    }
  }

  /// Solo los programas de iVoox tienen feed; los de Drive no.
  bool get _hasFeed => int.tryParse(_program.id) != null;

  /// Los episodios se descargan al abrir el programa, no en el arranque de la
  /// app: así el feed (que puede pesar) solo viaja cuando alguien lo mira.
  Future<void> _loadEpisodes({
    bool force = false,
    bool background = false,
  }) async {
    if (!_hasFeed) return;
    setState(() {
      _loadingEpisodes = !background;
      _loadFailed = false;
    });
    final loaded = await IvooxService.fetchProgram(
      IvooxService.refFor(_program),
      forceRefresh: force,
    );
    if (!mounted) return;
    setState(() {
      _loadingEpisodes = false;
      if (loaded == null) {
        _loadFailed = true;
        return;
      }
      _program = _program.withEpisodes(loaded);
      if (_selected.audioUrl.isEmpty && _episodes.isNotEmpty) {
        _selected = _episodes.first;
      }
      _openWindowTo(_selected);
    });
  }

  /// Abre la ventana de render hasta el episodio dado (enlaces profundos).
  void _openWindowTo(PodcastEpisode episode) {
    final i = _episodes.indexOf(episode);
    if (i >= 0) _visible = math.max(_pageSize, i + _pageSize);
  }

  void _loadMore() {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    // El centinela se construye durante el layout: diferir el setState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _visible = math.min(_visible + _pageSize, _episodes.length);
        _loadingMore = false;
      });
    });
  }

  String get _coverUrl =>
      _selected.imageUrl.isNotEmpty ? _selected.imageUrl : _program.imageUrl;

  String get _headerTitle =>
      _selected.title.isNotEmpty ? _selected.title : _program.title;

  String get _description => _selected.description.isNotEmpty
      ? _selected.description
      : _program.description;

  /// Reproduce un episodio y abre el reproductor. Se le pasa la lista completa
  /// del programa para poder saltar al anterior o al siguiente sin volver.
  void _select(PodcastEpisode ep, {bool openPlayer = true}) {
    setState(() => _selected = ep);
    AudioService().playEpisode(
      ep.audioUrl,
      title: ep.title,
      subtitle: _program.title,
      imageUrl: ep.imageUrl.isNotEmpty ? ep.imageUrl : _program.imageUrl,
      queue: _episodes,
      queueIndex: _episodes.indexOf(ep),
    );
    if (openPlayer) _openPlayer();
  }

  void _openPlayer() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EpisodePlayerScreen()));
  }

  void _toggleSelected(AudioService audio) {
    if (_selected.audioUrl.isEmpty) return;
    if (audio.currentEpisodeUrl == _selected.audioUrl) {
      // Ya está sonando: el botón lleva al reproductor completo.
      _openPlayer();
    } else {
      _select(_selected);
    }
  }

  void _share() {
    Share.share(
      '🎧 Escucha "${_program.title}" en La Mohana, la emisora de las '
      'mujeres. Descarga la app: $_playStoreUrl',
    );
  }

  @override
  Widget build(BuildContext context) {
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
            'Programa',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MohanaColors.tertiary,
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(child: const AudioPlayerBar()),
        body: ListenableBuilder(
          listenable: AudioService(),
          builder: (context, _) {
            final audio = AudioService();
            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(audio)),
                const SliverToBoxAdapter(
                  child: SizedBox(height: MohanaSpacing.lg),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MohanaSpacing.base,
                    ),
                    child: Row(
                      children: [
                        const Expanded(child: SectionEyebrow('Episodios')),
                        if (_episodes.isNotEmpty)
                          Text(
                            _program.episodesLabel,
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
                  child: SizedBox(height: MohanaSpacing.sm),
                ),

                if (_loadingEpisodes && _episodes.isEmpty)
                  const SliverToBoxAdapter(child: EpisodeListSkeleton())
                else if (_loadFailed && _episodes.isEmpty && _hasFeed)
                  SliverToBoxAdapter(
                    child: LoadNotice(
                      message: 'No se pudieron cargar los episodios',
                      detail: 'Revisa tu conexión e inténtalo de nuevo.',
                      onRetry: () => _loadEpisodes(force: true),
                      busy: _loadingEpisodes,
                    ),
                  )
                else
                  SliverList.builder(
                    // Ventana de render: se amplía sola al llegar al final.
                    itemCount:
                        math.min(_visible, _episodes.length) +
                        (_hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= _visible) {
                        return _LoadMoreSentinel(onReached: _loadMore);
                      }
                      return _EpisodeTile(
                        episode: _episodes[i],
                        audio: audio,
                        onTap: () => _select(_episodes[i]),
                      );
                    },
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: MohanaSpacing.xxl),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AudioService audio) {
    final isCurrent =
        audio.currentEpisodeUrl == _selected.audioUrl &&
        _selected.audioUrl.isNotEmpty;
    final isPlaying = isCurrent && audio.isPlaying;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Carátula: es lo primero que identifica al programa, así que manda.
          LayoutBuilder(
            builder: (context, constraints) => ClipRRect(
              borderRadius: MohanaRadius.xxlAll,
              child: MohanaCover.square(
                url: _coverUrl,
                size: constraints.maxWidth.clamp(180.0, 320.0),
              ),
            ),
          ),
          const SizedBox(height: MohanaSpacing.md),
          // Programa (contexto)
          Text(
            _program.title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MohanaColors.secondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: MohanaSpacing.xxs),
          // Nombre del episodio activo
          Text(
            _headerTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.breeSerif(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: MohanaColors.tertiary,
              height: 1.15,
            ),
          ),
          if (_description.isNotEmpty) ...[
            const SizedBox(height: MohanaSpacing.sm),
            Text(
              _description,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: MohanaColors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: MohanaSpacing.md),
          // Controles: reproducir y compartir, sin botón grande.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeaderAction(
                icon: isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                tooltip: isCurrent ? 'Ver reproductor' : 'Reproducir',
                primary: true,
                onTap: () => _toggleSelected(audio),
              ),
              const SizedBox(width: MohanaSpacing.base),
              _HeaderAction(
                icon: Icons.ios_share,
                tooltip: 'Compartir programa',
                onTap: _share,
              ),
            ],
          ),
        ],
      ),
    );
  }

}

/// Botón redondo de la cabecera. El principal (reproducir) va con el gradiente
/// de marca; los secundarios, en blanco sobre el fondo tonal.
class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool primary;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = primary ? 60.0 : 48.0;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: primary ? MohanaGradients.primaryButton : null,
            color: primary ? null : MohanaColors.surface,
            shape: BoxShape.circle,
            boxShadow: [MohanaShadows.tonalCard],
          ),
          child: Icon(
            icon,
            size: primary ? 30 : 22,
            color: primary ? MohanaColors.onPrimary : MohanaColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Fila final de la lista: al construirse (entra en el viewport o en su
/// `cacheExtent`) pide el siguiente lote de episodios.
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

class _EpisodeTile extends StatelessWidget {
  final PodcastEpisode episode;
  final AudioService audio;
  final VoidCallback onTap;

  const _EpisodeTile({
    required this.episode,
    required this.audio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Por URL, no por titulo: los titulos se repiten dentro de un programa.
    final isCurrent = audio.currentEpisodeUrl == episode.audioUrl;
    final isPlaying = isCurrent && audio.isPlaying;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MohanaSpacing.sm,
        MohanaSpacing.xs,
        MohanaSpacing.sm,
        MohanaSpacing.xs,
      ),
      child: Material(
        color: isCurrent ? MohanaColors.surface : Colors.transparent,
        borderRadius: MohanaRadius.lgAll,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: MohanaRadius.lgAll,
          child: Container(
            decoration: isCurrent
                ? BoxDecoration(
                    borderRadius: MohanaRadius.lgAll,
                    boxShadow: [MohanaShadows.tonalCard],
                  )
                : null,
            padding: const EdgeInsets.symmetric(
              horizontal: MohanaSpacing.md,
              vertical: MohanaSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: isCurrent ? MohanaGradients.primaryButton : null,
                    color: isCurrent ? null : MohanaColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: isCurrent
                        ? null
                        : [
                            BoxShadow(
                              color: MohanaColors.tertiary.withValues(
                                alpha: 0.18,
                              ),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isCurrent ? Colors.white : MohanaColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: MohanaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? MohanaColors.primary
                              : MohanaColors.onSurface,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: MohanaSpacing.xxs),
                      Text(
                        _subtitle(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: MohanaColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final date = episode.date != null
        ? DateFormat("d MMM y", 'es').format(episode.date!)
        : '';
    final dur = episode.duration ?? '';
    if (date.isNotEmpty && dur.isNotEmpty) return '$date · $dur';
    return date.isNotEmpty ? date : dur;
  }
}
