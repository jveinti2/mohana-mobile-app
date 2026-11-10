import 'podcast_episode.dart';

class PodcastItem {
  final String id;
  final String title;
  final String description;
  final String body;
  final String imageUrl;
  final String? audioUrl;
  final String? episodes;

  /// Episodios del programa (cuando proviene de un feed iVoox).
  final List<PodcastEpisode> episodeList;

  /// URL de la página del programa en iVoox (opcional).
  final String? pageUrl;

  const PodcastItem({
    required this.id,
    required this.title,
    required this.description,
    required this.body,
    required this.imageUrl,
    this.audioUrl,
    this.episodes,
    this.episodeList = const [],
    this.pageUrl,
  });

  /// Etiqueta legible del número de episodios ("1 episodio" / "740 episodios").
  /// Cae a [description] cuando el conteo no es numérico (el destacado del CMS).
  String get episodesLabel {
    final n = int.tryParse(episodes ?? '');
    if (n == null) return description;
    return n == 1 ? '1 episodio' : '$n episodios';
  }

  /// Conteo real de episodios que declara el feed, si se conoce.
  int? get episodeCount => int.tryParse(episodes ?? '');

  /// `false` cuando solo se tiene una parte de los episodios (por ejemplo, los
  /// que se guardaron en caché): hay que releer el feed para completarlos.
  bool get hasAllEpisodes {
    final total = episodeCount;
    return total == null || episodeList.length >= total;
  }

  /// Episodio más reciente por fecha. No asume que el feed venga ordenado;
  /// si ningún episodio trae fecha, cae al primero del feed.
  PodcastEpisode? get latestEpisode {
    if (episodeList.isEmpty) return null;
    PodcastEpisode? best;
    for (final e in episodeList) {
      if (e.date == null) continue;
      if (best == null || e.date!.isAfter(best.date!)) best = e;
    }
    return best ?? episodeList.first;
  }

  /// Copia con los episodios ya cargados desde el feed, conservando los datos
  /// del catálogo que el feed no trae.
  PodcastItem withEpisodes(PodcastItem loaded) => PodcastItem(
    id: id,
    title: loaded.title.isNotEmpty ? loaded.title : title,
    description: loaded.description.isNotEmpty
        ? loaded.description
        : description,
    body: body,
    imageUrl: loaded.imageUrl.isNotEmpty ? loaded.imageUrl : imageUrl,
    audioUrl: loaded.audioUrl ?? audioUrl,
    episodes: loaded.episodes ?? episodes,
    episodeList: loaded.episodeList,
    pageUrl: loaded.pageUrl ?? pageUrl,
  );
}
