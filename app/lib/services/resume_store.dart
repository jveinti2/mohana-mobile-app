import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un episodio que quedó a medias.
class ResumeEntry {
  final String audioUrl;
  final String title;

  /// Programa al que pertenece, para poder decir de dónde salió el episodio.
  final String program;
  final String imageUrl;
  final Duration position;
  final Duration duration;

  /// Cuándo se escuchó por última vez. Ordena la lista.
  final DateTime at;

  const ResumeEntry({
    required this.audioUrl,
    required this.title,
    required this.program,
    required this.imageUrl,
    required this.position,
    required this.duration,
    required this.at,
  });

  /// Avance entre 0 y 1, para la barra de la tarjeta.
  double get fraction {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Lo que falta, redondeado a minutos: "18 min".
  String get remainingLabel {
    final restante = duration - position;
    final minutos = restante.inMinutes;
    if (minutos < 1) return 'casi terminado';
    if (minutos < 60) return '$minutos min';
    final h = minutos ~/ 60;
    final m = minutos % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  Map<String, dynamic> toJson() => {
    'url': audioUrl,
    'title': title,
    'program': program,
    'image': imageUrl,
    'pos': position.inMilliseconds,
    'dur': duration.inMilliseconds,
    'at': at.millisecondsSinceEpoch,
  };

  static ResumeEntry? fromJson(Map<String, dynamic> json) {
    final url = json['url'];
    if (url is! String || url.isEmpty) return null;
    return ResumeEntry(
      audioUrl: url,
      title: json['title'] as String? ?? 'Episodio',
      program: json['program'] as String? ?? '',
      imageUrl: json['image'] as String? ?? '',
      position: Duration(milliseconds: json['pos'] as int? ?? 0),
      duration: Duration(milliseconds: json['dur'] as int? ?? 0),
      at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int? ?? 0),
    );
  }
}

/// Dónde se quedó cada episodio.
///
/// Un episodio de La Mohana dura de 30 minutos a una hora larga y se escucha
/// a ratos: sin esto, volver a la app significa empezar de cero, que es la
/// razón más común para no volver.
///
/// Se apoya en `shared_preferences`, igual que [IvooxCache], y falla en
/// silencio: perder la marca de avance molesta, romper la app no.
class ResumeStore {
  ResumeStore._();

  static const _key = 'resume_v1';

  /// Cuántos episodios se recuerdan. Más allá de una docena nadie vuelve.
  static const _max = 12;

  /// Margen en los extremos: por debajo no se considera empezado y por encima
  /// se da por terminado. Sin él, la lista se llenaría de episodios que solo
  /// se abrieron por error y de otros ya escuchados enteros.
  static const _edge = Duration(seconds: 30);

  static SharedPreferences? _prefs;
  static List<ResumeEntry> _entries = const [];
  static bool _loaded = false;

  /// Episodios a medias, del más reciente al más antiguo.
  static List<ResumeEntry> get entries => _entries;

  /// El último que quedó a medias, que es el que se ofrece retomar.
  static ResumeEntry? get latest => _entries.isEmpty ? null : _entries.first;

  /// Carga la lista en memoria. Se llama en el arranque, antes del primer
  /// frame, para que la biblioteca pueda pintar la tarjeta sin esperar.
  static Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('Resume: almacenamiento no disponible: $e');
      return;
    }
    final raw = _prefs?.getString(_key);
    if (raw == null) return;
    try {
      _entries = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(ResumeEntry.fromJson)
          .whereType<ResumeEntry>()
          .toList();
    } catch (e) {
      debugPrint('Resume: lista corrupta: $e');
      _entries = const [];
    }
  }

  /// Posición guardada de un episodio, si la hay.
  static Duration? positionFor(String audioUrl) {
    for (final e in _entries) {
      if (e.audioUrl == audioUrl) return e.position;
    }
    return null;
  }

  /// Anota el avance de un episodio.
  ///
  /// Los extremos no se guardan: apenas empezado no hay nada que retomar, y
  /// casi terminado se olvida para que no reaparezca en la lista.
  static Future<void> record({
    required String audioUrl,
    required String title,
    required String program,
    required String imageUrl,
    required Duration position,
    required Duration duration,
  }) async {
    if (audioUrl.isEmpty || duration <= Duration.zero) return;

    if (position < _edge || position > duration - _edge) {
      if (positionFor(audioUrl) != null) await forget(audioUrl);
      return;
    }

    final entry = ResumeEntry(
      audioUrl: audioUrl,
      title: title,
      program: program,
      imageUrl: imageUrl,
      position: position,
      duration: duration,
      at: DateTime.now(),
    );

    final next = [entry, ..._entries.where((e) => e.audioUrl != audioUrl)];
    _entries = next.length > _max ? next.sublist(0, _max) : next;
    await _flush();
  }

  /// Olvida un episodio (terminado, o retirado a mano de la lista).
  static Future<void> forget(String audioUrl) async {
    final next = _entries.where((e) => e.audioUrl != audioUrl).toList();
    if (next.length == _entries.length) return;
    _entries = next;
    await _flush();
  }

  static Future<void> _flush() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(
        _key,
        jsonEncode(_entries.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Resume: no se pudo guardar: $e');
    }
  }
}
