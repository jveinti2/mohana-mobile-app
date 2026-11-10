import 'package:flutter/foundation.dart';

import '../config/hygraph_config.dart';
import '../data/demo_premium.dart';
import '../models/premium_audio.dart';
import 'hygraph_service.dart';

/// Contenido exclusivo de la emisora: audios que no se publican en iVoox.
///
/// Mismo patrón que [ContentService] —clase estática, caché en memoria y TTL—
/// y por el mismo motivo: la pantalla pide y pinta, nadie se suscribe.
///
/// La diferencia está en cómo trata un fallo. Un corte de red **sí** llega a la
/// UI y se puede reintentar, como en el resto del feed. Lo que no se trata como
/// avería es que el modelo `ContenidoPremium` todavía no exista en el panel:
/// mientras se crea, la sección funciona con los audios de muestra en vez de
/// enseñar un error que nadie puede arreglar desde el teléfono.
class PremiumService {
  PremiumService._();

  /// Igual que el resto del CMS: lo editorial cambia a diario, cinco minutos
  /// es suficiente y evita descargar al cambiar de pestaña.
  static const _cacheTtl = Duration(minutes: 5);

  /// Tope de la consulta. Lejísimos de lo que la emisora va a publicar, y lo
  /// bastante bajo para que la respuesta siga cabiendo en una petición.
  static const _max = 50;

  static const _query = r'''
query ContenidoPremium($max: Int!, $anchoPortada: Int!) {
  contenidosPremium(orderBy: fecha_DESC, first: $max) {
    id
    titulo
    descripcion
    fecha
    duracion
    audioUrl
    audio {
      url
    }
    portada {
      url(transformation: {image: {resize: {width: $anchoPortada, fit: max}}})
    }
  }
}
''';

  static List<PremiumAudio>? _cached;
  static DateTime? _cachedAt;

  /// El modelo no existe en el proyecto (o no tiene lectura pública).
  ///
  /// Se recuerda para no repetir cada cinco minutos una consulta que se sabe
  /// rechazada. Se olvida al refrescar a mano, que es justo el gesto que hará
  /// quien acabe de crear el modelo en el panel.
  static bool _sinModelo = false;

  /// El modelo existe pero todavía no tiene ninguna ficha publicada.
  static bool _sinContenido = false;

  /// `true` cuando lo que se está mostrando son los audios de muestra y no
  /// contenido real de la emisora.
  static bool get usandoMuestra => _sinModelo || _sinContenido;

  /// Descarga el contenido exclusivo.
  ///
  /// Lanza [HygraphException] si falla la red o el CMS, igual que
  /// [ContentService]: la pantalla lo pinta con `LoadNotice` y ofrece
  /// reintentar. Lo único que **no** sale como error es que el modelo no esté
  /// creado todavía.
  static Future<List<PremiumAudio>> load({bool forceRefresh = false}) async {
    if (!HygraphConfig.isConfigured) return demoPremium;

    // Quien refresca a mano puede estar comprobando si el modelo que acaba de
    // crear ya se ve: hay que volver a preguntar.
    if (forceRefresh) _sinModelo = false;
    if (_sinModelo) return demoPremium;

    final cached = _cached;
    final at = _cachedAt;
    if (!forceRefresh &&
        cached != null &&
        at != null &&
        DateTime.now().difference(at) < _cacheTtl) {
      return cached;
    }

    try {
      final data = await HygraphService.query(
        _query,
        variables: {'max': _max, 'anchoPortada': HygraphConfig.anchoPortada},
      );
      final items = parse(data['contenidosPremium']);
      _cached = items;
      _cachedAt = DateTime.now();
      // Sin nada publicado se siguen oyendo las muestras. Una pestaña vacía no
      // se distingue de una rota, y mientras la emisora no suba su primer
      // audio esto es lo único con lo que se puede comprobar que suena. En
      // cuanto haya una ficha publicada, desaparecen solas.
      _sinContenido = items.isEmpty;
      if (items.isEmpty) return demoPremium;
      return items;
    } on HygraphException catch (e) {
      if (e.schemaError) {
        _sinModelo = true;
        _sinContenido = false;
        debugPrint('ContenidoPremium todavía no está en Hygraph: ${e.detail}');
        return demoPremium;
      }
      rethrow;
    }
  }

  static void invalidate() {
    _cached = null;
    _cachedAt = null;
    _sinModelo = false;
    _sinContenido = false;
  }

  /// Convierte la respuesta de Hygraph en modelos.
  ///
  /// Defensivo de principio a fin, como [ContentService]: en un CMS cualquier
  /// campo puede venir vacío porque alguien dejó la ficha a medias, y eso no
  /// puede tumbar la sección entera.
  @visibleForTesting
  static List<PremiumAudio> parse(Object? raw) {
    if (raw is! List) return const [];
    final items = <PremiumAudio>[];
    for (final entrada in raw) {
      if (entrada is! Map<String, dynamic>) continue;
      final id = (entrada['id'] as String?)?.trim() ?? '';
      if (id.isEmpty) continue;
      items.add(
        PremiumAudio(
          id: id,
          title: (entrada['titulo'] as String?)?.trim().isNotEmpty == true
              ? (entrada['titulo'] as String).trim()
              : 'Sin título',
          description: (entrada['descripcion'] as String?)?.trim() ?? '',
          imageUrl: _url(entrada['portada']),
          audioUrl: _audio(entrada),
          duration: (entrada['duracion'] as String?)?.trim().isNotEmpty == true
              ? (entrada['duracion'] as String).trim()
              : null,
          publishedAt: _fecha(entrada['fecha']),
        ),
      );
    }
    return items;
  }

  /// Dirección del audio, con el campo de texto por delante del archivo.
  ///
  /// El orden importa y es el eje de todo el diseño: `audioUrl` gana siempre.
  /// Sirve para dos cosas a la vez — mover los audios a otro almacenamiento sin
  /// tocar la app, y dejar una salida cuando el archivo subido a Hygraph no se
  /// puede leer (se quedó en borrador al publicar, el caso más probable).
  static String _audio(Map<String, dynamic> entrada) {
    final manual = (entrada['audioUrl'] as String?)?.trim() ?? '';
    if (manual.isNotEmpty) return manual;
    return _url(entrada['audio']);
  }

  /// Saca `url` de un asset de Hygraph, que llega como objeto o como null.
  static String _url(Object? asset) {
    if (asset is! Map<String, dynamic>) return '';
    return (asset['url'] as String?)?.trim() ?? '';
  }

  static DateTime? _fecha(Object? valor) {
    if (valor is! String) return null;
    return DateTime.tryParse(valor);
  }
}
