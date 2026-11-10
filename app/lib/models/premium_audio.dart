import 'podcast_episode.dart';

/// Un audio exclusivo de la emisora: contenido que **no** está en iVoox.
///
/// Es la pieza de la sección premium. Sale del modelo `ContenidoPremium` de
/// Hygraph, no de un feed, y por eso no comparte nada con [PodcastItem]: aquí
/// no hay programa ni catálogo, solo una lista plana de audios sueltos.
///
/// [audioUrl] llega **ya resuelto** por [PremiumService]: el campo `audioUrl`
/// del CMS si quien publicó lo llenó, y si no la dirección del archivo subido
/// a Hygraph. La app no distingue de dónde sale, y eso es deliberado — es lo
/// que permitirá mover los audios a otro almacenamiento pegando direcciones en
/// el panel, sin tocar una línea de código.
class PremiumAudio {
  final String id;
  final String title;

  /// Puede venir vacía: la descripción es opcional en el panel.
  final String description;

  /// Vacía ⇒ [MohanaCover] pinta el respaldo de marca, nunca un hueco.
  final String imageUrl;

  /// Vacía ⇒ la entrada se quedó sin audio. Ver [playable].
  final String audioUrl;

  /// Tal cual lo escribió la emisora ("48 min"), no una [Duration]: la fuente
  /// es un campo de texto libre y no merece la pena interpretarlo.
  final String? duration;

  final DateTime? publishedAt;

  const PremiumAudio({
    required this.id,
    required this.title,
    this.description = '',
    this.imageUrl = '',
    this.audioUrl = '',
    this.duration,
    this.publishedAt,
  });

  /// `false` cuando no hay audio que reproducir.
  ///
  /// El caso que de verdad pasa no es un descuido de la app: en Hygraph el
  /// archivo es una entrada aparte, y publicar la ficha **no publica el
  /// archivo**. Quien olvide marcar la casilla del audio al publicar tendrá
  /// una ficha visible y muda. Por eso la fila se pinta igual, avisando: si la
  /// escondiéramos, en el panel se vería todo correcto y nadie sabría qué
  /// arreglar.
  bool get playable => audioUrl.isNotEmpty;

  /// Cómo lo ve la capa de audio, que solo habla de [PodcastEpisode].
  ///
  /// La conversión vive aquí para no tener que enseñarle a [AudioService] un
  /// tipo nuevo: lo único que lee de la cola son `audioUrl`, `title` e
  /// `imageUrl`.
  PodcastEpisode get asEpisode => PodcastEpisode(
    title: title,
    audioUrl: audioUrl,
    date: publishedAt,
    description: description,
    imageUrl: imageUrl,
    duration: duration,
  );
}
