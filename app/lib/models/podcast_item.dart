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
}
