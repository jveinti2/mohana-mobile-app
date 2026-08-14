import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  static const String streamUrl = 'https://stream.zeno.fm/kxmzbp902ndtv';
  static const String stationName = 'La Mohana';
  static const String frequency = '91.2 FM';

  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  /// `true` mientras suena el stream en vivo; `false` si suena un episodio.
  bool _isLive = true;
  String? _episodeTitle;
  String? _episodeSubtitle;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isLive => _isLive;

  /// Título a mostrar en el reproductor según el modo actual.
  String get nowPlayingTitle =>
      _isLive ? stationName : (_episodeTitle ?? stationName);

  /// Subtítulo a mostrar en el reproductor según el modo actual.
  String get nowPlayingSubtitle => _isLive
      ? '$frequency · La emisora de las mujeres'
      : (_episodeSubtitle ?? '');

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      notifyListeners();
    });

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
  Future<void> playEpisode(
    String url, {
    required String title,
    String? subtitle,
  }) async {
    _isLive = false;
    _episodeTitle = title;
    _episodeSubtitle = subtitle;
    notifyListeners();
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      debugPrint('Error reproduciendo episodio: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
