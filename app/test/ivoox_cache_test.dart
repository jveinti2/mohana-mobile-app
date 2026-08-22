import 'package:flutter_test/flutter_test.dart';
import 'package:mohana/config/ivoox_config.dart';
import 'package:mohana/models/podcast_episode.dart';
import 'package:mohana/models/podcast_item.dart';
import 'package:mohana/services/ivoox_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La caché es lo que permite pintar el feed sin esperar a la red, así que un
/// fallo aquí sería silencioso: estas pruebas comprueban el viaje de ida y
/// vuelta a disco sin tocar iVoox.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('el catálogo sobrevive al viaje a disco', () async {
    const refs = [
      IvooxProgramRef('Dignidad y Región', '12366029', coverUrl: 'http://a/1'),
      IvooxProgramRef('Café BCA', '12398801'),
    ];

    expect(await IvooxCache.isCatalogFresh(), isFalse);

    await IvooxCache.writeCatalog(refs);
    final read = await IvooxCache.readCatalog();

    expect(await IvooxCache.isCatalogFresh(), isTrue);
    expect(read, isNotNull);
    expect(read!.map((r) => r.feedId), ['12366029', '12398801']);
    expect(read.first.name, 'Dignidad y Región');
    expect(read.first.coverUrl, 'http://a/1');
    expect(read.last.coverUrl, isEmpty);
  });

  test('un catálogo vacío no borra el que ya estaba guardado', () async {
    await IvooxCache.writeCatalog(const [
      IvooxProgramRef('La Marcha', '12546730'),
    ]);
    await IvooxCache.writeCatalog(const []);

    final read = await IvooxCache.readCatalog();
    expect(read, hasLength(1));
  });

  test('los episodios se guardan recortados pero con el conteo real', () async {
    final episodes = [
      for (var i = 0; i < 300; i++)
        PodcastEpisode(
          title: 'Episodio $i',
          audioUrl: 'https://audio/$i.mp3',
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          duration: '30 min',
        ),
    ];
    final program = PodcastItem(
      id: '12112848',
      title: 'Revista Informativa La Mohana',
      description: 'Programa informativo',
      body: '',
      imageUrl: 'http://cover',
      episodes: '${episodes.length}',
      episodeList: episodes,
    );

    await IvooxCache.writeProgram(program);
    final read = await IvooxCache.readProgram('12112848');

    expect(read, isNotNull);
    expect(read!.title, program.title);
    // Se guarda solo una ventana reciente para no inflar el almacenamiento...
    expect(read.episodeList.length, lessThan(episodes.length));
    // ...pero el conteo sigue siendo el real, y la pantalla sabe que le falta.
    expect(read.episodesLabel, '300 episodios');
    expect(read.hasAllEpisodes, isFalse);
    expect(read.episodeList.first.audioUrl, 'https://audio/0.mp3');
    expect(read.episodeList.first.duration, '30 min');
    expect(read.latestEpisode, isNotNull);
  });

  test('un programa completo se marca como completo', () async {
    final program = PodcastItem(
      id: '13105193',
      title: 'Mujeres y melodías',
      description: '',
      body: '',
      imageUrl: '',
      episodes: '2',
      episodeList: const [
        PodcastEpisode(title: 'A', audioUrl: 'https://audio/a.mp3'),
        PodcastEpisode(title: 'B', audioUrl: 'https://audio/b.mp3'),
      ],
    );

    await IvooxCache.writeProgram(program);
    final read = await IvooxCache.readProgram('13105193');

    expect(read!.hasAllEpisodes, isTrue);
    expect(read.episodesLabel, '2 episodios');
  });

  test('no devuelve nada para un programa que nunca se guardó', () async {
    expect(await IvooxCache.readProgram('00000000'), isNull);
  });
}
