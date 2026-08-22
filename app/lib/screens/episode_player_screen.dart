import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../config/theme.dart';
import '../services/audio_service.dart';
import '../widgets/mohana_cover.dart';
import 'radio_screen.dart';

/// Reproductor de episodios de podcast.
///
/// Deliberadamente distinto al de la emisora en vivo ([RadioScreen], de fondo
/// claro y sin barra de tiempo): aquí el contenido está grabado, así que manda
/// la línea de tiempo — se puede arrastrar, saltar atrás y adelante, cambiar de
/// episodio y ajustar la velocidad. El fondo morado profundo deja claro de un
/// vistazo que no es el directo.
class EpisodePlayerScreen extends StatelessWidget {
  const EpisodePlayerScreen({super.key});

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ofp.lamohanaradio';

  /// Cambia del episodio al directo de la emisora y abre su reproductor, que
  /// es otro: sin barra de tiempo y con el distintivo EN VIVO.
  void _backToLive(BuildContext context, AudioService audio) {
    audio.playLive();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const RadioScreen()));
  }

  void _share(AudioService audio) {
    final program = audio.currentProgramTitle;
    final where = program.isEmpty ? 'La Mohana' : program;
    Share.share(
      '🎧 Estoy escuchando "${audio.nowPlayingTitle}" en $where, la emisora '
      'de las mujeres. Descarga la app: $_playStoreUrl',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioService(),
      builder: (context, _) {
        final audio = AudioService();

        // Si el usuario vuelve al directo desde el mini player, esta pantalla
        // ya no tiene nada que reproducir.
        if (audio.isLive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
        }

        return Container(
          decoration: const BoxDecoration(gradient: MohanaGradients.player),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                'Reproduciendo',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.4,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.radio_rounded, color: Colors.white),
                  tooltip: 'Volver al directo',
                  onPressed: () => _backToLive(context, audio),
                ),
                IconButton(
                  icon: const Icon(Icons.ios_share, color: Colors.white),
                  tooltip: 'Compartir episodio',
                  onPressed: () => _share(audio),
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // La carátula cede espacio en pantallas bajas para que los
                  // controles nunca queden fuera.
                  final cover = (constraints.maxWidth * 0.68).clamp(
                    140.0,
                    constraints.maxHeight * 0.42,
                  );

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: MohanaSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: MohanaSpacing.md),
                        _Cover(size: cover.toDouble(), audio: audio),
                        const SizedBox(height: MohanaSpacing.xl),
                        _TrackInfo(audio: audio),
                        const SizedBox(height: MohanaSpacing.lg),
                        const _ProgressBar(),
                        const SizedBox(height: MohanaSpacing.md),
                        _Controls(audio: audio),
                        const SizedBox(height: MohanaSpacing.lg),
                        _SpeedChip(audio: audio),
                        const SizedBox(height: MohanaSpacing.xl),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Cover extends StatelessWidget {
  final double size;
  final AudioService audio;

  const _Cover({required this.size, required this.audio});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: MohanaRadius.xxlAll,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 12),
            blurRadius: 32,
          ),
        ],
      ),
      child: MohanaCover.square(
        url: audio.currentEpisodeImageUrl,
        size: size,
        borderRadius: MohanaRadius.xxlAll,
      ),
    );
  }
}

class _TrackInfo extends StatelessWidget {
  final AudioService audio;

  const _TrackInfo({required this.audio});

  @override
  Widget build(BuildContext context) {
    final program = audio.currentProgramTitle;

    return Column(
      children: [
        if (program.isNotEmpty) ...[
          Text(
            program.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MohanaColors.secondary200,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: MohanaSpacing.sm),
        ],
        Text(
          audio.nowPlayingTitle,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.breeSerif(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

/// Barra de tiempo arrastrable. Es lo que separa a este reproductor del
/// directo: mientras se arrastra manda el valor local, no el del reproductor,
/// para que el pulgar no "pelee" con la posición que sigue llegando.
class _ProgressBar extends StatefulWidget {
  const _ProgressBar();

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double? _dragValue;

  String _format(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    final mm = minutes.toString().padLeft(hours > 0 ? 2 : 1, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final audio = AudioService();

    return StreamBuilder<PlaybackProgress>(
      stream: audio.progressStream,
      builder: (context, snapshot) {
        final progress = snapshot.data ?? const PlaybackProgress();
        final total = progress.duration;
        final known = total.inMilliseconds > 0;
        final position = _dragValue != null && known
            ? Duration(
                milliseconds: (_dragValue! * total.inMilliseconds).round(),
              )
            : progress.position;

        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
                secondaryActiveTrackColor: Colors.white.withValues(alpha: 0.38),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.15),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              ),
              child: Slider(
                value: _dragValue ?? progress.fraction,
                // Cuánto lleva descargado, por detrás de la posición.
                secondaryTrackValue: known
                    ? (progress.buffered.inMilliseconds / total.inMilliseconds)
                          .clamp(0.0, 1.0)
                    : 0,
                onChanged: known
                    ? (value) => setState(() => _dragValue = value)
                    : null,
                onChangeEnd: known
                    ? (value) {
                        audio.seek(
                          Duration(
                            milliseconds: (value * total.inMilliseconds)
                                .round(),
                          ),
                        );
                        setState(() => _dragValue = null);
                      }
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_format(position), style: _timeStyle),
                  Text(known ? _format(total) : '--:--', style: _timeStyle),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  TextStyle get _timeStyle => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white.withValues(alpha: 0.75),
  );
}

class _Controls extends StatelessWidget {
  final AudioService audio;

  const _Controls({required this.audio});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _IconAction(
          icon: Icons.skip_previous_rounded,
          size: 30,
          tooltip: 'Episodio anterior',
          onTap: audio.hasPrevious ? audio.skipToPrevious : null,
        ),
        _IconAction(
          icon: Icons.replay_10_rounded,
          size: 32,
          tooltip: 'Retroceder 10 segundos',
          onTap: audio.rewind,
        ),
        _PlayButton(audio: audio),
        _IconAction(
          icon: Icons.forward_30_rounded,
          size: 32,
          tooltip: 'Adelantar 30 segundos',
          onTap: audio.fastForward,
        ),
        _IconAction(
          icon: Icons.skip_next_rounded,
          size: 30,
          tooltip: 'Episodio siguiente',
          onTap: audio.hasNext ? audio.skipToNext : null,
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final AudioService audio;

  const _PlayButton({required this.audio});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: audio.togglePlayPause,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              offset: const Offset(0, 6),
              blurRadius: 18,
            ),
          ],
        ),
        child: audio.isLoading
            ? const Padding(
                padding: EdgeInsets.all(22),
                child: CircularProgressIndicator(
                  color: MohanaColors.primary,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(
                audio.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: MohanaColors.primary,
                size: 38,
              ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final double size;
  final String tooltip;
  final VoidCallback? onTap;

  const _IconAction({
    required this.icon,
    required this.size,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: size),
      color: Colors.white,
      disabledColor: Colors.white.withValues(alpha: 0.28),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final AudioService audio;

  const _SpeedChip({required this.audio});

  @override
  Widget build(BuildContext context) {
    final label = audio.speed == audio.speed.roundToDouble()
        ? '${audio.speed.toInt()}x'
        : '${audio.speed}x';

    return GestureDetector(
      onTap: audio.cycleSpeed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MohanaSpacing.base,
          vertical: MohanaSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(MohanaRadius.pill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed_rounded, size: 16, color: Colors.white),
            const SizedBox(width: MohanaSpacing.xs),
            Text(
              'Velocidad $label',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
