import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../config/ivoox_config.dart';
import '../models/podcast_episode.dart';
import '../models/podcast_item.dart';
import 'ivoox_cache.dart';
import 'task_pool.dart';

/// Página del catálogo de programas de la emisora.
class IvooxCatalogPage {
  final List<IvooxProgramRef> programs;

  /// `true` si la página venía llena, así que probablemente hay otra.
  final bool hasMore;

  const IvooxCatalogPage({this.programs = const [], this.hasMore = false});
}

/// Catálogo de programas de la emisora.
class IvooxCatalog {
  final List<IvooxProgramRef> programs;

  /// `true` cuando no se pudo hablar con iVoox y lo que se muestra sale de la
  /// caché vencida o de la semilla embebida. La UI lo usa para avisar.
  final bool isStale;

  const IvooxCatalog(this.programs, {this.isStale = false});

  bool get isEmpty => programs.isEmpty;
}

/// Resultado de cargar feeds: los que llegaron y los que no.
///
/// Los fallos ya no se pierden en un `catch` mudo: llegan a la UI para poder
/// avisar y reintentar solo lo que falta.
class IvooxLoadResult {
  final List<PodcastItem> programs;
  final List<IvooxProgramRef> failed;

  const IvooxLoadResult({this.programs = const [], this.failed = const []});

  bool get hasFailures => failed.isNotEmpty;

  /// Fusiona el resultado de un reintento sobre este, sustituyendo los
  /// programas que ahora sí cargaron y conservando el orden original.
  IvooxLoadResult mergedWith(IvooxLoadResult retry) {
    if (retry.programs.isEmpty) return this;
    final byId = {for (final p in retry.programs) p.id: p};
    final merged = [
      for (final p in programs) byId.remove(p.id) ?? p,
      ...byId.values,
    ];
    final stillFailing = failed.where(
      (r) => !retry.programs.any((p) => p.id == r.feedId),
    );
    return IvooxLoadResult(
      programs: merged,
      failed: [...stillFailing, ...retry.failed],
    );
  }
}

/// Datos que cruzan al isolate para parsear un feed RSS.
class _FeedJob {
  final Uint8List bytes;
  final String feedId;
  final String fallbackName;
  final String fallbackCover;

  const _FeedJob(
    this.bytes,
    this.feedId,
    this.fallbackName,
    this.fallbackCover,
  );
}

/// Carga los contenidos de Emisora La Mohana desde iVoox.
///
/// iVoox es la fuente: el catálogo de programas se descubre en tiempo de
/// ejecución desde la página de la emisora y los episodios se leen del feed
/// RSS de cada programa, que se descarga **solo cuando hace falta** (al abrir
/// el programa o al calcular los episodios recientes), nunca todos de golpe en
/// el arranque. El parseo va en un isolate y todo se cachea en disco.
///
/// Nota: en Flutter web el navegador bloquea estas peticiones por CORS (iVoox
/// no envía las cabeceras). En Android/iOS funciona sin problema.
class IvooxService {
  IvooxService._();

  static const _timeout = Duration(seconds: 15);
  static const _maxAttempts = 3;
  static const _maxConcurrent = 4;
  static const _maxCatalogPages = 20;

  /// Episodios ya parseados en esta sesión, para no volver a la red ni al
  /// disco al navegar entre pantallas.
  static final Map<String, PodcastItem> _memory = {};

  // ─── Catálogo de programas ─────────────────────────────────────

  /// Lista de programas de la emisora.
  ///
  /// Sirve primero lo cacheado (arranque instantáneo) y luego revalida contra
  /// iVoox. [onProgress] se invoca con la lista acumulada al terminar cada
  /// página, para que la UI se vaya rellenando sin esperar al catálogo entero.
  static Future<IvooxCatalog> loadCatalog({
    bool forceRefresh = false,
    void Function(List<IvooxProgramRef> partial)? onProgress,
  }) async {
    if (!forceRefresh && await IvooxCache.isCatalogFresh()) {
      final cached = await IvooxCache.readCatalog();
      if (cached != null && cached.isNotEmpty) return IvooxCatalog(cached);
    }

    final client = http.Client();
    final refs = <IvooxProgramRef>[];
    final seen = <String>{};
    try {
      for (var page = 1; page <= _maxCatalogPages; page++) {
        final result = await fetchCatalogPage(page, client: client);
        for (final ref in result.programs) {
          if (seen.add(ref.feedId)) refs.add(ref);
        }
        if (refs.isNotEmpty) onProgress?.call(List.unmodifiable(refs));
        if (!result.hasMore) break;
      }
    } catch (e) {
      debugPrint('iVoox: catálogo no disponible: $e');
    } finally {
      client.close();
    }

    if (refs.isNotEmpty) {
      await IvooxCache.writeCatalog(refs);
      return IvooxCatalog(refs);
    }

    // Sin red: lo último conocido y, si no hay nada, la semilla embebida.
    final cached = await IvooxCache.readCatalog();
    return IvooxCatalog(
      (cached != null && cached.isNotEmpty)
          ? cached
          : IvooxConfig.fallbackPrograms,
      isStale: true,
    );
  }

  /// Descarga y parsea una página del listado de programas de la emisora.
  static Future<IvooxCatalogPage> fetchCatalogPage(
    int page, {
    http.Client? client,
  }) async {
    final own = client == null;
    final c = client ?? http.Client();
    try {
      final body = await _getBytes(IvooxConfig.catalogUrl(page), c);
      if (body == null) return const IvooxCatalogPage();
      return await compute(_parseCatalogJob, body);
    } finally {
      if (own) c.close();
    }
  }

  // ─── Episodios de un programa ──────────────────────────────────

  /// Programa con todos sus episodios. Usa memoria -> disco -> red, en ese
  /// orden, salvo [forceRefresh].
  static Future<PodcastItem?> fetchProgram(
    IvooxProgramRef ref, {
    bool forceRefresh = false,
    http.Client? client,
  }) async {
    if (!forceRefresh) {
      final hot = _memory[ref.feedId];
      if (hot != null) return hot;
      final cold = await IvooxCache.readProgram(ref.feedId);
      if (cold != null) {
        _memory[ref.feedId] = cold;
        return cold;
      }
    }

    final own = client == null;
    final c = client ?? http.Client();
    try {
      final bytes = await _getBytes(IvooxConfig.feedUrl(ref.feedId), c);
      if (bytes == null) return _staleOrNull(ref);

      final item = await compute(
        _parseFeedJob,
        _FeedJob(bytes, ref.feedId, ref.name, ref.coverUrl),
      );
      if (item == null) return _staleOrNull(ref);

      _memory[ref.feedId] = item;
      unawaited(IvooxCache.writeProgram(item));
      return item;
    } catch (e) {
      debugPrint('iVoox: fallo cargando ${ref.name}: $e');
      return _staleOrNull(ref);
    } finally {
      if (own) c.close();
    }
  }

  /// Carga varios programas con concurrencia limitada, informando de los que
  /// fallaron. [onProgram] permite pintar cada uno en cuanto llega.
  static Future<IvooxLoadResult> loadPrograms(
    List<IvooxProgramRef> refs, {
    bool forceRefresh = false,
    void Function(PodcastItem program)? onProgram,
  }) async {
    if (refs.isEmpty) return const IvooxLoadResult();

    final client = http.Client();
    final programs = <PodcastItem>[];
    final failed = <IvooxProgramRef>[];
    try {
      await pooled<IvooxProgramRef, void>(refs, _maxConcurrent, (ref) async {
        final item = await fetchProgram(
          ref,
          forceRefresh: forceRefresh,
          client: client,
        );
        if (item == null) {
          failed.add(ref);
        } else {
          programs.add(item);
          onProgram?.call(item);
        }
      });
    } finally {
      client.close();
    }

    // Respetar el orden de las refs, no el de finalización.
    final byId = {for (final p in programs) p.id: p};
    return IvooxLoadResult(
      programs: [
        for (final ref in refs)
          if (byId[ref.feedId] != null) byId[ref.feedId]!,
      ],
      failed: failed,
    );
  }

  /// Tarjeta de programa sin episodios, para pintar el catálogo sin tocar
  /// ningún feed. Los episodios se cargan al abrir el programa.
  static PodcastItem stubFor(IvooxProgramRef ref) {
    final cached = _memory[ref.feedId];
    if (cached != null) return cached;
    return PodcastItem(
      id: ref.feedId,
      title: ref.name,
      description: '',
      body: '',
      imageUrl: ref.coverUrl,
      pageUrl: IvooxConfig.programUrl(ref.feedId),
    );
  }

  /// Referencia equivalente a un programa ya cargado (para reintentos).
  static IvooxProgramRef refFor(PodcastItem item) =>
      IvooxProgramRef(item.title, item.id, coverUrl: item.imageUrl);

  /// Vacía la caché en memoria (el disco tiene su propio TTL).
  static void clearMemory() => _memory.clear();

  // ─── Red ───────────────────────────────────────────────────────

  /// GET con timeout y reintentos. Devuelve null si no hay nada que parsear.
  ///
  /// Solo reintenta lo que puede mejorar con otro intento (timeout, error de
  /// socket, 5xx); un 404 se da por perdido de inmediato.
  static Future<Uint8List?> _getBytes(String url, http.Client client) async {
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final res = await client.get(Uri.parse(url)).timeout(_timeout);
        if (res.statusCode == 200) return res.bodyBytes;
        if (res.statusCode < 500) return null;
      } on TimeoutException {
        // reintentable
      } on SocketException {
        // reintentable
      } on http.ClientException {
        // reintentable
      }
      if (attempt < _maxAttempts) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
    return null;
  }

  /// Último contenido conocido de un programa, aunque haya expirado.
  static Future<PodcastItem?> _staleOrNull(IvooxProgramRef ref) async {
    final stale = await IvooxCache.readProgram(ref.feedId, onlyFresh: false);
    if (stale != null) _memory[ref.feedId] = stale;
    return stale;
  }

  // ─── Parseo (se ejecuta en un isolate) ─────────────────────────

  /// Extrae los programas de una página del listado de la emisora.
  ///
  /// Se apoya en los `<meta itemprop>` de schema.org, más estables que las
  /// clases CSS del maquetado.
  static IvooxCatalogPage _parseCatalogJob(Uint8List bytes) {
    final html = utf8.decode(bytes, allowMalformed: true);
    final blocks = html.split('modulo-type-programa');
    final programs = <IvooxProgramRef>[];
    final seen = <String>{};

    for (var i = 1; i < blocks.length; i++) {
      final block = blocks[i];
      final id = RegExp(r'_sq_f(\d+)_1\.html').firstMatch(block)?.group(1);
      if (id == null || !seen.add(id)) continue;

      final name = RegExp(
        r'<meta itemprop="name" content="([^"]*)"',
      ).firstMatch(block)?.group(1);
      if (name == null || name.trim().isEmpty) continue;

      final cover = RegExp(r'data-src="([^"]*)"').firstMatch(block)?.group(1);

      programs.add(
        IvooxProgramRef(
          _unescapeHtml(name).trim(),
          id,
          coverUrl: _coverUrl(cover),
        ),
      );
    }

    return IvooxCatalogPage(
      programs: programs,
      hasMore: programs.length >= IvooxConfig.catalogPageSize,
    );
  }

  /// La miniatura del listado viene a 77 px; se le pide al redimensionador de
  /// iVoox una versión utilizable como carátula.
  static String _coverUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final url = _unescapeHtml(raw).trim();
    if (!url.startsWith('http')) return '';
    return url.replaceAll('w=77&h=77', 'w=320&h=320');
  }

  /// Deshace las entidades HTML. Se aplica dos veces porque iVoox las
  /// re-escapa dentro de los atributos (`&amp;iacute;`).
  static String _unescapeHtml(String input) {
    var out = input;
    for (var pass = 0; pass < 2; pass++) {
      out = out.replaceAllMapped(RegExp(r'&(#\d+|#x[0-9a-fA-F]+|[a-zA-Z]+);'), (
        m,
      ) {
        final code = m.group(1)!;
        if (code.startsWith('#x') || code.startsWith('#X')) {
          final n = int.tryParse(code.substring(2), radix: 16);
          return n == null ? m.group(0)! : String.fromCharCode(n);
        }
        if (code.startsWith('#')) {
          final n = int.tryParse(code.substring(1));
          return n == null ? m.group(0)! : String.fromCharCode(n);
        }
        return _entities[code.toLowerCase()] ?? m.group(0)!;
      });
    }
    return out;
  }

  static const _entities = <String, String>{
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': ' ',
    'aacute': 'á',
    'eacute': 'é',
    'iacute': 'í',
    'oacute': 'ó',
    'uacute': 'ú',
    'ntilde': 'ñ',
    'uuml': 'ü',
    'ccedil': 'ç',
    'iexcl': '¡',
    'iquest': '¿',
    'ordf': 'ª',
    'ordm': 'º',
    'deg': '°',
    'hellip': '…',
    'mdash': '—',
    'ndash': '–',
    'lsquo': '‘',
    'rsquo': '’',
    'ldquo': '“',
    'rdquo': '”',
    'bull': '•',
    'middot': '·',
  };

  /// Convierte el XML del feed en un [PodcastItem] con todos sus episodios.
  static PodcastItem? _parseFeedJob(_FeedJob job) {
    try {
      final doc = XmlDocument.parse(
        utf8.decode(job.bytes, allowMalformed: true),
      );
      final channel = doc.findAllElements('channel').firstOrNull;
      if (channel == null) return null;

      final channelTitle = _childText(channel, 'title') ?? job.fallbackName;
      var channelImage = _imageUrl(channel);
      if (channelImage.isEmpty) channelImage = job.fallbackCover;

      final episodes = <PodcastEpisode>[];
      for (final item in channel.findElements('item')) {
        final audioUrl = item
            .findElements('enclosure')
            .firstOrNull
            ?.getAttribute('url');
        if (audioUrl == null || audioUrl.isEmpty) continue;

        final itemImage = _imageUrl(item);
        episodes.add(
          PodcastEpisode(
            title: _childText(item, 'title') ?? 'Episodio',
            audioUrl: audioUrl,
            date: _parseRfc822(_childText(item, 'pubDate')),
            description: _stripHtml(_childText(item, 'description') ?? ''),
            imageUrl: itemImage.isNotEmpty ? itemImage : channelImage,
            duration: _parseDuration(_childText(item, 'itunes:duration')),
          ),
        );
      }

      if (episodes.isEmpty) return null;

      // Del más reciente al más antiguo: iVoox suele darlos así, pero no
      // siempre, y el orden decide qué episodio abre la pantalla.
      episodes.sort((a, b) {
        final da = a.date;
        final db = b.date;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      return PodcastItem(
        id: job.feedId,
        title: channelTitle,
        description: _stripHtml(_childText(channel, 'description') ?? ''),
        body: '',
        imageUrl: channelImage,
        audioUrl: episodes.first.audioUrl,
        episodes: episodes.length.toString(),
        episodeList: episodes,
        pageUrl: IvooxConfig.programUrl(job.feedId),
      );
    } catch (e) {
      debugPrint('iVoox: feed ${job.feedId} ilegible: $e');
      return null;
    }
  }

  // ─── Helpers de parseo ─────────────────────────────────────────

  static String? _childText(XmlElement parent, String name) {
    final el = parent.findElements(name).firstOrNull;
    final text = el?.innerText.trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// Imagen de iTunes (`<itunes:image href="...">`) o `<image><url>`.
  static String _imageUrl(XmlElement el) {
    final itunes = el.findElements('itunes:image').firstOrNull;
    final href = itunes?.getAttribute('href');
    if (href != null && href.isNotEmpty) return href;

    final image = el.findElements('image').firstOrNull;
    final urlNode = image?.findElements('url').firstOrNull;
    return urlNode?.innerText.trim() ?? '';
  }

  /// Convierte `<itunes:duration>` a un texto corto tipo "48 min".
  /// Acepta segundos ("2918") o reloj ("48:38" / "01:12:05").
  static String? _parseDuration(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    int? totalSeconds;
    if (raw.contains(':')) {
      final parts = raw.split(':').map((p) => int.tryParse(p.trim())).toList();
      if (parts.any((p) => p == null)) return null;
      totalSeconds = 0;
      for (final p in parts) {
        totalSeconds = totalSeconds! * 60 + p!;
      }
    } else {
      totalSeconds = int.tryParse(raw.trim());
    }
    if (totalSeconds == null || totalSeconds <= 0) return null;

    final minutes = totalSeconds ~/ 60;
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  static String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  /// Parsea fechas RFC-822 tipo "Fri, 29 May 2026 16:15:42 +0200".
  static DateTime? _parseRfc822(String? raw) {
    if (raw == null) return null;
    final m = RegExp(r'(\d{1,2})\s+(\w{3})\w*\s+(\d{4})').firstMatch(raw);
    if (m == null) return null;
    final day = int.tryParse(m.group(1)!);
    final month = _months[m.group(2)!.toLowerCase()];
    final year = int.tryParse(m.group(3)!);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }
}
