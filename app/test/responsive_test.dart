import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mohana/config/theme.dart';
import 'package:mohana/models/news_article.dart';
import 'package:mohana/models/podcast_episode.dart';
import 'package:mohana/models/podcast_item.dart';
import 'package:mohana/models/premium_audio.dart';
import 'package:mohana/screens/about_screen.dart';
import 'package:mohana/screens/article_detail_screen.dart';
import 'package:mohana/screens/episode_player_screen.dart';
import 'package:mohana/screens/podcast_detail_screen.dart';
import 'package:mohana/screens/radio_screen.dart';
import 'package:mohana/widgets/article_list_card.dart';
import 'package:mohana/widgets/audio_player_bar.dart';
import 'package:mohana/widgets/featured_article_card.dart';
import 'package:mohana/widgets/ivoox_section.dart';
import 'package:mohana/widgets/load_notice.dart';
import 'package:mohana/widgets/mohana_app_bar.dart';
import 'package:mohana/widgets/mohana_bottom_nav.dart';
import 'package:mohana/widgets/on_air_card.dart';
import 'package:mohana/widgets/podcast_card.dart';
import 'package:mohana/widgets/premium_list_card.dart';

/// La app se probó siempre en el mismo teléfono. En otro, el reproductor se
/// veía roto: no era un detalle de estilo, era que las medidas fijas no daban
/// de sí. Este archivo monta cada pieza en un abanico de pantallas y de
/// tamaños de letra y falla si algo se desborda.
///
/// Un desbordamiento en Flutter no rompe la app: pinta las rayas amarillas y
/// avisa por `FlutterError`. En una prueba ese aviso llega a
/// [WidgetTester.takeException], así que basta con exigir que no haya ninguno.
void main() {
  // Las tarjetas del feed pintan la fecha con `intl`, que sin esto lanza.
  setUpAll(() => initializeDateFormatting('es'));

  // Pantallas reales, no números redondos: la pequeña es el gama baja que
  // todavía se usa en Barranca, la apaisada es el mismo teléfono girado.
  const pantallas = <String, Size>{
    'pequeña 320×568': Size(320, 568),
    'gama baja 360×640': Size(360, 640),
    'moderna 412×915': Size(412, 915),
    'tableta 600×960': Size(600, 960),
    'apaisada 740×360': Size(740, 360),
  };

  // 1.0 es el ajuste de fábrica; 1.3 es el que mucha gente pone sin pensar que
  // es "accesibilidad"; 2.0 es el máximo que ofrece Android.
  const escalas = <double>[1.0, 1.3, 2.0];

  final articulo = NewsArticle(
    id: 'a1',
    title: 'Mujeres del Magdalena Medio exigen garantías para la vida y la paz',
    summary:
        'Organizaciones de mujeres de Barrancabermeja se reunieron para exigir '
        'garantías de seguridad y participación en la implementación.',
    body: 'Cuerpo del artículo.',
    imageUrl: '',
    category: 'Impacto Social',
    author: 'Organización Femenina Popular',
    publishedAt: DateTime(2026, 3, 14),
  );

  const programa = PodcastItem(
    id: '12112848',
    title: 'Mujeres y melodías del Magdalena Medio',
    description: 'Un recorrido por la música que acompaña la resistencia.',
    body: '',
    imageUrl: '',
    episodes: '740',
  );

  // Sin identificador numérico no hay feed de iVoox que descargar: la pantalla
  // del programa se pinta con lo que se le pasa y la prueba no sale a la red.
  final conEpisodios = PodcastItem(
    id: 'sin-feed',
    title: programa.title,
    description: programa.description,
    body: '',
    imageUrl: '',
    episodeList: List.generate(
      6,
      (i) => PodcastEpisode(
        title: 'Episodio ${i + 1}: las mujeres que sostienen el río',
        audioUrl: '',
        date: DateTime(2026, 3, 14 - i),
        description: 'Conversación con lideresas del Magdalena Medio.',
        duration: '48 min',
      ),
    ),
  );

  final premium = PremiumAudio(
    id: 'p1',
    title: 'Las voces que el río no se llevó: memoria de las mujeres de Barranca',
    description:
        'Un relato sonoro de media hora sobre la resistencia de las mujeres '
        'del Magdalena Medio, grabado en el patio de la OFP.',
    audioUrl: 'https://ejemplo.invalid/audio.mp3',
    duration: '32 min',
    publishedAt: DateTime(2026, 3, 14),
  );

  // La misma ficha con el archivo sin publicar. El aviso que ocupa el hueco de
  // la duración es más largo que "32 min", y es justo donde se aprieta la fila
  // de arriba con la letra ampliada.
  final premiumSinAudio = PremiumAudio(
    id: 'p2',
    title: premium.title,
    description: premium.description,
    duration: premium.duration,
    publishedAt: premium.publishedAt,
  );

  /// Monta [child] en una pantalla concreta y con un tamaño de letra concreto.
  ///
  /// El [MediaQuery] va dentro del [MaterialApp] (en su `builder`): puesto por
  /// fuera, el propio `MaterialApp` lo reconstruye a partir de la vista y la
  /// escala de letra no llegaría.
  Future<void> montar(
    WidgetTester tester,
    Widget child, {
    required Size pantalla,
    required double escala,
    bool enScaffold = true,
  }) async {
    tester.view.physicalSize = pantalla;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: MohanaTheme.light,
        debugShowCheckedModeBanner: false,
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(escala)),
          child: widget!,
        ),
        // Las piezas sueltas van dentro de un scroll, que es donde viven en
        // la app: en un `Scaffold` a secas quedarían acotadas al alto de la
        // pantalla y se contaría como desbordamiento lo que en realidad es
        // contenido que se desplaza.
        home: enScaffold
            ? Scaffold(body: SingleChildScrollView(child: child))
            : child,
      ),
    );
    // Sin pumpAndSettle: el visualizador de audio y el shimmer animan en bucle
    // y la prueba no terminaría nunca.
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Recorre el abanico completo de pantallas y escalas.
  void enTodasLasPantallas(
    String descripcion,
    Widget Function() construir, {
    bool enScaffold = true,
  }) {
    for (final entrada in pantallas.entries) {
      for (final escala in escalas) {
        testWidgets('$descripcion — ${entrada.key}, letra ×$escala', (
          tester,
        ) async {
          await montar(
            tester,
            construir(),
            pantalla: entrada.value,
            escala: escala,
            enScaffold: enScaffold,
          );

          expect(
            tester.takeException(),
            isNull,
            reason:
                'se desbordó en ${entrada.key} con la letra al ×$escala',
          );
        });
      }
    }
  }

  // Las dos pantallas que el usuario vio rotas.
  enTodasLasPantallas(
    'el reproductor del directo',
    () => const RadioScreen(),
    enScaffold: false,
  );

  enTodasLasPantallas(
    'el reproductor de episodios',
    () => const EpisodePlayerScreen(),
    enScaffold: false,
  );

  // El armazón que acompaña a todas las secciones.
  enTodasLasPantallas('la barra del reproductor', () => const AudioPlayerBar());

  enTodasLasPantallas(
    'la navegación inferior',
    () => MohanaBottomNav(current: MohanaTab.inicio, onSelect: (_) {}),
  );

  // Con la quinta pestaña la barra pasa a ser la pieza más justa de ancho: en
  // 320 px cada pestaña se queda en 52 px y la píldora de la seleccionada
  // pedía 56. Se registra con una del grupo de la derecha para que la píldora
  // caiga en el lado que no se había probado.
  enTodasLasPantallas(
    'la navegación inferior con la pestaña exclusiva',
    () => MohanaBottomNav(current: MohanaTab.premium, onSelect: (_) {}),
  );

  enTodasLasPantallas('la tarjeta del directo', () => const OnAirCard());

  // Las tarjetas del feed.
  enTodasLasPantallas(
    'la tarjeta destacada',
    () => FeaturedArticleCard(article: articulo),
  );

  enTodasLasPantallas(
    'la tarjeta de artículo',
    () => ArticleListCard(article: articulo),
  );

  enTodasLasPantallas(
    'la tarjeta de podcast',
    () => const PodcastCard(podcast: programa),
  );

  enTodasLasPantallas(
    'la tarjeta de contenido exclusivo',
    () => PremiumListCard(item: premium),
  );

  enTodasLasPantallas(
    'la tarjeta de contenido exclusivo sin audio',
    () => PremiumListCard(item: premiumSinAudio),
  );

  // El resto de superficies con texto largo.
  enTodasLasPantallas(
    'el artículo abierto',
    () => ArticleDetailScreen(article: articulo),
    enScaffold: false,
  );

  enTodasLasPantallas('la sección Nosotras', () => const AboutScreen(),
      enScaffold: false);

  enTodasLasPantallas(
    'la cabecera con los dos logos',
    () => const Scaffold(appBar: MohanaAppBar(), body: SizedBox.shrink()),
    enScaffold: false,
  );

  enTodasLasPantallas(
    'la pantalla de un programa',
    () => PodcastDetailScreen(program: conEpisodios),
    enScaffold: false,
  );

  enTodasLasPantallas(
    'la fila de podcasts del home',
    () => IvooxSection(podcasts: [programa, programa, programa]),
  );

  enTodasLasPantallas(
    'el aviso de contenido no cargado',
    () => LoadNotice(
      message: 'No se pudieron cargar 3 programas',
      detail: 'Mujeres y melodías del Magdalena Medio, Voces de la OFP, '
          'La hora del cuento radial',
      onRetry: () {},
    ),
  );
}
