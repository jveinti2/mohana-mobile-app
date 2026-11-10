import '../models/premium_audio.dart';

/// Audios de muestra para poder probar la sección premium **antes** de que
/// exista el modelo `ContenidoPremium` en Hygraph.
///
/// `PremiumService` solo recurre a esto cuando la consulta se rechaza porque el
/// modelo todavía no está creado (o no tiene permiso de lectura pública). En
/// cuanto haya una entrada publicada en el panel, esto deja de verse: no hay
/// ningún camino que lo mezcle con contenido real.
///
/// **Cómo borrarlo** cuando la emisora ya publique lo suyo: elimina este
/// archivo y, en `premium_service.dart`, el import y los tres `return
/// demoPremium` — que pasan a devolver `const []`. La pantalla ya sabe enseñar
/// "Todavía no hay contenido exclusivo". Se deja esta nota porque
/// `data/mock_news.dart` llegó para lo mismo y lleva meses siendo código muerto
/// que nadie referencia.
///
/// Las dos entradas son a propósito: con una sola no se puede comprobar que el
/// anterior/siguiente del reproductor recorre la lista premium.
final List<PremiumAudio> demoPremium = [
  // Un audio largo y real (de los que publica la emisora), para poder probar
  // adelantar, la notificación en segundo plano y que se retome donde se dejó
  // — ResumeStore ignora a propósito lo que dure menos de 30 s.
  PremiumAudio(
    id: 'demo-premium-1',
    title: 'Muestra: así se verá un audio exclusivo',
    description:
        'Contenido de prueba mientras no haya nada publicado en el panel. '
        'Sirve para comprobar que suena, que se puede adelantar y que sigue '
        'en segundo plano.',
    audioUrl: 'https://www.ivoox.com/episodio-202-2026_mf_183032288_feed_1.mp3',
    duration: '1 h',
    publishedAt: DateTime(2026, 11, 1),
  ),
  // Y uno corto, para comprobar de un tirón el paso al siguiente de la cola.
  PremiumAudio(
    id: 'demo-premium-2',
    title: 'Muestra corta: para probar el paso al siguiente',
    description:
        'Dura unos segundos, así que es el rápido para ver que al terminar '
        'pasa al siguiente de la lista.',
    audioUrl: 'https://archive.org/download/testmp3testfile/mpthreetest.mp3',
    duration: '27 s',
    publishedAt: DateTime(2026, 10, 31),
  ),
];
