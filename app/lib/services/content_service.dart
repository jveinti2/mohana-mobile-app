import 'dart:math';

import '../config/hygraph_config.dart';
import '../models/news_article.dart';
import '../models/podcast_item.dart';
import 'hygraph_service.dart';

/// Contenido completo del home feed, cargado desde Hygraph.
///
/// Los podcasts no salen de aquí: la fuente es iVoox ([IvooxService]). Solo se
/// conserva [podcastDestacado], que sí es editorial.
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

/// Servicio de alto nivel que carga el contenido editorial desde Hygraph.
///
/// Frente a Drive, esto es **una sola petición**: allí había que listar la
/// carpeta raíz, luego cada subcarpeta, luego bajar cada `contenido.md` — tres
/// rondas y una tanda concurrente. Aquí GraphQL trae titular, artículos y
/// podcast destacado de golpe, así que ni hace falta acotar concurrencia.
class ContentService {
  ContentService._();

  /// Cuánto se reutiliza lo ya descargado. Evita que cambiar de pestaña o
  /// volver atrás dispare otra petición.
  static const _cacheTtl = Duration(minutes: 5);

  /// Tope de artículos que se traen. Son los que la app llega a enseñar; el
  /// resto sigue en el CMS pero no se descarga.
  static const _maxArticulos = 40;

  static HomeContent? _cached;
  static DateTime? _cachedAt;

  static const _query = r'''
query ContenidoInicio($max: Int!, $anchoImagen: Int!, $anchoPortada: Int!) {
  titulares: articulos(where: {titular: true}, orderBy: fecha_DESC, first: 1) {
    ...campos
  }
  articulos(orderBy: fecha_DESC, first: $max) {
    ...campos
  }
  podcastsDestacados(orderBy: updatedAt_DESC, first: 1) {
    id
    titulo
    descripcion
    url
    portada {
      url(transformation: {image: {resize: {width: $anchoPortada, fit: max}}})
    }
  }
}

fragment campos on Articulo {
  id
  titulo
  fecha
  categoria
  autor
  resumen
  titular
  cuerpo { markdown }
  imagen {
    url(transformation: {image: {resize: {width: $anchoImagen, fit: max}}})
  }
}
''';

  /// Carga todo el contenido del home feed.
  static Future<HomeContent> loadHomeContent({bool forceRefresh = false}) async {
    if (!HygraphConfig.isConfigured) return const HomeContent();

    final cached = _cached;
    final at = _cachedAt;
    if (!forceRefresh &&
        cached != null &&
        at != null &&
        DateTime.now().difference(at) < _cacheTtl) {
      return cached;
    }

    final data = await HygraphService.query(
      _query,
      variables: {
        'max': _maxArticulos,
        'anchoImagen': HygraphConfig.anchoImagen,
        'anchoPortada': HygraphConfig.anchoPortada,
      },
    );

    final titularJson = _primero(data['titulares']);
    final titular = titularJson == null ? null : _articulo(titularJson);

    // El titular también viene en la lista general (es un artículo más, solo
    // que marcado). Se quita de ahí para no enseñarlo dos veces.
    final articulos = _lista(data['articulos'])
        .map(_articulo)
        .where((a) => a.id != titular?.id)
        .toList();

    final destacado = _primero(data['podcastsDestacados']);
    final content = HomeContent(
      titular: titular,
      articulos: articulos,
      podcastDestacado: destacado == null ? null : _podcast(destacado),
    );
    _cached = content;
    _cachedAt = DateTime.now();
    return content;
  }

  /// Olvida lo cacheado. Para el diagnóstico, que debe medir la red de verdad.
  static void invalidate() {
    _cached = null;
    _cachedAt = null;
  }

  // ─── Mapeo ─────────────────────────────────────────────────────

  static NewsArticle _articulo(Map<String, dynamic> json) {
    final cuerpo = (json['cuerpo'] as Map<String, dynamic>?)?['markdown'];
    final body = (cuerpo as String?)?.trim() ?? '';
    final resumen = (json['resumen'] as String?)?.trim();

    return NewsArticle(
      id: json['id'] as String? ?? '',
      title: (json['titulo'] as String?)?.trim() ?? 'Sin título',
      // El resumen es opcional en el panel: si nadie lo escribe, se saca del
      // cuerpo como se hacía con los archivos de Drive.
      summary: resumen != null && resumen.isNotEmpty
          ? resumen
          : _extractSummary(body),
      body: body,
      imageUrl: _url(json['imagen']),
      category: categoriaVisible(json['categoria'] as String?),
      author: (json['autor'] as String?)?.trim().isNotEmpty == true
          ? (json['autor'] as String).trim()
          : 'La Mohana',
      publishedAt: _fecha(json['fecha'] as String?),
    );
  }

  static PodcastItem _podcast(Map<String, dynamic> json) => PodcastItem(
    id: json['id'] as String? ?? 'podcast_destacado',
    title: (json['titulo'] as String?)?.trim() ?? '',
    description: (json['descripcion'] as String?)?.trim() ?? '',
    body: '',
    imageUrl: _url(json['portada']),
    audioUrl: json['url'] as String?,
  );

  static String _url(Object? asset) =>
      (asset as Map<String, dynamic>?)?['url'] as String? ?? '';

  /// Hygraph devuelve el identificador de la enumeración (`medio_ambiente`),
  /// no lo que se ve en el panel. La app necesita el nombre legible: es lo que
  /// se pinta en la etiqueta y con lo que `MohanaCategoryColors` elige color.
  static const _categorias = <String, String>{
    'impacto_social': 'Impacto Social',
    'cultura': 'Cultura',
    'salud': 'Salud',
    'medio_ambiente': 'Medio Ambiente',
    'musica': 'Música',
    'comunidad': 'Comunidad',
    'educacion': 'Educación',
    'infraestructura': 'Infraestructura',
  };

  /// Nombre visible de una categoría. Si en el CMS añaden una que la app no
  /// conoce, se enseña con guiones bajos convertidos en espacios en vez de
  /// desaparecer.
  static String categoriaVisible(String? apiId) {
    if (apiId == null || apiId.isEmpty) return 'General';
    final conocida = _categorias[apiId];
    if (conocida != null) return conocida;
    return apiId
        .split('_')
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  static List<Map<String, dynamic>> _lista(Object? raw) =>
      (raw as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];

  static Map<String, dynamic>? _primero(Object? raw) {
    final lista = _lista(raw);
    return lista.isEmpty ? null : lista.first;
  }

  /// Extrae las primeras ~150 caracteres como resumen.
  static String _extractSummary(String body) {
    if (body.isEmpty) return '';
    final clean = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final end = min(150, clean.length);
    final summary = clean.substring(0, end);
    return end < clean.length ? '$summary...' : summary;
  }

  /// Parsea una fecha en formato YYYY-MM-DD, que es lo que da el campo Date.
  static DateTime _fecha(String? raw) {
    if (raw == null || raw.isEmpty) return DateTime.now();
    return DateTime.tryParse(raw) ?? DateTime.now();
  }
}
