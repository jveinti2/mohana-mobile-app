import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/ivoox_config.dart';
import '../models/podcast_episode.dart';
import '../models/podcast_item.dart';

/// Caché en disco del contenido de iVoox (catálogo de programas y feeds ya
/// parseados), para que la app pinte al instante en el arranque y revalide
/// después contra la red (stale-while-revalidate).
///
/// Se apoya en `shared_preferences`: son pocos KB de JSON, no hace falta una
/// base de datos. Todas las operaciones fallan en silencio — la caché es una
/// optimización, nunca la fuente de verdad.
class IvooxCache {
  IvooxCache._();

  static const _catalogKey = 'ivoox_catalog_v1';
  static const _catalogAtKey = 'ivoox_catalog_at_v1';
  static const _feedPrefix = 'ivoox_feed_v1_';

  /// El catálogo cambia poco: medio día es suficiente para ver programas
  /// nuevos sin castigar el arranque.
  static const catalogTtl = Duration(hours: 12);

  /// Los episodios sí cambian a diario; media hora evita re-descargas al
  /// navegar entre pantallas sin quedarse desactualizado.
  static const feedTtl = Duration(minutes: 30);

  /// Tope de episodios que se serializan por programa. `shared_preferences`
  /// se carga entero en memoria al arrancar, así que de los feeds largos (740
  /// episodios) solo se guardan los más recientes: bastan para pintar al
  /// instante mientras el feed completo llega de la red.
  static const _maxCachedEpisodes = 50;

  static SharedPreferences? _prefs;

  static Future<SharedPreferences?> _instance() async {
    try {
      return _prefs ??= await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('iVoox caché: no disponible: $e');
      return null;
    }
  }

  /// Precalienta la instancia para que las lecturas posteriores sean síncronas.
  static Future<void> init() => _instance();

  // ─── Catálogo de programas ─────────────────────────────────────

  static Future<List<IvooxProgramRef>?> readCatalog() async {
    final prefs = await _instance();
    final raw = prefs?.getString(_catalogKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final refs = list
          .whereType<Map<String, dynamic>>()
          .map(IvooxProgramRef.fromJson)
          .whereType<IvooxProgramRef>()
          .toList();
      return refs.isEmpty ? null : refs;
    } catch (e) {
      debugPrint('iVoox caché: catálogo corrupto: $e');
      return null;
    }
  }

  static Future<void> writeCatalog(List<IvooxProgramRef> refs) async {
    if (refs.isEmpty) return;
    final prefs = await _instance();
    if (prefs == null) return;
    await prefs.setString(
      _catalogKey,
      jsonEncode(refs.map((r) => r.toJson()).toList()),
    );
    await prefs.setInt(_catalogAtKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// `true` si el catálogo guardado sigue dentro de su TTL.
  static Future<bool> isCatalogFresh() async {
    final prefs = await _instance();
    final at = prefs?.getInt(_catalogAtKey);
    if (at == null) return false;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(at),
    );
    return age < catalogTtl;
  }

  // ─── Feeds de programas ────────────────────────────────────────

  /// Devuelve el programa cacheado. Con [onlyFresh] descarta los que ya
  /// superaron el TTL; sin él sirve también contenido viejo (útil para pintar
  /// algo mientras la red responde).
  static Future<PodcastItem?> readProgram(
    String feedId, {
    bool onlyFresh = true,
  }) async {
    final prefs = await _instance();
    final raw = prefs?.getString('$_feedPrefix$feedId');
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (onlyFresh) {
        final at = json['at'] as int?;
        if (at == null) return null;
        final age = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(at),
        );
        if (age >= feedTtl) return null;
      }
      return _programFromJson(json);
    } catch (e) {
      debugPrint('iVoox caché: feed $feedId corrupto: $e');
      return null;
    }
  }

  static Future<void> writeProgram(PodcastItem item) async {
    final prefs = await _instance();
    if (prefs == null) return;
    await prefs.setString(
      '$_feedPrefix${item.id}',
      jsonEncode(_programToJson(item)),
    );
  }

  // ─── Serialización ─────────────────────────────────────────────

  static Map<String, dynamic> _programToJson(PodcastItem item) {
    final episodes = item.episodeList.length > _maxCachedEpisodes
        ? item.episodeList.sublist(0, _maxCachedEpisodes)
        : item.episodeList;
    return {
      'at': DateTime.now().millisecondsSinceEpoch,
      'id': item.id,
      'title': item.title,
      'description': item.description,
      'image': item.imageUrl,
      // Conteo real del feed, aunque se guarden menos episodios.
      'episodes': item.episodes,
      'items': [
        for (final e in episodes)
          {
            'title': e.title,
            'url': e.audioUrl,
            if (e.date != null) 'date': e.date!.millisecondsSinceEpoch,
            'desc': e.description,
            'image': e.imageUrl,
            if (e.duration != null) 'dur': e.duration,
          },
      ],
    };
  }

  static PodcastItem _programFromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => PodcastEpisode(
            title: e['title'] as String? ?? 'Episodio',
            audioUrl: e['url'] as String? ?? '',
            date: e['date'] is int
                ? DateTime.fromMillisecondsSinceEpoch(e['date'] as int)
                : null,
            description: e['desc'] as String? ?? '',
            imageUrl: e['image'] as String? ?? '',
            duration: e['dur'] as String?,
          ),
        )
        .where((e) => e.audioUrl.isNotEmpty)
        .toList();

    return PodcastItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      body: '',
      imageUrl: json['image'] as String? ?? '',
      audioUrl: items.isNotEmpty ? items.first.audioUrl : null,
      episodes: json['episodes'] as String?,
      episodeList: items,
      pageUrl: IvooxConfig.programUrl(json['id'] as String? ?? ''),
    );
  }
}
