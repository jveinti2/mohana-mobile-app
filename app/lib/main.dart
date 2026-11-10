import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'config/theme.dart';
import 'screens/about_screen.dart';
import 'screens/home_feed_screen.dart';
import 'screens/podcasts_library_screen.dart';
import 'screens/posts_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/ivoox_cache.dart';
import 'services/resume_store.dart';
import 'widgets/audio_player_bar.dart';
import 'widgets/mohana_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Servicio en primer plano y notificación de medios. Va antes de tocar
  // [AudioService], porque tiene que estar en pie cuando se crea el
  // reproductor: es lo que mantiene el audio sonando al salir de la app y lo
  // que pinta el control en la barra de notificaciones y en el bloqueo.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ofp.lamohanaradio.audio',
    androidNotificationChannelName: 'Reproducción',
    androidNotificationChannelDescription:
        'Control del directo y de los episodios de podcast',
    androidNotificationIcon: 'drawable/ic_notificacion',
    notificationColor: MohanaColors.primary,
    // La notificación se puede descartar con la reproducción parada; mientras
    // suena, el servicio en primer plano la mantiene fija de todos modos.
    androidNotificationOngoing: false,
    rewindInterval: AudioService.skipBack,
    fastForwardInterval: AudioService.skipForward,
  );
  await initializeDateFormatting('es');
  // Deja la caché lista antes del primer frame: el feed se pinta sin esperar
  // a la red cuando ya se abrió la app alguna vez.
  await IvooxCache.init();
  // Dónde se quedó cada episodio, para poder ofrecer retomarlo sin esperar a
  // que la biblioteca lea el disco.
  await ResumeStore.init();
  await AudioService().init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MohanaApp());
}

class MohanaApp extends StatelessWidget {
  const MohanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (_, themeMode, _) => MaterialApp(
        title: 'La Mohana',
        debugShowCheckedModeBanner: false,
        theme: MohanaTheme.light,
        darkTheme: MohanaTheme.dark,
        themeMode: themeMode,
        home: const SplashScreen(),
      ),
    );
  }
}

/// Contenedor de las secciones principales.
///
/// Mantiene vivas las pestañas ya visitadas (con [IndexedStack]) para que
/// volver a una no la recargue, y apila el mini reproductor sobre la barra de
/// navegación.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MohanaTab>(
      valueListenable: AppTabs.current,
      builder: (context, tab, _) => Scaffold(
        body: IndexedStack(
          index: MohanaTab.values.indexOf(tab),
          // El orden tiene que coincidir con el de declaración de [MohanaTab]:
          // el índice sale de `MohanaTab.values.indexOf(tab)` y la lista no
          // lleva etiquetas, así que colocar una pantalla en el hueco
          // equivocado desplaza todas las pestañas sin que nada falle.
          children: const [
            HomeFeedScreen(),
            PodcastsLibraryScreen(embedded: true),
            PremiumScreen(),
            PostsScreen(),
            AboutScreen(),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // El reproductor decide solo cuál abrir: el del directo o el de
            // episodios, según lo que esté sonando.
            const AudioPlayerBar(),
            SafeArea(
              top: false,
              child: MohanaBottomNav(current: tab, onSelect: AppTabs.go),
            ),
          ],
        ),
      ),
    );
  }
}
