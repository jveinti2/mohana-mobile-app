import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/premium_audio.dart';
import '../services/audio_service.dart';
import '../services/premium_service.dart';
import '../widgets/entrance.dart';
import '../widgets/feed_skeleton.dart';
import '../widgets/load_notice.dart';
import '../widgets/premium_list_card.dart';
import 'episode_player_screen.dart';

/// Contenido exclusivo: los audios de la emisora que no están en iVoox.
///
/// Es una lista plana, sin programas ni catálogo, porque la fuente no es un
/// feed sino fichas sueltas del CMS. Por eso no se parece a la biblioteca de
/// podcasts y sí a [PostsScreen].
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  List<PremiumAudio> _items = const [];
  bool _loading = true;
  bool _failed = false;

  /// IDs ya animados, para no repetir la entrada al volver a la pestaña.
  final Set<String> _seenIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      // Solo se enseña el esqueleto en un arranque en frío: al refrescar, la
      // lista de antes se queda puesta mientras llega la nueva.
      _loading = _items.isEmpty;
      _failed = false;
    });
    try {
      final items = await PremiumService.load(forceRefresh: force);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  /// Pone a sonar el audio y abre el reproductor.
  ///
  /// La cola es la lista entera menos lo que no suena, para que el
  /// anterior/siguiente del reproductor recorra el contenido exclusivo. El
  /// índice se calcula **sobre la cola ya filtrada**: con el índice de la
  /// pantalla, una ficha sin audio por el camino haría que los botones
  /// apuntaran al audio equivocado.
  void _reproducir(PremiumAudio item) {
    final cola = _items.where((e) => e.playable).map((e) => e.asEpisode).toList();
    AudioService().playEpisode(
      item.audioUrl,
      title: item.title,
      // No va la descripción: el subtítulo se pinta en una línea en mayúsculas
      // y es lo que sale como artista en la notificación del sistema.
      subtitle: 'Contenido exclusivo',
      imageUrl: item.imageUrl,
      queue: cola,
      queueIndex: cola.indexWhere((e) => e.audioUrl == item.audioUrl),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EpisodePlayerScreen()),
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
          automaticallyImplyLeading: false,
          title: Text(
            'Exclusivo',
            style: GoogleFonts.breeSerif(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: MohanaColors.tertiary,
            ),
          ),
        ),
        body: _loading ? const FeedSkeleton() : _buildList(),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: MohanaColors.primary,
      onRefresh: () => _load(force: true),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: MohanaSpacing.sm)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MohanaSpacing.screenH,
              ),
              child: Text(
                'Audios de la emisora que no están en iVoox.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: MohanaColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: MohanaSpacing.base)),

          if (_failed)
            SliverToBoxAdapter(
              child: LoadNotice(
                message: 'No se pudo cargar el contenido exclusivo',
                detail: 'Desliza hacia abajo para reintentar.',
                onRetry: () => _load(force: true),
              ),
            )
          else if (_items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Todavía no hay contenido exclusivo',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: MohanaColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SliverList.separated(
              itemCount: _items.length,
              itemBuilder: (_, index) {
                final item = _items[index];
                final firstSeen = _seenIds.add(item.id);
                final card = PremiumListCard(item: item);
                return StaggeredEntrance(
                  index: index,
                  animate: firstSeen,
                  // Una ficha sin audio se pinta pero no responde: es lo que
                  // le dice a la emisora que el archivo se quedó sin publicar.
                  child: item.playable
                      ? PressableScale(
                          onTap: () => _reproducir(item),
                          child: card,
                        )
                      : card,
                );
              },
              separatorBuilder: (_, _) =>
                  const SizedBox(height: MohanaSpacing.base),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: MohanaSpacing.xxl)),
        ],
      ),
    );
  }
}
