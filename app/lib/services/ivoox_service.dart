import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../config/ivoox_config.dart';
import '../models/podcast_episode.dart';
import '../models/podcast_item.dart';

/// Carga los programas de Emisora La Mohana desde los feeds RSS de iVoox.
///
/// Cada programa es un [PodcastItem] con su lista de [PodcastEpisode]
/// (título, MP3 directo, fecha, imagen). Los MP3 son reproducibles con
/// just_audio sin transformación.
///
/// Nota: en Flutter web el navegador puede bloquear estas peticiones por
/// CORS (iVoox no envía cabeceras CORS). En Android funciona sin problema.
class IvooxService {
  static const _maxEpisodesPerProgram = 30;

  /// Carga todos los programas en paralelo. Los que fallen se omiten.
  static Future<List<PodcastItem>> fetchPrograms() async {
    final results = await Future.wait(
      IvooxConfig.programs.map(_fetchProgram),
    );
    return results.whereType<PodcastItem>().toList();
  }

  static Future<PodcastItem?> _fetchProgram(IvooxProgramRef ref) async {
    try {
      final url = IvooxConfig.feedUrl(ref.feedId);
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final doc = XmlDocument.parse(utf8.decode(response.bodyBytes));
      final channel = doc.findAllElements('channel').firstOrNull;
      if (channel == null) return null;

      final channelTitle = _childText(channel, 'title') ?? ref.name;
      final channelImage = _imageUrl(channel);

      final episodes = <PodcastEpisode>[];
      for (final item in channel.findElements('item')) {
        final audioUrl = item
            .findElements('enclosure')
            .firstOrNull
            ?.getAttribute('url');
        if (audioUrl == null || audioUrl.isEmpty) continue;

        final itemImage = _imageUrl(item);
        episodes.add(PodcastEpisode(
          title: _childText(item, 'title') ?? 'Episodio',
          audioUrl: audioUrl,
          date: _parseRfc822(_childText(item, 'pubDate')),
          description: _stripHtml(_childText(item, 'description') ?? ''),
          imageUrl: itemImage.isNotEmpty ? itemImage : channelImage,
          duration: _parseDuration(_childText(item, 'itunes:duration')),
        ));
        if (episodes.length >= _maxEpisodesPerProgram) break;
      }

      if (episodes.isEmpty) return null;

      return PodcastItem(
        id: ref.feedId,
        title: channelTitle,
        description: _episodesLabel(episodes.length),
        body: '',
        imageUrl: channelImage,
        audioUrl: episodes.first.audioUrl,
        episodes: episodes.length.toString(),
        episodeList: episodes,
      );
    } catch (e) {
      debugPrint('iVoox: fallo cargando ${ref.name}: $e');
      return null;
    }
  }

  // ─── Parsing helpers ───────────────────────────────────────────

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

  static String _episodesLabel(int count) =>
      count == 1 ? '1 episodio' : '$count episodios';

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
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
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
