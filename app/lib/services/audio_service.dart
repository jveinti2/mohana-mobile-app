import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';

import '../models/podcast_episode.dart';
import 'resume_store.dart';

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

  /// Última posición anotada en [ResumeStore]. Evita escribir en disco varias
  /// veces por segundo: el stream de posición emite mucho más rápido de lo que
  /// hace falta para no perder el sitio.
  Duration _lastRecorded = Duration.zero;

  /// Cada cuánto se anota el avance mientras suena.
  static const _recordEvery = Duration(seconds: 10);

  /// `true` entre abrir un episodio y saltar a donde se dejó. Sin esta
  /// guarda, los eventos de posición que emite al montar la fuente (todos en 0)
  /// se tomarían por "apenas empezado" y borrarían la marca antes de usarla.
  bool _restoring = false;

  /// `true` cuando el usuario quiere que suene. Es lo que distingue una pausa
  /// suya de un corte del stream, y por tanto si hay que reconectar.
  bool _wantsPlayback = false;

  /// Reintentos seguidos de reconexión al directo, para espaciarlos.
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  /// Espera antes de cada reintento. El directo se cae sobre todo al cambiar
  /// de red, así que los primeros intentos van pegados.
  static const List<Duration> _reconnectDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 30),
  ];

  /// Carátula de la emisora para la notificación de medios, ya en disco.
  ///
  /// La notificación no sabe leer `assets/`: solo acepta `file:` o `http:`,
  /// así que el logotipo se copia una vez a la caché de la app.
  Uri? _stationArt;

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

  /// Fuente del directo con sus metadatos.
  ///
  /// Toda fuente tiene que llevar su [MediaItem]: es de ahí de donde la
  /// notificación y la pantalla de bloqueo sacan título, emisora y carátula.
  AudioSource get _liveSource => AudioSource.uri(
    Uri.parse(streamUrl),
    tag: MediaItem(
      id: streamUrl,
      title: stationName,
      artist: '$frequency · La emisora de las mujeres',
      album: stationName,
      artUri: _stationArt,
    ),
  );

  /// Fuente del episodio en curso con sus metadatos.
  AudioSource _episodeSource(String url) => AudioSource.uri(
    Uri.parse(url),
    tag: MediaItem(
      id: url,
      title: _episodeTitle ?? stationName,
      artist: _episodeSubtitle?.isNotEmpty == true
          ? _episodeSubtitle!
          : stationName,
      album: _episodeSubtitle?.isNotEmpty == true
          ? _episodeSubtitle!
          : stationName,
      artUri: _episodeImageUrl?.isNotEmpty == true
          ? Uri.tryParse(_episodeImageUrl!) ?? _stationArt
          : _stationArt,
    ),
  );

  /// Deja el logotipo de la emisora en la caché y devuelve su ruta.
  Future<void> _prepareStationArt() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/logo_emisora.png');
      if (!file.existsSync()) {
        final data = await rootBundle.load('assets/images/logo_emisora.png');
        await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
      _stationArt = file.uri;
    } catch (e) {
      // Sin carátula la notificación sigue saliendo, solo más sosa.
      debugPrint('No se pudo preparar la carátula de la emisora: $e');
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _prepareStationArt();

    _player.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      _isLoading =
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      // Al pausar se anota sin esperar al siguiente intervalo: es justo cuando
      // el usuario suele irse de la app.
      if (wasPlaying && !state.playing) _record(force: true);

      if (state.playing && state.processingState == ProcessingState.ready) {
        // Sonando de verdad: se olvida la cuenta de reintentos.
        _reconnectAttempts = 0;
      }
      // Los botones de la notificación tocan el reproductor directamente, sin
      // pasar por [play]/[pause], así que la intención se relee del estado.
      // Solo con la fuente montada: en reposo, un `playing` en falso puede ser
      // el stream cortado, y ahí la intención de oír sigue en pie.
      if (state.processingState == ProcessingState.ready ||
          state.processingState == ProcessingState.buffering) {
        _wantsPlayback = state.playing;
      }
      // Un directo no "termina": si el reproductor se queda en reposo o dice
      // que acabó mientras el usuario esperaba oírlo, es que se cortó el
      // stream. Hay que volver a montarlo, no quedarse en silencio.
      if (_isLive &&
          _wantsPlayback &&
          (state.processingState == ProcessingState.completed ||
              (state.processingState == ProcessingState.idle &&
                  !state.playing))) {
        _scheduleLiveReconnect();
      }
      notifyListeners();
    });

    // Los errores de red del stream no llegan por el estado, sino por aquí.
    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace _) {
        debugPrint('Error de reproducción: $e');
        if (_isLive && _wantsPlayback) _scheduleLiveReconnect();
      },
    );

    // Marca dónde se quedó el episodio, para poder retomarlo.
    _player.positionStream.listen((position) => _record());

    // La duración llega cuando el episodio termina de abrirse: hay que
    // repintar los controles (tiempo total, barra activa).
    _player.durationStream.listen((_) => notifyListeners());

    try {
      await _player.setAudioSource(_liveSource);
    } catch (e) {
      debugPrint('Error loading stream: $e');
    }
  }

  /// Programa un reintento de conexión al directo, espaciándolos.
  void _scheduleLiveReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    final delay =
        _reconnectDelays[_reconnectAttempts.clamp(
          0,
          _reconnectDelays.length - 1,
        )];
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, () async {
      if (!_isLive || !_wantsPlayback) return;
      try {
        await _player.setAudioSource(_liveSource);
        await _player.play();
      } catch (e) {
        debugPrint('Reintento del directo fallido: $e');
        _scheduleLiveReconnect();
      }
    });
  }

  /// Vuelve a montar la fuente si el reproductor quedó en reposo.
  ///
  /// El botón de parar de la notificación suelta el decodificador: sin volver
  /// a montar la fuente, `play()` no sonaría.
  Future<void> _ensureSource() async {
    if (_player.processingState != ProcessingState.idle) return;
    if (_isLive) {
      await _player.setAudioSource(_liveSource);
      return;
    }
    final url = _episodeUrl;
    if (url == null) return;
    final saved = ResumeStore.positionFor(url);
    _restoring = true;
    try {
      await _player.setAudioSource(_episodeSource(url));
      await _player.setSpeed(_speed);
      if (saved != null && saved > Duration.zero) {
        _lastRecorded = saved;
        await _player.seek(saved);
      }
    } finally {
      _restoring = false;
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    _wantsPlayback = true;
    _reconnectAttempts = 0;
    try {
      await _ensureSource();
    } catch (e) {
      debugPrint('Error montando la fuente: $e');
      if (_isLive) _scheduleLiveReconnect();
      return;
    }
    await _player.play();
  }

  Future<void> pause() async {
    // Una pausa del usuario no es un corte: no se reintenta nada.
    _wantsPlayback = false;
    _reconnectTimer?.cancel();
    await _player.pause();
  }

  /// Vuelve al stream en vivo de la emisora.
  Future<void> playLive() async {
    _wantsPlayback = true;
    _reconnectAttempts = 0;
    if (!_isLive) {
      _record(force: true);
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
        await _player.setAudioSource(_liveSource);
      } catch (e) {
        debugPrint('Error volviendo al vivo: $e');
        _scheduleLiveReconnect();
        return;
      }
    } else {
      await _ensureSource();
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
    // El episodio anterior se anota antes de soltarlo.
    _record(force: true);

    // Se lee ahora, antes de tocar el reproductor: es el último momento en que
    // la marca del episodio que se va a abrir sigue intacta.
    final saved = ResumeStore.positionFor(url);
    _restoring = true;
    _wantsPlayback = true;
    _reconnectTimer?.cancel();

    _isLive = false;
    _episodeTitle = title;
    _episodeSubtitle = subtitle;
    _episodeUrl = url;
    _episodeImageUrl = imageUrl;
    _lastRecorded = Duration.zero;
    // La cola se asigna siempre, incluso vacía. Antes solo se tocaba
    // `if (queue.isNotEmpty)`, así que abrir un audio suelto dejaba en pie la
    // del programa anterior y el anterior/siguiente saltaba a otro programa.
    // Ya pasaba al retomar un episodio desde la biblioteca cuando su feed
    // todavía no estaba cargado (`_resumeEntry` pasa la cola vacía).
    _queue = queue;
    _queueIndex = queue.isEmpty
        ? -1
        : (queueIndex >= 0
              ? queueIndex
              : queue.indexWhere((e) => e.audioUrl == url));
    notifyListeners();
    try {
      await _player.setAudioSource(_episodeSource(url));
      await _player.setSpeed(_speed);
      // Retomar donde se dejó.
      if (saved != null && saved > Duration.zero) {
        _lastRecorded = saved;
        await _player.seek(saved);
      }
      await _player.play();
    } catch (e) {
      debugPrint('Error reproduciendo episodio: $e');
    } finally {
      _restoring = false;
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
      // Si el episodio no trae carátula propia se queda la del programa, que
      // es la que ya está sonando: saltar de pista no debe vaciar la portada.
      imageUrl: episode.imageUrl.isNotEmpty
          ? episode.imageUrl
          : (_episodeImageUrl ?? ''),
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

  /// Anota el avance del episodio en curso.
  ///
  /// Sin [force] solo escribe cada [_recordEvery]; el directo no se anota
  /// nunca, porque no hay a dónde volver.
  void _record({bool force = false}) {
    if (_isLive || _restoring) return;
    final url = _episodeUrl;
    final total = _player.duration;
    if (url == null || total == null || total <= Duration.zero) return;

    final position = _player.position;
    if (!force && (position - _lastRecorded).abs() < _recordEvery) return;
    _lastRecorded = position;

    unawaited(
      ResumeStore.record(
        audioUrl: url,
        title: _episodeTitle ?? 'Episodio',
        program: _episodeSubtitle ?? '',
        imageUrl: _episodeImageUrl ?? '',
        position: position,
        duration: total,
      ),
    );
  }

  @override
  void dispose() {
    _record(force: true);
    _reconnectTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
