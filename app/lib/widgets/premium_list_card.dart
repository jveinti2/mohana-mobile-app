import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/premium_audio.dart';
import '../services/audio_service.dart';
import '../utils/dates.dart';
import 'mohana_cover.dart';

/// Fila de un audio exclusivo.
///
/// Misma forma que [ArticleListCard] —carátula, meta, título y descripción—
/// porque es la fila que la app ya usa para "una cosa con imagen y texto", y
/// repetirla ahorra inventar un lenguaje visual nuevo para lo mismo.
///
/// Sin `onTap`: quien decide si la fila responde es la pantalla, porque es lo
/// que distingue un audio que suena de uno que se quedó sin archivo.
class PremiumListCard extends StatelessWidget {
  final PremiumAudio item;

  const PremiumListCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
      padding: const EdgeInsets.all(MohanaSpacing.md),
      decoration: MohanaDecorations.tonalCard,
      child: Row(
        children: [
          _Caratula(item: item),
          const SizedBox(width: MohanaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Los dos textos van flexibles y a una línea. Es la misma
                // lección de ArticleListCard: con la letra al ×2 en un
                // teléfono estrecho, esta fila es lo primero que se sale de la
                // tarjeta.
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'EXCLUSIVO',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: MohanaColors.secondary500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const _Separador(),
                    Flexible(
                      child: Text(
                        _meta(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: item.playable
                              ? MohanaColors.onSurfaceVariant
                              : MohanaColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MohanaSpacing.xs + 2),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.breeSerif(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: MohanaColors.onSurface,
                    height: 1.3,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: MohanaSpacing.xs + 2),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: MohanaColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Qué se lee al lado de "EXCLUSIVO".
  ///
  /// Cuando falta el audio, ese hueco se usa para decirlo: es lo único que le
  /// explica a la emisora que la ficha está publicada pero el archivo no.
  static String _meta(PremiumAudio item) {
    if (!item.playable) return 'Audio no disponible';
    if (item.duration != null) return item.duration!;
    final fecha = item.publishedAt;
    return fecha == null ? '' : fechaRelativa(fecha);
  }
}

/// Carátula con la insignia de reproducción encima.
///
/// La insignia es lo que dice que esto suena en vez de leerse. Cambia a un
/// icono de onda cuando es justo este audio el que está puesto, y desaparece
/// cuando no hay nada que reproducir.
class _Caratula extends StatelessWidget {
  final PremiumAudio item;

  /// Lado de la carátula. Es una medida fija a propósito y no incumple la
  /// regla de la casa: dentro no hay texto, así que ampliar la letra no la
  /// aprieta. Igual que en [ArticleListCard].
  static const _lado = 100.0;
  static const _insignia = 28.0;

  const _Caratula({required this.item});

  @override
  Widget build(BuildContext context) {
    final caratula = MohanaCover.square(
      url: item.imageUrl,
      size: _lado,
      borderRadius: MohanaRadius.mdAll,
    );

    if (!item.playable) return caratula;

    return SizedBox(
      width: _lado,
      height: _lado,
      child: Stack(
        children: [
          caratula,
          Positioned(
            right: MohanaSpacing.xs,
            bottom: MohanaSpacing.xs,
            // Solo la insignia escucha al reproductor: repintar la fila
            // entera en cada cambio de estado del audio saldría caro en una
            // lista. Mismo apaño que _LiveButton en la barra inferior.
            child: ListenableBuilder(
              listenable: AudioService(),
              builder: (context, _) {
                final suena =
                    AudioService().currentEpisodeUrl == item.audioUrl;
                return Container(
                  width: _insignia,
                  height: _insignia,
                  decoration: const BoxDecoration(
                    gradient: MohanaGradients.brand,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    suena
                        ? Icons.graphic_eq_rounded
                        : Icons.play_arrow_rounded,
                    size: 16,
                    color: MohanaColors.onPrimary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Punto de separación, copiado de [ArticleListCard]: la regla de la casa es
/// punto y nunca barra vertical.
class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: MohanaSpacing.xs + 2),
      decoration: const BoxDecoration(
        color: MohanaColors.outlineVariant,
        shape: BoxShape.circle,
      ),
    );
  }
}
