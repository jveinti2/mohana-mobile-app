import 'dart:math';
import '../config/drive_config.dart';
import '../models/news_article.dart';
import '../models/podcast_item.dart';
import 'drive_service.dart';
import 'task_pool.dart';

/// Resultado del parseo de un archivo markdown con frontmatter.
class _ParsedMarkdown {
  final Map<String, String> frontmatter;
  final String body;

  const _ParsedMarkdown({required this.frontmatter, required this.body});
}

/// Contenido completo del home feed, cargado desde Google Drive.
///
/// Los podcasts no salen de aquí: la fuente es iVoox ([IvooxService]). Solo se
/// conserva [podcastDestacado] como respaldo para cuando iVoox no responde.
class HomeContent {
  final NewsArticle? titular;
  final List<NewsArticle> articulos;
  final PodcastItem? podcastDestacado;

  const HomeContent({
    this.titular,
    this.articulos = const [],
    this.podcastDestacado,
  });
}

/// Servicio de alto nivel que carga contenido desde Google Drive.
///
/// Lee la estructura de carpetas en Drive y la convierte en modelos de la app.
class ContentService {
  /// Peticiones simultáneas a Drive. Acorta la espera sin arriesgarse a que
  /// Drive limite por ráfaga.
  static const _driveConcurrency = 4;

  /// Cuánto se reutiliza lo ya descargado. Evita que cambiar de pestaña o
  /// volver atrás dispare otra vez todas las peticiones a Drive.
  static const _cacheTtl = Duration(minutes: 5);

  static HomeContent? _cached;
  static DateTime? _cachedAt;

  /// Carga todo el contenido del home feed.
  static Future<HomeContent> loadHomeContent({bool forceRefresh = false}) async {
    if (!DriveConfig.isConfigured) {
      return const HomeContent();
    }

    final cached = _cached;
    final at = _cachedAt;
    if (!forceRefresh &&
        cached != null &&
        at != null &&
        DateTime.now().difference(at) < _cacheTtl) {
      return cached;
    }

    // Descubrir carpetas sección dentro de la raíz
    final rootFolders = await DriveService.listFolders(
      DriveConfig.rootFolderId,
    );
    final sectionMap = <String, String>{};
    for (final folder in rootFolders) {
      sectionMap[folder.name.toLowerCase()] = folder.id;
    }

    // Cargar cada sección en paralelo
    final results = await Future.wait([
      _loadTitular(sectionMap[DriveConfig.titularFolder]),
      _loadArticulos(sectionMap[DriveConfig.articulosFolder]),
      _loadPodcastDestacado(sectionMap[DriveConfig.podcastDestacadoFolder]),
    ]);

    final content = HomeContent(
      titular: results[0] as NewsArticle?,
      articulos: results[1] as List<NewsArticle>,
      podcastDestacado: results[2] as PodcastItem?,
    );
    _cached = content;
    _cachedAt = DateTime.now();
    return content;
  }

  /// Carga el artículo titular (carpeta con contenido.md + imagen).
  static Future<NewsArticle?> _loadTitular(String? folderId) async {
    if (folderId == null) return null;
    return _loadSingleArticle(folderId, 'titular');
  }

  /// Carga la lista de artículos (subcarpetas dentro de articulos/).
  static Future<List<NewsArticle>> _loadArticulos(String? folderId) async {
    if (folderId == null) return [];

    final subfolders = await DriveService.listFolders(folderId);

    // En paralelo (con tope): cada artículo son 2-3 peticiones a Drive, y en
    // serie la espera era la suma de todas.
    final loaded = await pooled<DriveFile, NewsArticle?>(
      subfolders,
      _driveConcurrency,
      (folder) => _loadSingleArticle(folder.id, folder.name),
    );
    final articles = loaded.whereType<NewsArticle>().toList();

    // Ordenar por fecha (más reciente primero)
    articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return articles;
  }

  /// Carga un artículo desde una carpeta (contenido.md + imagen.*).
  static Future<NewsArticle?> _loadSingleArticle(
    String folderId,
    String fallbackId,
  ) async {
    final files = await DriveService.listFiles(folderId);

    // Buscar markdown y imagen
    DriveFile? mdFile;
    DriveFile? imgFile;
    for (final file in files) {
      if (file.isMarkdown) mdFile = file;
      if (file.isImage) imgFile = file;
    }

    if (mdFile == null) return null;

    final markdown = await DriveService.downloadText(mdFile.id);
    final parsed = _parseMarkdown(markdown);

    return NewsArticle(
      id: fallbackId,
      title: parsed.frontmatter['titulo'] ?? fallbackId,
      summary: _extractSummary(parsed.body),
      body: parsed.body,
      imageUrl: imgFile != null ? DriveService.imageUrl(imgFile.id) : '',
      category: parsed.frontmatter['categoria'] ?? 'General',
      author: parsed.frontmatter['autor'] ?? 'La Mohana',
      publishedAt: _parseDate(parsed.frontmatter['fecha']),
    );
  }

  /// Carga el podcast destacado (carpeta con contenido.md + portada.*).
  static Future<PodcastItem?> _loadPodcastDestacado(String? folderId) async {
    if (folderId == null) return null;
    return _loadSinglePodcast(folderId, 'podcast_destacado');
  }

  /// Carga un podcast desde una carpeta (contenido.md + portada.*).
  static Future<PodcastItem?> _loadSinglePodcast(
    String folderId,
    String fallbackId,
  ) async {
    final files = await DriveService.listFiles(folderId);

    DriveFile? mdFile;
    DriveFile? imgFile;
    for (final file in files) {
      if (file.isMarkdown) mdFile = file;
      if (file.isImage) imgFile = file;
    }

    if (mdFile == null) return null;

    final markdown = await DriveService.downloadText(mdFile.id);
    final parsed = _parseMarkdown(markdown);

    return PodcastItem(
      id: fallbackId,
      title: parsed.frontmatter['titulo'] ?? fallbackId,
      description: parsed.frontmatter['descripcion'] ?? '',
      body: parsed.body,
      imageUrl: imgFile != null ? DriveService.imageUrl(imgFile.id) : '',
      audioUrl: parsed.frontmatter['url'],
      episodes: parsed.frontmatter['episodios'],
    );
  }

  /// Parsea un archivo markdown con frontmatter YAML.
  ///
  /// Formato esperado:
  /// ```
  /// ---
  /// titulo: Mi Título
  /// fecha: 2026-05-20
  /// ---
  /// Cuerpo del contenido aquí...
  /// ```
  static _ParsedMarkdown _parseMarkdown(String content) {
    final trimmed = content.trim();
    final frontmatter = <String, String>{};
    var body = trimmed;

    if (trimmed.startsWith('---')) {
      final endIndex = trimmed.indexOf('---', 3);
      if (endIndex != -1) {
        final yamlBlock = trimmed.substring(3, endIndex).trim();
        body = trimmed.substring(endIndex + 3).trim();

        for (final line in yamlBlock.split('\n')) {
          final colonIndex = line.indexOf(':');
          if (colonIndex != -1) {
            final key = line.substring(0, colonIndex).trim().toLowerCase();
            final value = line.substring(colonIndex + 1).trim();
            if (key.isNotEmpty && value.isNotEmpty) {
              frontmatter[key] = value;
            }
          }
        }
      }
    }

    return _ParsedMarkdown(frontmatter: frontmatter, body: body);
  }

  /// Extrae las primeras ~150 caracteres como resumen.
  static String _extractSummary(String body) {
    if (body.isEmpty) return '';
    final clean = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final end = min(150, clean.length);
    final summary = clean.substring(0, end);
    return end < clean.length ? '$summary...' : summary;
  }

  /// Parsea una fecha en formato YYYY-MM-DD.
  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      return DateTime(
        int.tryParse(parts[0]) ?? 2026,
        int.tryParse(parts[1]) ?? 1,
        int.tryParse(parts[2]) ?? 1,
      );
    }
    return DateTime.now();
  }
}
