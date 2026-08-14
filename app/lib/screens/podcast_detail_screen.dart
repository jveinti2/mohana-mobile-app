import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../config/theme.dart';
import '../models/podcast_episode.dart';
import '../models/podcast_item.dart';
import '../services/audio_service.dart';
import '../widgets/audio_player_bar.dart';
import '../widgets/entrance.dart';
import 'radio_screen.dart';

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

  late PodcastEpisode _selected;
  bool _descExpanded = false;

  List<PodcastEpisode> get _episodes => widget.program.episodeList;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialEpisode ??
        (_episodes.isNotEmpty
            ? _episodes.first
            : const PodcastEpisode(title: '', audioUrl: ''));
  }

  String get _coverUrl =>
      _selected.imageUrl.isNotEmpty ? _selected.imageUrl : widget.program.imageUrl;

  String get _headerTitle =>
      _selected.title.isNotEmpty ? _selected.title : widget.program.title;

  String get _description => _selected.description.isNotEmpty
      ? _selected.description
      : widget.program.description;

  void _select(PodcastEpisode ep) {
    setState(() {
      _selected = ep;
      _descExpanded = false;
    });
    AudioService().playEpisode(
      ep.audioUrl,
      title: ep.title,
      subtitle: widget.program.title,
    );
  }

  void _toggleSelected(AudioService audio) {
    final isCurrent = !audio.isLive && audio.nowPlayingTitle == _selected.title;
    if (isCurrent) {
      audio.togglePlayPause();
    } else {
      _select(_selected);
    }
  }

  void _share() {
    Share.share(
      '🎧 Escucha "${widget.program.title}" en La Mohana, la emisora de las '
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
          actions: [
            IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: _share,
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: AudioPlayerBar(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RadioScreen()),
            ),
          ),
        ),
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
                    child: SectionEyebrow('Episodios'),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: MohanaSpacing.sm),
                ),
                SliverList.builder(
                  itemCount: _episodes.length,
                  itemBuilder: (_, i) => _EpisodeTile(
                    episode: _episodes[i],
                    audio: audio,
                    onTap: () => _select(_episodes[i]),
                  ),
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
        !audio.isLive && audio.nowPlayingTitle == _selected.title;
    final isPlaying = isCurrent && audio.isPlaying;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Carátula central
          ClipRRect(
            borderRadius: MohanaRadius.xxlAll,
            child: SizedBox(
              width: 200,
              height: 200,
              child: _coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _coverFallback(),
                      errorWidget: (_, _, _) => _coverFallback(),
                    )
                  : _coverFallback(),
            ),
          ),
          const SizedBox(height: MohanaSpacing.lg),
          // Programa (contexto)
          Text(
            widget.program.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MohanaColors.secondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: MohanaSpacing.xs),
          // Nombre del episodio activo
          Text(
            _headerTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.breeSerif(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: MohanaColors.tertiary,
              height: 1.2,
            ),
          ),
          if (_selected.date != null) ...[
            const SizedBox(height: MohanaSpacing.xs),
            Text(
              _formatDate(_selected.date!) +
                  (_selected.duration != null
                      ? ' · ${_selected.duration}'
                      : ''),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: MohanaColors.onSurfaceVariant,
              ),
            ),
          ],
          // Descripción con "ver más"
          if (_description.isNotEmpty) ...[
            const SizedBox(height: MohanaSpacing.md),
            Text(
              _description,
              textAlign: TextAlign.center,
              maxLines: _descExpanded ? null : 3,
              overflow: _descExpanded ? null : TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: MohanaColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: MohanaSpacing.xs),
                child: Text(
                  _descExpanded ? 'Ver menos ▴' : 'Ver más ▾',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MohanaColors.primary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: MohanaSpacing.lg),
          // Botón reproducir / pausar
          GestureDetector(
            onTap: () => _toggleSelected(audio),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MohanaSpacing.xxl,
                vertical: MohanaSpacing.md,
              ),
              decoration: MohanaDecorations.primaryButton,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: MohanaColors.onPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: MohanaSpacing.sm),
                  Text(
                    isPlaying ? 'Reproduciendo' : 'Reproducir',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MohanaColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverFallback() => Container(
        decoration: const BoxDecoration(gradient: MohanaGradients.brand),
        child: const Icon(Icons.podcasts, color: Colors.white, size: 56),
      );

  String _formatDate(DateTime date) =>
      DateFormat("d 'de' MMMM, y", 'es').format(date);
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
    final isCurrent = !audio.isLive && audio.nowPlayingTitle == episode.title;
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
                              color: MohanaColors.tertiary
                                  .withValues(alpha: 0.18),
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
