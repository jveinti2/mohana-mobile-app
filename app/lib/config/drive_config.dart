/// Configuración de Google Drive como CMS.
///
/// Para configurar:
/// 1. Crear un proyecto en Google Cloud Console (console.cloud.google.com)
/// 2. Habilitar la API de Google Drive
/// 3. Crear una API Key (Credenciales > Crear credenciales > Clave de API)
/// 4. Restringir la key solo a "Google Drive API"
/// 5. Pegar la key en [apiKey]
/// 6. Crear la carpeta mohana_app/ en Google Drive
/// 7. Compartir como "Cualquier persona con el enlace puede ver"
/// 8. Copiar el ID de la carpeta (la parte larga de la URL) en [rootFolderId]
///
/// Estructura esperada en Drive:
/// ```
/// mohana_app/
///   titular/            → contenido.md + imagen.png/jpg
///   articulos/          → subcarpetas, cada una con contenido.md + imagen.png/jpg
///   podcasts/           → subcarpetas, cada una con contenido.md + portada.png/jpg
///   podcast_destacado/  → contenido.md + portada.png/jpg
/// ```
class DriveConfig {
  DriveConfig._();

  /// Google API Key (solo lectura, sin OAuth)
  static const apiKey = 'AIzaSyDx8_ovXHPkWzemxMh1Gq4XeOV0NhUGnJ8';

  /// ID de la carpeta raíz mohana_app/ en Google Drive
  static const rootFolderId = '1GBO1HvO1Jc_2VnzFTDFhVfWHjCTl_44n';

  /// Nombres esperados de las carpetas sección
  static const titularFolder = 'titular';
  static const articulosFolder = 'articulos';
  static const podcastsFolder = 'podcasts';
  static const podcastDestacadoFolder = 'podcast_destacado';

  /// Verifica si la configuración de Drive está lista
  static bool get isConfigured => apiKey.isNotEmpty && rootFolderId.isNotEmpty;
}
