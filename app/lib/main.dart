import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/theme.dart';
import 'screens/home_feed_screen.dart';
import 'screens/radio_screen.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'widgets/audio_player_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
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

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  void _openRadio(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RadioScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const HomeFeedScreen(),
      bottomNavigationBar: SafeArea(
        child: AudioPlayerBar(onTap: () => _openRadio(context)),
      ),
    );
  }
}
