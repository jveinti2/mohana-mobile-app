/// Referencia a un programa de la emisora en iVoox.
class IvooxProgramRef {
  final String name;

  /// ID numérico del feed (la parte después de `_f` en la URL del programa).
  final String feedId;

  const IvooxProgramRef(this.name, this.feedId);
}

/// Configuración de los programas de Emisora La Mohana en iVoox.
///
/// El feed RSS de cada programa se construye con [feedUrl].
/// Estación: https://www.ivoox.com/...emisora-la-mohana_al_32053771_1.html
class IvooxConfig {
  IvooxConfig._();

  /// Construye la URL del feed RSS a partir del [feedId].
  static String feedUrl(String feedId) =>
      'https://feeds.ivoox.com/feed_fg_f${feedId}_filtro_1.xml';

  /// Programas listados en la página de la emisora, en orden editorial.
  static const programs = <IvooxProgramRef>[
    IvooxProgramRef('Revista Informativa La Mohana', '12112848'),
    IvooxProgramRef('Magazín Informativo La Mohana', '12250823'),
    IvooxProgramRef('Comuna Popular', '12108048'),
    IvooxProgramRef('Guardianas Ambientales', '12108044'),
    IvooxProgramRef('Memorias con sentido', '12108052'),
    IvooxProgramRef('Mujeres y melodías del Magdalena Medio', '13105193'),
    IvooxProgramRef('Mujeres emprendedoras', '12470453'),
    IvooxProgramRef('Alma de campeonas', '12592055'),
    IvooxProgramRef('Dignidad y Región', '12366029'),
    IvooxProgramRef('La Marcha', '12546730'),
    IvooxProgramRef('FELIBAR: Puerto de letras', '13129707'),
    IvooxProgramRef('Programas Especiales', '12304631'),
  ];
}
