/// Un episodio individual de un programa (proveniente del RSS de iVoox).
class PodcastEpisode {
  final String title;
  final String audioUrl;
  final DateTime? date;
  final String description;
  final String imageUrl;

  /// Duración legible del episodio (ej. "48 min"), si el feed la provee.
  final String? duration;

  const PodcastEpisode({
    required this.title,
    required this.audioUrl,
    this.date,
    this.description = '',
    this.imageUrl = '',
    this.duration,
  });
}
