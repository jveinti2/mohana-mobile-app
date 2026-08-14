import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../config/theme.dart';
import '../services/audio_service.dart';
import '../widgets/audio_visualizer.dart';

/// Enlace de la app en Play Store (applicationId com.ofp.lamohanaradio).
const String _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.ofp.lamohanaradio';

Future<void> _shareApp() async {
  await Share.share(
    '📻 Escucha Emisora La Mohana 91.2 FM, la emisora de las mujeres.\n\n'
    'Descarga la app y sintonízanos en vivo:\n$_playStoreUrl',
    subject: 'Emisora La Mohana 91.2 FM',
  );
}

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('La Mohana'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: MohanaColors.onSurface),
            tooltip: 'Compartir app',
            onPressed: _shareApp,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: MohanaGradients.radioPlayer),
        child: ListenableBuilder(
          listenable: AudioService(),
          builder: (context, _) => const SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: MohanaSpacing.xl),
                  _FrequencyCircle(),
                  SizedBox(height: MohanaSpacing.lg),
                  _EnVivoBadge(),
                  SizedBox(height: MohanaSpacing.xl),
                  _StationInfo(),
                  SizedBox(height: MohanaSpacing.xxl),
                  _VisualizerSection(),
                  SizedBox(height: MohanaSpacing.xxl),
                  _PlayerControls(),
                  SizedBox(height: MohanaSpacing.huge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FrequencyCircle extends StatelessWidget {
  const _FrequencyCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MohanaColors.surface,
        border: Border.all(
          color: MohanaColors.outlineVariant.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [MohanaShadows.ambient],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AudioService.frequency.replaceAll(' FM', ''),
            style: GoogleFonts.breeSerif(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: MohanaColors.primary,
              height: 1,
            ),
          ),
          const SizedBox(height: MohanaSpacing.xs),
          Text(
            'FM STEREO',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: MohanaColors.onSurfaceVariant,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnVivoBadge extends StatelessWidget {
  const _EnVivoBadge();

  @override
  Widget build(BuildContext context) {
    return MohanaTheme.liveBadge(fontSize: 12);
  }
}

/// Identidad de la emisora. Al ser transmisión en vivo no conocemos el
/// programa al aire, así que mostramos la marca de la emisora.
class _StationInfo extends StatelessWidget {
  const _StationInfo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
      child: Column(
        children: [
          Text(
            'Emisora La Mohana',
            textAlign: TextAlign.center,
            style: GoogleFonts.breeSerif(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: MohanaColors.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: MohanaSpacing.sm),
          Text(
            'La emisora de las mujeres',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: MohanaColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualizerSection extends StatelessWidget {
  const _VisualizerSection();

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();
    return AudioVisualizer(
      isPlaying: audioService.isPlaying,
      height: 70,
      barCount: 9,
    );
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls();

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();

    return Column(
      children: [
        // Botón principal play/pausa
        GestureDetector(
          onTap: () => audioService.togglePlayPause(),
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: MohanaGradients.brand,
              shape: BoxShape.circle,
              boxShadow: [MohanaShadows.elevated],
            ),
            child: audioService.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Icon(
                    audioService.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
          ),
        ),
        const SizedBox(height: MohanaSpacing.xl),
        // Compartir la app
        GestureDetector(
          onTap: _shareApp,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MohanaSpacing.lg,
              vertical: MohanaSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: MohanaColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(MohanaRadius.pill),
              border: Border.all(
                color: MohanaColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.ios_share,
                    size: 18, color: MohanaColors.primary),
                const SizedBox(width: MohanaSpacing.sm),
                Text(
                  'Compartir app',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MohanaColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
