import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohana/config/ivoox_config.dart';
import 'package:mohana/services/ivoox_service.dart';

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
        // Los nombres no deben quedar con entidades HTML sin resolver.
        expect(ref.name, isNot(contains('&')));
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
