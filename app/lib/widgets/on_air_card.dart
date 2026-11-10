import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../screens/radio_screen.dart';
import '../services/audio_service.dart';
import '../services/schedule_service.dart';
import 'audio_visualizer.dart';

/// El directo, arriba del todo del feed.
///
/// Es una emisora, pero hasta ahora el stream en vivo solo existía en la barra
/// de abajo: quien abría la app se encontraba con artículos, no con la radio.
/// Esta tarjeta lo pone primero, en el morado de marca, para que no se lea
/// como una noticia más.
///
/// Dice qué programa suena cuando hay parrilla ([ScheduleService]); si no la
/// hay, cae a la identidad de la emisora y sigue sirviendo igual como acceso
/// al directo.
class OnAirCard extends StatelessWidget {
  const OnAirCard({super.key});

  void _openRadio(BuildContext context) {
    final audio = AudioService();
    if (!audio.isLive) audio.playLive();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RadioScreen()));
  }

  /// El botón cambia lo que suena sin sacar al usuario del feed.
  void _toggle() {
    final audio = AudioService();
    if (audio.isLive) {
      audio.togglePlayPause();
    } else {
      audio.playLive();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioService(),
      builder: (context, _) {
        final audio = AudioService();
        final slot = ScheduleService.current();
        final onAir = audio.isLive && audio.isPlaying;

        return GestureDetector(
          onTap: () => _openRadio(context),
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: MohanaSpacing.screenH,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: MohanaSpacing.base,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              gradient: MohanaGradients.brand,
              borderRadius: MohanaRadius.lgAll,
              boxShadow: [
                BoxShadow(
                  color: MohanaColors.tertiary.withValues(alpha: 0.28),
                  offset: const Offset(0, 6),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Flexible(child: _OnAirPill()),
                          // Las barras solo se mueven si de verdad está
                          // sonando: es señal, no adorno. Y por eso mismo son
                          // lo primero que se cede cuando la letra ampliada
                          // deja sin sitio al distintivo, que sí hace falta.
                          if (MediaQuery.textScalerOf(context).scale(9) <=
                              12) ...[
                            const SizedBox(width: MohanaSpacing.sm),
                            SizedBox(
                              height: 14,
                              child: AudioVisualizer(
                                isPlaying: onAir,
                                height: 14,
                                barCount: 4,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: MohanaSpacing.sm),
                      Text(
                        slot?.title ?? AudioService.stationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.breeSerif(
                          fontSize: 18,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: MohanaSpacing.xs),
                      Text(
                        slot != null
                            ? '${slot.label} · ${AudioService.frequency}'
                            : '${AudioService.frequency} · La emisora de las mujeres',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: MohanaSpacing.md),
                _PlayButton(
                  isLoading: audio.isLoading && audio.isLive,
                  isPlaying: onAir,
                  onTap: _toggle,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Distintivo del directo. Va en [MohanaColors.liveIndicatorStrong] y no en el
/// rosa del punto: ese, con texto blanco encima, no llega al contraste mínimo.
class _OnAirPill extends StatelessWidget {
  const _OnAirPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: const BoxDecoration(
        color: MohanaColors.liveIndicatorStrong,
        borderRadius: BorderRadius.all(Radius.circular(MohanaRadius.pill)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'EN EL AIRE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Play invertido: blanco sobre el morado de la tarjeta. Es la acción
/// principal de la pantalla, así que se lleva el mayor contraste disponible.
class _PlayButton extends StatelessWidget {
  final bool isLoading;
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayButton({
    required this.isLoading,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isPlaying ? 'Pausar el directo' : 'Escuchar el directo',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(15),
                  child: CircularProgressIndicator(
                    color: MohanaColors.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: MohanaColors.primary,
                  size: 28,
                ),
        ),
      ),
    );
  }
}
