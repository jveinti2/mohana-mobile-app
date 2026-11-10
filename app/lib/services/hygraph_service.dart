import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/hygraph_config.dart';

/// Fallo al hablar con Hygraph: red, HTTP o errores que devuelve GraphQL.
///
/// Se distingue del `Exception` genérico para que el feed pueda enseñar algo
/// legible en vez de un volcado, igual que hacía con Drive.
class HygraphException implements Exception {
  final String message;

  /// Cuerpo de la respuesta cuando lo hay, para el diagnóstico.
  final String? detail;

  const HygraphException(this.message, {this.detail});

  /// GraphQL rechazó la consulta por el **esquema**, no por los datos: el
  /// modelo o un campo no existen en el proyecto.
  ///
  /// Se distingue de un fallo de red para que quien llama pueda seguir sin esa
  /// parte del contenido en vez de pintar un error. Es el caso de una sección
  /// cuyo modelo todavía no se ha creado en el panel: no es una avería, es que
  /// aún no está.
  ///
  /// Se detecta por el texto del mensaje porque es lo único que da Hygraph: un
  /// campo desconocido vuelve como HTTP 400 con `Cannot query field …`, sin
  /// código ni tipo de error aparte.
  bool get schemaError {
    final texto = detail ?? message;
    return texto.contains('Cannot query field') ||
        texto.contains('Unknown argument') ||
        texto.contains('Unknown field') ||
        texto.contains('Unknown type');
  }

  @override
  String toString() => detail == null ? message : '$message\n$detail';
}

/// Cliente mínimo de la API de Hygraph.
///
/// Hygraph solo habla GraphQL: no hay `GET /articulos`, sino un POST con la
/// consulta en el cuerpo. Lo que vuelve sigue siendo JSON, así que el resto de
/// la app no se entera.
///
/// No hace falta un paquete de GraphQL para esto: son dos docenas de líneas y
/// una dependencia menos que mantener.
class HygraphService {
  HygraphService._();

  static const _timeout = Duration(seconds: 20);

  /// Ejecuta [document] y devuelve el objeto `data`.
  ///
  /// Lanza [HygraphException] si la red falla, si el HTTP no es 200 o si
  /// GraphQL responde con errores.
  static Future<Map<String, dynamic>> query(
    String document, {
    Map<String, dynamic>? variables,
  }) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(HygraphConfig.endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': document,
              'variables': ?variables,
            }),
          )
          .timeout(_timeout);
    } catch (e) {
      throw HygraphException('No se pudo conectar con el CMS', detail: '$e');
    }

    // Igual que con Drive: se decodifica UTF-8 a mano en vez de fiarse de la
    // cabecera, o las tildes llegan rotas.
    final texto = utf8.decode(response.bodyBytes);

    if (response.statusCode != 200) {
      throw HygraphException(
        'El CMS respondió ${response.statusCode}',
        detail: texto.length > 500 ? texto.substring(0, 500) : texto,
      );
    }

    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(texto) as Map<String, dynamic>;
    } catch (e) {
      throw HygraphException('El CMS devolvió algo que no es JSON', detail: '$e');
    }

    final errors = payload['errors'];
    if (errors is List && errors.isNotEmpty) {
      final mensajes = errors
          .whereType<Map<String, dynamic>>()
          .map((e) => e['message']?.toString() ?? '?')
          .join('\n');
      throw HygraphException('El CMS rechazó la consulta', detail: mensajes);
    }

    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw HygraphException('El CMS respondió sin datos', detail: texto);
    }
    return data;
  }
}
