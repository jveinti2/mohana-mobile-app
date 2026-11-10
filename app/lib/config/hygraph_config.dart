/// Configuración de Hygraph, el CMS de la emisora.
///
/// Sustituye a Google Drive como fuente del contenido editorial. La diferencia
/// para quien escribe es que ya no hay carpetas ni `contenido.md`: se entra al
/// panel, se llena un formulario y se le da a **Publish**.
///
/// Panel de edición: <https://app.hygraph.com> (proyecto `mohana-app`).
///
/// Modelos que consume la app:
/// ```
/// Articulo          titulo, fecha, categoria, autor, imagen,
///                   resumen (opcional), cuerpo, titular
/// PodcastDestacado  titulo, descripcion, portada, url
/// Franja            programa, dias, horaInicio, horaFin   → parrilla del directo
/// ```
///
/// Lo que está en borrador no se ve en la app: solo lo publicado.
class HygraphConfig {
  HygraphConfig._();

  /// Endpoint de solo lectura (High Performance Content API).
  ///
  /// Va en claro a propósito, igual que antes la API key de Drive: solo
  /// permite leer lo que ya es público. Escribir requiere un token que no
  /// vive en la app.
  static const endpoint =
      'https://us-west-2.cdn.hygraph.com/content/cmsxfdt9305as06w6zt9vjukk/master';

  static bool get isConfigured => endpoint.isNotEmpty;

  /// Ancho al que se piden las fotos de artículo. Hygraph las redimensiona en
  /// su CDN: pedir el original significaba bajarse los 4 MB que subió quien
  /// escribió, con datos móviles.
  static const anchoImagen = 800;

  /// Ancho de las portadas de podcast, que se ven más pequeñas.
  static const anchoPortada = 600;
}
