import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/audio_service.dart';

class AudioPlayerBar extends StatelessWidget {
  final VoidCallback? onTap;

  const AudioPlayerBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();

    return ListenableBuilder(
      listenable: audioService,
      builder: (context, _) {
        return GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: MohanaColors.surfaceContainerLowest
                      .withValues(alpha: 0.92),
                  border: Border(
                    top: BorderSide(
                      color: MohanaColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Mini album art
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: MohanaGradients.brand,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        audioService.isLive
                            ? Icons.radio
                            : Icons.podcasts_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Now playing info
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  audioService.nowPlayingTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: MohanaColors.onSurface,
                                  ),
                                ),
                              ),
                              if (audioService.isPlaying &&
                                  audioService.isLive) ...[
                                const SizedBox(width: 8),
                                MohanaTheme.liveBadge(fontSize: 8),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            audioService.nowPlayingSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: MohanaColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Play/Pause
                    GestureDetector(
                      onTap: () => audioService.togglePlayPause(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: MohanaGradients.brand,
                          shape: BoxShape.circle,
                          boxShadow: [MohanaShadows.ambient],
                        ),
                        child: audioService.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                audioService.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
