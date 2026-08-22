import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/podcast_episode.dart';

/// Posición de reproducción de un episodio, para pintar la barra de progreso.
class PlaybackProgress {
  final Duration position;
  final Duration buffered;
  final Duration duration;

  const PlaybackProgress({
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.duration = Duration.zero,
  });

  /// Avance entre 0 y 1. Cero mientras no se conozca la duración.
  double get fraction {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }
}

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  static const String streamUrl = 'https://stream.zeno.fm/kxmzbp902ndtv';
  static const String stationName = 'La Mohana';
  static const String frequency = '91.2 FM';

  /// Saltos de la barra de control, en la convención habitual de podcasts.
  static const Duration skipBack = Duration(seconds: 10);
  static const Duration skipForward = Duration(seconds: 30);

  /// Velocidades que ofrece el reproductor de episodios.
  static const List<double> speeds = [1.0, 1.25, 1.5, 2.0];

  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  /// `true` mientras suena el stream en vivo; `false` si suena un episodio.
  bool _isLive = true;
  String? _episodeTitle;
  String? _episodeSubtitle;
  String? _episodeUrl;
  String? _episodeImageUrl;
  double _speed = 1.0;

  /// Episodios del programa en curso, para pasar al anterior/siguiente.
  List<PodcastEpisode> _queue = const [];
  int _queueIndex = -1;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isLive => _isLive;
  double get speed => _speed;

  /// URL del episodio en curso. Identifica el episodio de forma unívoca: los
  /// títulos se repiten entre episodios de un mismo programa.
  String? get currentEpisodeUrl => _isLive ? null : _episodeUrl;

  /// Carátula del episodio en curso, si el feed la traía.
  String get currentEpisodeImageUrl => _isLive ? '' : (_episodeImageUrl ?? '');

  /// Título a mostrar en el reproductor según el modo actual.
  String get nowPlayingTitle =>
      _isLive ? stationName : (_episodeTitle ?? stationName);

  /// Subtítulo a mostrar en el reproductor según el modo actual.
  String get nowPlayingSubtitle => _isLive
      ? '$frequency · La emisora de las mujeres'
      : (_episodeSubtitle ?? '');

  /// Nombre del programa al que pertenece el episodio en curso.
  String get currentProgramTitle => _isLive ? '' : (_episodeSubtitle ?? '');

  bool get hasPrevious => !_isLive && _queueIndex > 0;
  bool get hasNext =>
      !_isLive && _queueIndex >= 0 && _queueIndex < _queue.length - 1;

  /// Progreso de reproducción. Solo lo escucha el reproductor de episodios:
  /// emite varias veces por segundo, así que no pasa por [notifyListeners].
  Stream<PlaybackProgress> get progressStream => _player.positionStream.map(
    (position) => PlaybackProgress(
      position: position,
      buffered: _player.bufferedPosition,
      duration: _player.duration ?? Duration.zero,
    ),
  );

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading =
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      notifyListeners();
    });

    // La duración llega cuando el episodio termina de abrirse: hay que
    // repintar los controles (tiempo total, barra activa).
    _player.durationStream.listen((_) => notifyListeners());

    try {
      await _player.setUrl(streamUrl);
    } catch (e) {
      debugPrint('Error loading stream: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  /// Vuelve al stream en vivo de la emisora.
  Future<void> playLive() async {
    if (!_isLive) {
      _isLive = true;
      _episodeTitle = null;
      _episodeSubtitle = null;
      _episodeUrl = null;
      _episodeImageUrl = null;
      _queue = const [];
      _queueIndex = -1;
      await _setSpeed(1.0);
      notifyListeners();
      try {
        await _player.setUrl(streamUrl);
      } catch (e) {
        debugPrint('Error volviendo al vivo: $e');
        return;
      }
    }
    await _player.play();
  }

  /// Reproduce un episodio de podcast (iVoox) dentro de la app.
  ///
  /// [queue] es la lista de episodios del programa: permite pasar al anterior
  /// o al siguiente desde el reproductor sin volver a la pantalla del programa.
  Future<void> playEpisode(
    String url, {
    required String title,
    String? subtitle,
    String imageUrl = '',
    List<PodcastEpisode> queue = const [],
    int queueIndex = -1,
  }) async {
    _isLive = false;
    _episodeTitle = title;
    _episodeSubtitle = subtitle;
    _episodeUrl = url;
    _episodeImageUrl = imageUrl;
    if (queue.isNotEmpty) {
      _queue = queue;
      _queueIndex = queueIndex >= 0
          ? queueIndex
          : queue.indexWhere((e) => e.audioUrl == url);
    }
    notifyListeners();
    try {
      await _player.setUrl(url);
      await _player.setSpeed(_speed);
      await _player.play();
    } catch (e) {
      debugPrint('Error reproduciendo episodio: $e');
    }
  }

  /// Reproduce un [episode] de la cola del programa en curso.
  Future<void> playFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final episode = _queue[index];
    await playEpisode(
      episode.audioUrl,
      title: episode.title,
      subtitle: _episodeSubtitle,
      imageUrl: episode.imageUrl,
      queue: _queue,
      queueIndex: index,
    );
  }

  Future<void> skipToPrevious() async {
    if (hasPrevious) await playFromQueue(_queueIndex - 1);
  }

  Future<void> skipToNext() async {
    if (hasNext) await playFromQueue(_queueIndex + 1);
  }

  /// Salta a un punto del episodio. En el directo no aplica.
  Future<void> seek(Duration position) async {
    if (_isLive) return;
    final total = _player.duration;
    var target = position;
    if (target < Duration.zero) target = Duration.zero;
    if (total != null && target > total) target = total;
    await _player.seek(target);
  }

  /// Retrocede [skipBack] desde la posición actual.
  Future<void> rewind() => seek(_player.position - skipBack);

  /// Adelanta [skipForward] desde la posición actual.
  Future<void> fastForward() => seek(_player.position + skipForward);

  /// Pasa a la siguiente velocidad de la lista ([speeds]).
  Future<void> cycleSpeed() async {
    final next = speeds[(speeds.indexOf(_speed) + 1) % speeds.length];
    await _setSpeed(next);
    notifyListeners();
  }

  Future<void> _setSpeed(double value) async {
    _speed = value;
    try {
      await _player.setSpeed(value);
    } catch (e) {
      debugPrint('Error cambiando la velocidad: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
