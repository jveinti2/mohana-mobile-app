import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/theme.dart';
import 'screens/about_screen.dart';
import 'screens/home_feed_screen.dart';
import 'screens/podcasts_library_screen.dart';
import 'screens/posts_screen.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/ivoox_cache.dart';
import 'widgets/audio_player_bar.dart';
import 'widgets/mohana_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  // Deja la caché lista antes del primer frame: el feed se pinta sin esperar
  // a la red cuando ya se abrió la app alguna vez.
  await IvooxCache.init();
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
          children: const [
            HomeFeedScreen(),
            PodcastsLibraryScreen(embedded: true),
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
