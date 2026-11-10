# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es esto

App móvil Flutter de **Emisora La Mohana 91.2 FM** (Organización Femenina Popular, Barrancabermeja): radio en directo, podcasts de iVoox y publicaciones editoriales. Todo el código, los comentarios y la UI están en **español** — mantén ese idioma al escribir comentarios y textos nuevos.

El repo tiene el proyecto Flutter en `app/`; en la raíz solo hay `DESIGN.md` y `documentos/` (material comercial, no código).

## Comandos

Todo se ejecuta desde `app/` (Flutter no está en el PATH de esta sesión; hay que instalarlo o usar el SDK del entorno de desarrollo del usuario).

```bash
cd app
flutter pub get
flutter run                       # dispositivo/emulador conectado
flutter analyze                   # lints (flutter_lints 6)
flutter test                      # suite completa
flutter test test/ivoox_service_test.dart          # un archivo
flutter test --plain-name "parseo del catálogo"    # un test suelto
flutter build apk --release       # firma con android/key.properties (no versionado)
flutter build appbundle --release
```

**No compiles en cada iteración** (petición explícita del usuario, ver `app/.CLAUDE.md`). Usa `flutter analyze` y `flutter test` para validar; deja las compilaciones para cuando de verdad haga falta un artefacto.

Versión y build number viven en `app/pubspec.yaml` (`version: 1.2.2+11`) y se propagan a Android/iOS. `applicationId` = `com.ofp.lamohanaradio`.

## Arquitectura

Sin gestor de estado externo: **singletons + `ChangeNotifier`/`ValueNotifier` + `setState`**. No hay Provider, Riverpod ni Bloc, y no hay rutas con nombre — la navegación es `Navigator.push(MaterialPageRoute(...))` directa.

### Dos fuentes de contenido, independientes

1. **iVoox** (`services/ivoox_service.dart`) — la fuente de los podcasts. El catálogo de programas **no está hardcodeado**: se descubre en runtime raspando la página de la emisora (`IvooxConfig.catalogUrl`, parseo por `<meta itemprop>` de schema.org, más estable que las clases CSS) y los episodios salen del RSS de cada programa. `IvooxConfig.fallbackPrograms` es solo semilla de emergencia para el primer arranque sin red — puede estar desactualizada, no la trates como verdad.
2. **Hygraph como CMS** (`services/hygraph_service.dart` + `content_service.dart`) — titular, artículos y podcast destacado. Endpoint público de solo lectura, sin token: escribir requiere credenciales que no viven en la app. La API es **GraphQL, no REST** — un POST con la consulta en el cuerpo; lo que vuelve sigue siendo JSON. Los modelos (`Articulo`, `PodcastDestacado`, `Franja`) y el endpoint están documentados en `config/hygraph_config.dart`. El panel es <https://app.hygraph.com>, proyecto `mohana-app`.

   Lo que está en borrador no llega a la app: solo lo publicado. Es la causa número uno de «escribí algo y no sale».

La **parrilla** (modelo `Franja`) vive en el mismo Hygraph pero la lee `services/schedule_service.dart` con su propia consulta, a propósito: un fallo suyo no debe arrastrar al feed, y su TTL es de 12 h frente a los 5 min del resto. Es lo que permite al directo decir qué programa está sonando. Las horas se interpretan en hora de Colombia, no en la del teléfono. Sin franjas, todo cae a la identidad de la emisora y nada se rompe.

`dias` **no pudo marcarse como obligatorio** en Hygraph (no admite listas requeridas), así que una franja sin días es un dato posible: `parse()` la descarta en vez de hacerla sonar los siete días.

### Estrategia de carga (el eje del diseño)

Todo el rendimiento de la app se apoya en **stale-while-revalidate en tres niveles**: memoria (`IvooxService._memory`) → disco (`IvooxCache` sobre `shared_preferences`) → red. `IvooxCache.init()` se llama antes del primer frame en `main()` para que el feed pinte sin esperar a la red.

Reglas que conviene no romper al tocar carga de datos:

- **Los feeds se descargan solo cuando hacen falta**, nunca los 27 de golpe al arrancar. El catálogo pinta con `IvooxService.stubFor(ref)` (nombre + carátula, sin episodios) y el feed se lee al abrir el programa o al entrar en la ventana visible de la cuadrícula.
- **Concurrencia acotada** con `pooled()` (`services/task_pool.dart`), no `Future.wait` sobre listas largas: 4 simultáneas en iVoox. El CMS ya no lo necesita — donde Drive pedía una carpeta por artículo, Hygraph lo trae todo en una consulta.
- **El parseo va en un isolate** vía `compute()` — feeds de 700 episodios bloquearían el frame.
- **Los fallos llegan a la UI, no a un `catch` mudo**: `IvooxLoadResult` lleva la lista de `failed` y la UI la pinta con `LoadNotice` + reintento parcial (`mergedWith`). `IvooxCatalog.isStale` avisa cuando lo mostrado sale de caché vencida o de la semilla.
- **TTLs**: catálogo 12 h, feeds 30 min, contenido del CMS 5 min y parrilla 12 h (en memoria). La caché de disco guarda como máximo 50 episodios por programa porque `shared_preferences` se carga entera en memoria.

### Audio

`AudioService` es un singleton `ChangeNotifier` sobre `just_audio` con **un solo reproductor** en dos modos: directo (`isLive`, stream de Zeno.fm) o episodio (con cola de reproducción del programa, velocidad, seek, ±10/30 s). `progressStream` va aparte de `notifyListeners()` a propósito: emite varias veces por segundo y repintar todo sería carísimo. La barra `AudioPlayerBar` decide sola qué pantalla abrir (`RadioScreen` o `EpisodePlayerScreen`) según el modo.

La reproducción en segundo plano no la da `just_audio` por sí sola: va sobre **`just_audio_background`** (y `audio_service` por debajo), que arranca un servicio en primer plano y publica una `MediaSession`. Son la misma pieza para dos cosas que el usuario ve como distintas: el control en la barra de notificaciones y en la pantalla de bloqueo, y que Android no mate el audio a los pocos minutos de salir de la app. Tres piezas tienen que estar juntas o no funciona ninguna:

1. `JustAudioBackground.init()` en `main()` **antes** de tocar `AudioService` — el reproductor tiene que crearse con el servicio ya en pie.
2. El `<service>` y el `<receiver>` de `com.ryanheise.audioservice` declarados en `android/app/src/main/AndroidManifest.xml`; el plugin no los aporta. `MainActivity` hereda de `AudioServiceActivity`, no de `FlutterActivity`.
3. **Toda** fuente de audio lleva su `MediaItem` como `tag` (`_liveSource`, `_episodeSource`): de ahí salen título, emisora y carátula de la notificación. Por eso ya no hay ningún `setUrl` — un `setUrl` sin etiquetar lanza excepción en tiempo de ejecución.

La carátula no puede ser un asset: la notificación solo acepta `file:` o `http:`, así que `_prepareStationArt()` copia `logo_emisora.png` a la caché una vez y el `artUri` del directo apunta ahí (el de un episodio usa la imagen del feed, que ya es una URL). El icono pequeño es `drawable/ic_notificacion`, un glifo de antena monocromo en cinco densidades: el logotipo de la app no sirve, Android enmascara el icono pequeño y un logotipo con texto queda en un borrón blanco. Ese icono está retenido a mano en `android/app/src/main/res/raw/keep.xml`, y hay que dejarlo ahí: se resuelve por nombre en tiempo de ejecución, el shrinker de recursos no ve la referencia y lo borraba del bundle firmado —en depuración la notificación salía perfecta y en la release se quedaba sin icono.

Y el directo **se reconecta solo**. Un stream no "termina": si el reproductor se queda en reposo o da error mientras `_wantsPlayback` sigue en `true`, es que se cortó la red, y `_scheduleLiveReconnect()` vuelve a montar la fuente con esperas crecientes (2 s → 30 s). La distinción entre una pausa del usuario y un corte es justo `_wantsPlayback`: sin ella, reconectaríamos encima de una pausa deliberada. `_ensureSource()` cubre el otro caso raro: el botón de parar de la notificación suelta el decodificador, y sin remontar la fuente el siguiente `play()` no sonaría.

El avance de cada episodio se anota en `services/resume_store.dart` (otra vez `shared_preferences`) para poder retomarlo: cada 10 s mientras suena, y a la fuerza al pausar, al cambiar de pista y al volver al directo. Dos guardas que no hay que quitar: los extremos (menos de 30 s, o a menos de 30 s del final) no se guardan —y borran la marca— para que la lista no se llene de episodios abiertos por error o ya terminados; y `_restoring` silencia la anotación entre abrir un episodio y saltar a su posición, porque los eventos que emite `setUrl` vienen todos en cero y borrarían la marca justo antes de usarla.

Hay tres accesos al directo, con dos comportamientos distintos a propósito: el botón central de `MohanaBottomNav` y la tarjeta `OnAirCard` del home **navegan** a `RadioScreen`; el de `AudioPlayerBar` solo **cambia lo que suena** y deja al usuario donde está, porque vive en pantallas apiladas que no tienen navegación inferior.

### Navegación

`main()` → `SplashScreen` → `AppShell`, que es un `IndexedStack` de cuatro pestañas (`MohanaTab`: Inicio / Podcasts / Posts / Nosotras) para que volver a una pestaña no la recargue. La pestaña activa es global (`AppTabs.current`, un `ValueNotifier`), así cualquier pantalla puede saltar de sección. `AppShell` apila el mini reproductor sobre la barra de navegación.

`ProfileScreen` y `PublishScreen` existen pero no están conectados a ninguna ruta. `CmsDiagnosticScreen` solo es accesible desde el estado de error del home.

## Sistema de diseño

`lib/config/design_tokens.dart` (colores, gradientes, espaciado, radios, sombras, decoraciones) y `lib/config/theme.dart` (`ThemeData`, tipografías vía `google_fonts`, helpers `gradientButton`/`liveBadge`/`categoryTag`) son **la fuente de verdad**. Usa los tokens; no metas colores ni medidas literales en los widgets.

Ojo con dos fuentes de confusión:

- **`DESIGN.md` (raíz) está desalineado con el código.** Describe la paleta como `#6100A4`/`#7B2CBF` y las tipografías como Epilogue/Manrope; el código usa `MohanaColors.primary = #7B2E88` con Bree Serif (display/headline), Montserrat (títulos) y Poppins (cuerpo). Sus *principios* siguen valiendo (nada de bordes de 1px para separar secciones, capas tonales en vez de sombras Material, glassmorphism en elementos flotantes, mucho aire), pero **los valores concretos salen de `design_tokens.dart`**.
- **La skill `frontend-design`** (`app/.claude/skills/`, `app/.agents/skills/`) es una plantilla de terceros vendorizada (`skills-lock.json` → `blogic-cz/blogic-marketplace`). Habla de `docs/design.md`, Inter y azul `#2563eb` — nada de eso aplica a este proyecto. Ignora sus constantes de marca.

Las carátulas de iVoox **siempre** se piden al redimensionador (`IvooxConfig.coverResizer`) y a un único tamaño (`IvooxConfig.coverSize`, 480 px), y eso es deliberado por dos razones. La primera: el feed entrega la imagen cruda en `<itunes:image>` —el original de 1400×1400, hasta 1,2 MB— mientras el listado la trae ya envuelta a 77 px, así que antes la misma imagen llegaba por dos caminos con 100× de diferencia de peso; bajarse el original para pintar una fila de 48 dp es lo que hacía que la portada tardara segundos y que mientras tanto se viera el respaldo de marca (la emisora lo reportó como «no sale la portada»). La segunda: un solo tamaño significa **una sola URL** para la cuadrícula, la fila del episodio, el reproductor y la notificación, de modo que la portada ya está en caché cuando se abre el reproductor. Si alguna vez hacen falta dos tamaños, hay que asumir que se descarga dos veces. `_resizedCover()` desenvuelve antes de volver a envolver, así que es idempotente y no depende de la medida que traiga iVoox —hoy el listado va a 77 px, pero la misma página usa 141 en otros sitios—.

Ojo con un dato de la fuente: todos los episodios de un programa comparten la carátula del canal, y las descripciones de los episodios son en su mayoría solo la fecha (`09 de octubre de 2026`). La descripción se pinta **sin filtrar** en la fila del episodio, por decisión del usuario: que la emisora controle lo que se ve corrigiéndolo en iVoox, no la app escondiéndolo.

`MohanaCover` es el único sitio donde se decide qué se ve cuando falta una imagen (logo de la emisora sobre lila de marca, nunca un hueco). Cualquier portada nueva debe pasar por ahí.

## Tests

`app/test/` cubre lo frágil, no todo: parseo de iVoox con fixtures de HTML/XML, serialización de la caché y los widgets con medidas calculadas. Los tests de widget evitan `pumpAndSettle()` donde hay animaciones en bucle (splash, visualizador) — usa `pump(Duration)`.

`test/responsive_test.dart` es la red de seguridad de las medidas: monta cada pantalla y cada tarjeta en cinco tamaños de pantalla (de 320×568 a una tableta, más apaisado) por tres escalas de letra (×1, ×1.3 y ×2, el máximo de Android) y falla si algo se desborda —Flutter avisa del desbordamiento por `FlutterError`, y en una prueba ese aviso llega a `tester.takeException()`—. Al añadir una pantalla o una tarjeta, añádela también ahí.

Dos detalles del arnés que no son caprichos: el `MediaQuery` va **dentro** del `MaterialApp` (en su `builder`), porque puesto por fuera el propio `MaterialApp` lo reconstruye desde la vista y la escala de letra no llegaría; y las piezas sueltas se montan dentro de un `SingleChildScrollView`, que es donde viven en la app — en un `Scaffold` a secas quedarían acotadas al alto de la pantalla y se contaría como desbordamiento lo que solo es contenido que se desplaza.

**Nada de medidas fijas donde hay texto.** Es de donde salieron casi todos los desbordamientos: un alto en duro que no da de sí cuando el sistema amplía la letra (`FeaturedArticleCard` con `height: 280`, el disco de frecuencia del directo, el alto de la fila de podcasts), o un `Text` sin `Flexible` en un `Row` que empuja a los demás fuera. Cuando el alto depende del texto, se calcula con `MediaQuery.textScalerOf(context)` — `ProgramGridCard.extentFor` es el patrón a copiar.

## Icono de la app

El icono del lanzador es el mismo que el de la ficha de Play Store (`app/docs/icon_512x512.png`): el logotipo de la emisora sobre blanco. Las fuentes están en `app/assets/icon/` y se generan con `flutter_launcher_icons`, configurado al final de `pubspec.yaml`:

```bash
dart run flutter_launcher_icons   # reescribe mipmaps de Android e iconos de iOS
```

`icon.png` es la composición completa (iOS y los Android anteriores al icono adaptativo). `icon_foreground.png` lleva el mismo logotipo pero más recogido, al 55 % del lienzo: en un icono adaptativo el lanzador solo garantiza el 66 % central, y lo que se salga de ahí se recorta. Por eso también va `adaptive_icon_foreground_inset: 0` — el margen ya lo trae la imagen, y el 16 % que mete la herramienta por su cuenta dejaría el logotipo diminuto.

Los ficheros de `assets/icon/` **no** se declaran en `flutter: assets:`: son material de compilación, no se empaquetan.

## Notas

- Flutter web no sirve para probar iVoox: el navegador bloquea las peticiones por CORS. Android/iOS funcionan.
- `HygraphService` fuerza UTF-8 a mano sobre `bodyBytes` en vez de fiarse de la cabecera; si no, las tildes se rompen. Es la misma lección que dejó Drive.
- El endpoint de Hygraph está en claro en `config/hygraph_config.dart`. No es un descuido que arreglar por tu cuenta: es el endpoint de solo lectura y solo sirve lo ya publicado.
- Las imágenes se piden redimensionadas por el CDN de Hygraph (`transformation:` en la propia consulta, anchos en `HygraphConfig`). Pedir el original significaba bajarse los megas que subió quien escribió el artículo.
- `app/examples/` conserva el formato de Drive (markdown con frontmatter). Ya no lo lee nadie: queda como referencia de redacción, no de formato.
- Las claves de firma de Android (`android/key.properties`, `android/keystore/`) están en `.gitignore` y no viven en el repo.
