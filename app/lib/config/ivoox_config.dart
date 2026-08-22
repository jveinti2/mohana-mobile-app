/// Referencia a un programa de la emisora en iVoox.
class IvooxProgramRef {
  final String name;

  /// ID numérico del feed (la parte después de `_f` en la URL del programa).
  final String feedId;

  /// Carátula del programa, cuando viene del catálogo remoto.
  final String coverUrl;

  const IvooxProgramRef(this.name, this.feedId, {this.coverUrl = ''});

  Map<String, dynamic> toJson() => {
    'name': name,
    'feedId': feedId,
    if (coverUrl.isNotEmpty) 'cover': coverUrl,
  };

  static IvooxProgramRef? fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final feedId = json['feedId'];
    if (name is! String || feedId is! String || feedId.isEmpty) return null;
    return IvooxProgramRef(
      name,
      feedId,
      coverUrl: json['cover'] is String ? json['cover'] as String : '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is IvooxProgramRef && other.feedId == feedId;

  @override
  int get hashCode => feedId.hashCode;
}

/// Configuración de la emisora en iVoox.
///
/// La lista de programas **no** vive en la app: se descubre en tiempo de
/// ejecución desde la página de la emisora ([catalogUrl]), de modo que cuando
/// la emisora publica un programa nuevo aparece sin necesidad de recompilar.
/// [fallbackPrograms] es solo la red de seguridad para el primer arranque sin
/// conexión, cuando aún no hay catálogo en caché.
class IvooxConfig {
  IvooxConfig._();

  /// ID de la estación: https://www.ivoox.com/...emisora-la-mohana_al_32053771_1.html
  static const stationId = '32053771';
  static const stationSlug = 'emisora-la-mohana';

  /// Programas por página en el listado de la emisora.
  static const catalogPageSize = 12;

  /// Página del catálogo de programas de la emisora ([page] empieza en 1).
  static String catalogUrl(int page) =>
      'https://www.ivoox.com/escuchar-programas-${stationSlug}_al_${stationId}_$page.html?show=programs';

  /// Construye la URL del feed RSS a partir del [feedId].
  static String feedUrl(String feedId) =>
      'https://feeds.ivoox.com/feed_fg_f${feedId}_filtro_1.xml';

  /// Página del programa en iVoox (para compartir / abrir en el navegador).
  static String programUrl(String feedId) =>
      'https://www.ivoox.com/podcast_sq_f${feedId}_1.html';

  /// Semilla de emergencia: solo se usa si el catálogo remoto falla y no hay
  /// nada en caché. Puede quedar desactualizada — la fuente es iVoox.
  static const fallbackPrograms = <IvooxProgramRef>[
    IvooxProgramRef('Revista Informativa La Mohana', '12112848'),
    IvooxProgramRef('Comuna Popular', '12108048'),
    IvooxProgramRef('Magazín Informativo La Mohana', '12250823'),
    IvooxProgramRef('Entrevistas Mohana', '12049914'),
    IvooxProgramRef('Guardianas Ambientales', '12108044'),
    IvooxProgramRef('Memorias con sentido', '12108052'),
    IvooxProgramRef('Letras Púrpura', '13194844'),
    IvooxProgramRef('Clásicos del acordeón', '13193616'),
    IvooxProgramRef('FELIBAR: Puerto de letras', '13129707'),
    IvooxProgramRef('Programas Especiales', '12304631'),
    IvooxProgramRef('Mujeres y melodías del Magdalena Medio', '13105193'),
    IvooxProgramRef('Alma de campeonas', '12592055'),
    IvooxProgramRef('Dignidad y Región', '12366029'),
    IvooxProgramRef('La Marcha', '12546730'),
    IvooxProgramRef('Mujeres emprendedoras', '12470453'),
    IvooxProgramRef('Onda Femenina', '12179708'),
    IvooxProgramRef('Corpemag al Aire', '12552549'),
    IvooxProgramRef('Géneros en movimiento', '12481449'),
    IvooxProgramRef('Café BCA', '12398801'),
    IvooxProgramRef('ART', '12473106'),
    IvooxProgramRef('Magazín APB', '11994140'),
    IvooxProgramRef('+ Mujer + Deporte', '12429091'),
    IvooxProgramRef('La verdad al derecho', '12381179'),
    IvooxProgramRef('Pasa la voz', '12326546'),
    IvooxProgramRef('Zona Purpura', '12115273'),
    IvooxProgramRef(
      'Zona púrpura: Espacios seguros para mujeres de BCA',
      '12330640',
    ),
    IvooxProgramRef('La Hora del Cuento Radial', '12115282'),
  ];
}
