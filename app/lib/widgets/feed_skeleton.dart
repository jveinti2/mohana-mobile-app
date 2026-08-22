import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Esqueleto del feed con efecto shimmer, mostrado mientras carga el contenido
/// desde Drive. Reemplaza el spinner genérico por una previsualización de la
/// estructura real — sensación de carga más rápida y pulida.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: MohanaSpacing.base),
        children: [
          // Artículo destacado
          const _Box(height: 280, radius: MohanaRadius.lg, marginH: true),
          const SizedBox(height: MohanaSpacing.xl),
          // Lista de artículos
          for (var i = 0; i < 3; i++) ...[
            const _SkeletonRow(),
            const SizedBox(height: MohanaSpacing.base),
          ],
          const SizedBox(height: MohanaSpacing.base),
          // Encabezado de podcasts
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
            child: _Box(width: 180, height: 20, radius: MohanaRadius.sm),
          ),
          const SizedBox(height: MohanaSpacing.base),
          // Cards de podcast (horizontal)
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: MohanaSpacing.screenH,
              ),
              children: const [
                _Box(width: 140, height: 150, radius: MohanaRadius.lg),
                SizedBox(width: MohanaSpacing.md),
                _Box(width: 140, height: 150, radius: MohanaRadius.lg),
                SizedBox(width: MohanaSpacing.md),
                _Box(width: 140, height: 150, radius: MohanaRadius.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Esqueleto de la fila horizontal de podcasts. Se usa cuando el feed ya se
/// pintó pero el catálogo de iVoox todavía viene en camino: el resto de la
/// pantalla no espera por él.
class PodcastRowSkeleton extends StatelessWidget {
  final double height;
  final double cardWidth;
  final int count;

  const PodcastRowSkeleton({
    super.key,
    this.height = 150,
    this.cardWidth = 140,
    this.count = 3,
  });

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: MohanaSpacing.screenH,
          ),
          itemCount: count,
          separatorBuilder: (_, _) => const SizedBox(width: MohanaSpacing.md),
          itemBuilder: (_, _) =>
              _Box(width: cardWidth, height: height, radius: MohanaRadius.lg),
        ),
      ),
    );
  }
}

/// Esqueleto de una lista de episodios (detalle de programa).
class EpisodeListSkeleton extends StatelessWidget {
  final int count;

  const EpisodeListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            const _SkeletonRow(),
            const SizedBox(height: MohanaSpacing.base),
          ],
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Box(width: 100, height: 100, radius: MohanaRadius.md),
          const SizedBox(width: MohanaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Box(width: 90, height: 11, radius: MohanaRadius.xs),
                SizedBox(height: MohanaSpacing.sm),
                _Box(height: 14, radius: MohanaRadius.xs),
                SizedBox(height: MohanaSpacing.xs),
                _Box(height: 14, radius: MohanaRadius.xs),
                SizedBox(height: MohanaSpacing.sm),
                _Box(width: 110, height: 11, radius: MohanaRadius.xs),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloque sólido del esqueleto. El color es recoloreado por el shimmer,
/// así que solo importa su forma.
class _Box extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final bool marginH;

  const _Box({
    this.width,
    required this.height,
    required this.radius,
    this.marginH = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      margin: marginH
          ? const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: MohanaColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Aplica una banda de luz que barre el subárbol en bucle.
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              MohanaColors.surfaceContainerHigh,
              MohanaColors.surfaceContainerLow,
              MohanaColors.surfaceContainerHigh,
            ],
            stops: const [0.35, 0.5, 0.65],
            transform: _SlideGradient(_c.value),
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Desplaza el degradado del shimmer de izquierda a derecha.
class _SlideGradient extends GradientTransform {
  final double slide;
  const _SlideGradient(this.slide);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slide * 2 - 1), 0, 0);
  }
}
