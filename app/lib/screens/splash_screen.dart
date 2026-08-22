import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../main.dart';

/// Splash "Al aire" — el logo de La Mohana entra como héroe sobre ondas de
/// radio que pulsan (eco del ícono de ondas del logo + metáfora de transmisión).
/// Fondo claro cálido para que los logos respiren sin cards, con OFP como
/// firma institucional secundaria al pie.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// Bucle continuo: ondas de radio + brillo de la barra de sintonía.
  late final AnimationController _pulse;

  /// Entrada escalonada de los elementos (una sola pasada).
  late final AnimationController _intro;

  /// Llenado de la barra de "sintonizando"; al completar, navega.
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..forward();

    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _navigateToApp();
      })
      ..forward();
  }

  void _navigateToApp() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const AppShell(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 550),
      ),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    _intro.dispose();
    _progress.dispose();
    super.dispose();
  }

  // ─── Helpers de animación escalonada ───────────────────────────

  double _stagger(double start, double end, {Curve curve = Curves.easeOutCubic}) {
    final t = ((_intro.value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ringsSize = (size.width * 0.92).clamp(0.0, 380.0);
    final logoWidth = (size.width * 0.62).clamp(0.0, 250.0);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: MohanaGradients.backgroundSubtle,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Héroe centrado: ondas + wordmark + tagline ──
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: ringsSize,
                    height: ringsSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ondas de radio pulsando (bucle)
                        RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (_, _) => CustomPaint(
                              size: Size.square(ringsSize),
                              painter: _BroadcastRingsPainter(_pulse.value),
                            ),
                          ),
                        ),
                        // Wordmark héroe con entrada (escala + overshoot + fade)
                        AnimatedBuilder(
                          animation: _intro,
                          builder: (_, child) {
                            final appear = _stagger(0.0, 0.55,
                                curve: Curves.easeOutBack);
                            final fade = _stagger(0.0, 0.45);
                            return Opacity(
                              opacity: fade,
                              child: Transform.scale(
                                scale: lerpDouble(0.82, 1.0, appear)!,
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            'assets/images/logo_emisora.png',
                            width: logoWidth,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MohanaSpacing.lg),
                  // Tagline (slide-up + fade, escalonado)
                  AnimatedBuilder(
                    animation: _intro,
                    builder: (_, _) {
                      final t = _stagger(0.32, 0.66);
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 14),
                          child: Text(
                            'ORGULLOSAMENTE COMUNITARIA',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.4,
                              color: MohanaColors.primary600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Pie: barra de sintonía + firma OFP ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: AnimatedBuilder(
                  animation: _intro,
                  builder: (_, _) {
                    final t = _stagger(0.5, 0.9);
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * 18),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: MohanaSpacing.xxl,
                            left: MohanaSpacing.xxl,
                            right: MohanaSpacing.xxl,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _TuningBar(progress: _progress),
                              const SizedBox(height: MohanaSpacing.md),
                              Text(
                                'Sintonizando · 91.2 FM',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.8,
                                  color: MohanaColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: MohanaSpacing.xxl),
                              Text(
                                'UNA INICIATIVA DE',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.8,
                                  color: MohanaColors.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: MohanaSpacing.sm),
                              Image.asset(
                                'assets/images/logo_ofp.png',
                                height: 34,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra delgada de "sintonía" que se llena con el degradado de marca.
class _TuningBar extends StatelessWidget {
  final Animation<double> progress;
  const _TuningBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MohanaRadius.pill),
        child: Stack(
          children: [
            Container(
              height: 4,
              color: MohanaColors.primary100.withValues(alpha: 0.6),
            ),
            AnimatedBuilder(
              animation: progress,
              builder: (_, _) => FractionallySizedBox(
                widthFactor: Curves.easeInOut.transform(progress.value),
                child: Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        MohanaColors.primary,
                        MohanaColors.secondary,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinta ondas concéntricas que crecen y se desvanecen, en bucle.
/// Cada onda usa el degradado de marca (morado → naranja → morado oscuro).
class _BroadcastRingsPainter extends CustomPainter {
  final double t; // 0..1 en bucle
  static const int _ringCount = 4;

  _BroadcastRingsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minR = size.width * 0.18;
    final maxR = size.width * 0.5;

    for (var i = 0; i < _ringCount; i++) {
      final phase = (t + i / _ringCount) % 1.0;
      final radius = lerpDouble(minR, maxR, phase)!;
      // Aparece, se mantiene, y se desvanece al expandirse.
      final opacity = (1.0 - phase) * 0.22;
      if (opacity <= 0.001) continue;

      final rect = Rect.fromCircle(center: center, radius: radius);
      final shader = SweepGradient(
        startAngle: 0,
        endAngle: 6.2832,
        colors: [
          MohanaColors.primary.withValues(alpha: opacity),
          MohanaColors.secondary.withValues(alpha: opacity),
          MohanaColors.tertiary.withValues(alpha: opacity),
          MohanaColors.primary.withValues(alpha: opacity),
        ],
      ).createShader(rect);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = shader;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BroadcastRingsPainter old) => old.t != t;
}
