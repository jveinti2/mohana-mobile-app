import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../screens/episode_player_screen.dart';
import '../screens/radio_screen.dart';
import '../services/audio_service.dart';
import 'mohana_cover.dart';

class AudioPlayerBar extends StatelessWidget {
  /// Acción al tocar la barra. Por defecto abre el reproductor que
  /// corresponda a lo que esté sonando.
  final VoidCallback? onTap;

  const AudioPlayerBar({super.key, this.onTap});

  /// El directo y los episodios tienen reproductores distintos: la barra abre
  /// el que toca en cada momento, no siempre el de la emisora.
  void _openPlayer(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AudioService().isLive
            ? const RadioScreen()
            : const EpisodePlayerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();

    return ListenableBuilder(
      listenable: audioService,
      builder: (context, _) {
        return GestureDetector(
          onTap: () => _openPlayer(context),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: MohanaColors.surfaceContainerLowest.withValues(
                    alpha: 0.92,
                  ),
                  border: Border(
                    top: BorderSide(
                      color: MohanaColors.outlineVariant.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Mini album art
                        if (audioService.isLive)
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: MohanaGradients.brand,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.radio,
                              color: Colors.white,
                              size: 18,
                            ),
                          )
                        else
                          MohanaCover.square(
                            url: audioService.currentEpisodeImageUrl,
                            size: 36,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        const SizedBox(width: 12),
                        // Now playing info
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      audioService.nowPlayingTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: MohanaColors.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (audioService.isPlaying &&
                                      audioService.isLive) ...[
                                    const SizedBox(width: 8),
                                    MohanaTheme.liveBadge(fontSize: 8),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                audioService.nowPlayingSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: MohanaColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Volver al directo. Solo mientras suena un episodio:
                        // en el directo no tendría nada que hacer.
                        if (!audioService.isLive) ...[
                          const _BackToLiveButton(),
                          const SizedBox(width: MohanaSpacing.xs),
                        ],
                        // Play/Pause
                        GestureDetector(
                          onTap: () => audioService.togglePlayPause(),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: MohanaGradients.brand,
                              shape: BoxShape.circle,
                              boxShadow: [MohanaShadows.ambient],
                            ),
                            child: audioService.isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    audioService.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    // Avance del episodio: el directo no tiene línea de tiempo.
                    if (!audioService.isLive) const _MiniProgress(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Vuelta al directo desde el mini reproductor.
///
/// Cambia lo que suena sin sacar al usuario de donde está: la barra vive en
/// pantallas que no tienen la navegación inferior (la de un programa, por
/// ejemplo), y ahí este era el hueco — se entraba a un episodio y no había
/// forma de volver a la emisora. Para *ver* el reproductor del directo está
/// el toque sobre la barra, que ya lleva al que corresponda.
///
/// Va plano y en lila: el círculo con gradiente es el lenguaje del play, y
/// dos botones iguales en 38 píxeles se confundirían.
class _BackToLiveButton extends StatelessWidget {
  const _BackToLiveButton();

  static const _label = 'Volver al directo';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _label,
      child: Tooltip(
        message: _label,
        excludeFromSemantics: true,
        child: GestureDetector(
          onTap: () => AudioService().playLive(),
          // El círculo se ve a 34, pero el área que responde al dedo mide 44
          // de ancho: por debajo de eso se falla el toque más de lo que se
          // acierta. El alto se queda en 38, el mismo del play, para que la
          // barra no dé un salto al pasar del directo a un episodio.
          child: Container(
            width: 44,
            height: 38,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: MohanaColors.primary100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.radio_rounded,
                color: MohanaColors.primary,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Línea de avance del episodio en curso, fina y sin interacción: para
/// moverse por el audio está el reproductor completo.
class _MiniProgress extends StatelessWidget {
  const _MiniProgress();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackProgress>(
      stream: AudioService().progressStream,
      builder: (context, snapshot) {
        final progress = snapshot.data ?? const PlaybackProgress();
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 3,
              backgroundColor: MohanaColors.outlineVariant.withValues(
                alpha: 0.45,
              ),
              valueColor: const AlwaysStoppedAnimation(MohanaColors.primary),
            ),
          ),
        );
      },
    );
  }
}
