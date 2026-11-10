import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohana/config/ivoox_config.dart';
import 'package:mohana/services/ivoox_service.dart';

/// Una entidad HTML sin resolver: `&amp;`, `&#237;`, `&#xE9;`.
final _entidadHtml = RegExp(r'&(#\d+|#x[0-9a-fA-F]+|[a-zA-Z]+);');

/// Estas pruebas hablan con iVoox de verdad: son el contrato con la fuente.
/// Si iVoox cambia el maquetado del listado o el formato del feed, aquí se ve
/// antes que en el dispositivo. Requieren conexión.
void main() {
  // flutter_test instala un HttpOverrides que devuelve 400 a todo; estas
  // pruebas necesitan la red real.
  setUpAll(() => HttpOverrides.global = null);

  test(
    'el catálogo de la emisora trae una página llena de programas',
    () async {
      final page = await IvooxService.fetchCatalogPage(1);

      expect(page.programs.length, IvooxConfig.catalogPageSize);
      expect(page.hasMore, isTrue);

      for (final ref in page.programs) {
        expect(ref.feedId, matches(RegExp(r'^\d+$')));
        expect(ref.name.trim(), isNotEmpty);
        // Los nombres no deben quedar con entidades HTML sin resolver. Un `&`
        // suelto sí es legítimo —la emisora tiene «Notas & Letras»—, así que
        // lo que se busca es la sintaxis de la entidad, no el ampersand.
        expect(
          ref.name,
          isNot(matches(_entidadHtml)),
          reason: 'entidad HTML sin resolver en «${ref.name}»',
        );
        // La carátula se pide al redimensionador y al tamaño que se va a
        // pintar. El original de iVoox es de 1400×1400 y pesa hasta 1,2 MB:
        // bajárselo para una miniatura dejaba la portada en el respaldo de
        // marca durante segundos, que es lo que la emisora reportó como
        // «no sale la portada».
        expect(ref.coverUrl, startsWith(IvooxConfig.coverResizer));
        expect(
          ref.coverUrl,
          contains('w=${IvooxConfig.coverSize}&h=${IvooxConfig.coverSize}'),
        );
      }

      // Programas que no estaban en la lista que traía la app.
      final ids = page.programs.map((r) => r.feedId).toSet();
      expect(ids, contains('12049914')); // Entrevistas Mohana
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'el catálogo completo cubre todos los programas de la emisora',
    () async {
      final catalog = await IvooxService.loadCatalog(forceRefresh: true);

      expect(catalog.isStale, isFalse);
      // 27 programas publicados al escribir esto; la emisora solo suma.
      expect(catalog.programs.length, greaterThanOrEqualTo(27));

      final names = catalog.programs.map((r) => r.name.toLowerCase()).toList();
      for (final expected in [
        'dignidad y región',
        'la marcha',
        'mujeres emprendedoras',
        'café bca',
        'la hora del cuento radial',
      ]) {
        expect(names, contains(expected), reason: 'falta "$expected"');
      }
    },
    timeout: const Timeout(Duration(seconds: 120)),
  );

  test(
    'un feed devuelve todos sus episodios, sin el tope de 30',
    () async {
      // Revista Informativa La Mohana: el feed más largo de la emisora.
      final program = await IvooxService.fetchProgram(
        const IvooxProgramRef('Revista Informativa La Mohana', '12112848'),
        forceRefresh: true,
      );

      expect(program, isNotNull);
      expect(program!.episodeList.length, greaterThan(30));
      expect(program.episodes, program.episodeList.length.toString());
      expect(program.episodesLabel, endsWith('episodios'));

      final latest = program.latestEpisode;
      expect(latest, isNotNull);
      expect(latest!.audioUrl, startsWith('http'));
      // La fecha se usa para ordenar los episodios recientes.
      expect(latest.date, isNotNull);

      // El feed trae las carátulas crudas (`<itunes:image>` apunta al
      // original), así que el redimensionado tiene que aplicarse también
      // aquí: es la misma URL que acaba en la fila del episodio, en el
      // reproductor y en la notificación.
      expect(program.imageUrl, startsWith(IvooxConfig.coverResizer));
      for (final e in program.episodeList) {
        expect(
          e.imageUrl,
          startsWith(IvooxConfig.coverResizer),
          reason: 'carátula sin redimensionar en «${e.title}»',
        );
      }
      // Un solo tamaño en toda la app: así la portada del reproductor ya
      // está en caché desde la cuadrícula y aparece al instante.
      expect(program.imageUrl, program.episodeList.first.imageUrl);

      // Del más reciente al más antiguo: la pantalla del programa abre el
      // primero de la lista y debe ser el último publicado.
      expect(program.episodeList.first.audioUrl, latest.audioUrl);
      final dated = program.episodeList
          .map((e) => e.date)
          .whereType<DateTime>()
          .toList();
      for (var i = 1; i < dated.length; i++) {
        expect(
          dated[i].isAfter(dated[i - 1]),
          isFalse,
          reason: 'los episodios no vienen ordenados por fecha',
        );
      }
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
