import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/drive_config.dart';

/// Archivo de Drive con su metadata básica.
class DriveFile {
  final String id;
  final String name;
  final String mimeType;

  const DriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
  });

  bool get isFolder => mimeType == 'application/vnd.google-apps.folder';
  bool get isImage =>
      mimeType.startsWith('image/') ||
      name.endsWith('.png') ||
      name.endsWith('.jpg') ||
      name.endsWith('.jpeg');
  bool get isMarkdown => name.endsWith('.md');
}

/// Servicio de bajo nivel para interactuar con Google Drive API v3.
///
/// Solo requiere API Key (lectura pública, sin OAuth).
class DriveService {
  static const _baseUrl = 'https://www.googleapis.com/drive/v3';

  /// Lista archivos/carpetas dentro de una carpeta padre.
  static Future<List<DriveFile>> listFiles(String parentId) async {
    final query = Uri.encodeComponent("'$parentId' in parents and trashed=false");
    final url = '$_baseUrl/files'
        '?q=$query'
        '&fields=files(id,name,mimeType)'
        '&orderBy=name'
        '&pageSize=100'
        '&key=${DriveConfig.apiKey}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw DriveException(
        'Error listando archivos',
        statusCode: response.statusCode,
        url: url,
        body: response.body,
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final files = data['files'] as List<dynamic>? ?? [];

    return files
        .map((f) => DriveFile(
              id: f['id'] as String,
              name: f['name'] as String,
              mimeType: f['mimeType'] as String? ?? '',
            ))
        .toList();
  }

  /// Lista solo subcarpetas dentro de una carpeta padre.
  static Future<List<DriveFile>> listFolders(String parentId) async {
    final query = Uri.encodeComponent(
        "'$parentId' in parents and mimeType='application/vnd.google-apps.folder' and trashed=false");
    final url = '$_baseUrl/files'
        '?q=$query'
        '&fields=files(id,name,mimeType)'
        '&orderBy=name'
        '&pageSize=100'
        '&key=${DriveConfig.apiKey}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw DriveException(
        'Error listando carpetas',
        statusCode: response.statusCode,
        url: url,
        body: response.body,
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final files = data['files'] as List<dynamic>? ?? [];

    return files
        .map((f) => DriveFile(
              id: f['id'] as String,
              name: f['name'] as String,
              mimeType: f['mimeType'] as String,
            ))
        .toList();
  }

  /// Descarga el contenido de texto de un archivo.
  static Future<String> downloadText(String fileId) async {
    final url = '$_baseUrl/files/$fileId'
        '?alt=media'
        '&key=${DriveConfig.apiKey}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw DriveException(
        'Error descargando archivo',
        statusCode: response.statusCode,
        url: url,
        body: response.body,
      );
    }

    // Drive no envía charset en Content-Type, así que http decodifica como
    // Latin-1 por defecto y rompe las tildes. Forzamos UTF-8.
    return utf8.decode(response.bodyBytes);
  }

  /// Construye la URL pública de una imagen en Drive.
  ///
  /// Usa el endpoint de la Drive API v3 con API key, no `drive.google.com/uc`
  /// (devuelve HTML de virus-scan) ni `drive.google.com/thumbnail` (no envía
  /// headers CORS, falla en Flutter web).
  /// Este endpoint sí envía CORS correctamente y devuelve los bytes reales.
  static String imageUrl(String fileId) {
    return '$_baseUrl/files/$fileId?alt=media&key=${DriveConfig.apiKey}';
  }

  /// Busca una carpeta por nombre dentro de una carpeta padre.
  static Future<DriveFile?> findFolder(String parentId, String name) async {
    final folders = await listFolders(parentId);
    final lower = name.toLowerCase();
    for (final folder in folders) {
      if (folder.name.toLowerCase() == lower) return folder;
    }
    return null;
  }
}

class DriveException implements Exception {
  final String message;
  final int? statusCode;
  final String? url;
  final String? body;

  const DriveException(
    this.message, {
    this.statusCode,
    this.url,
    this.body,
  });

  @override
  String toString() {
    final buffer = StringBuffer('DriveException: $message');
    if (statusCode != null) buffer.write(' (HTTP $statusCode)');
    if (body != null && body!.isNotEmpty) {
      final preview = body!.length > 300 ? '${body!.substring(0, 300)}...' : body;
      buffer.write('\nRespuesta: $preview');
    }
    if (url != null) buffer.write('\nURL: $url');
    return buffer.toString();
  }
}
