import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

/// Entrada escalonada: fade + slide-up con retardo según [index].
/// Mismo lenguaje de movimiento que el splash, aplicado al feed.
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;

  /// Si es `false`, el hijo aparece sin animar (p. ej. ítems ya vistos al
  /// volver a hacer scroll, para evitar que re-animen).
  final bool animate;
  final Duration step;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.animate = true,
    this.step = const Duration(milliseconds: 70),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    if (!widget.animate) {
      _c.value = 1.0;
    } else {
      Future.delayed(widget.step * widget.index, () {
        if (mounted) _c.forward();
      });
    }
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
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 24),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Envoltura que reduce ligeramente la escala al presionar — feedback táctil.
class PressableScale extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Eyebrow de sección: acento de marca + etiqueta en mayúsculas.
/// Da estructura editorial al feed.
class SectionEyebrow extends StatelessWidget {
  final String label;
  const SectionEyebrow(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 3,
            decoration: BoxDecoration(
              gradient: MohanaGradients.primaryButton,
              borderRadius: BorderRadius.circular(MohanaRadius.pill),
            ),
          ),
          const SizedBox(width: MohanaSpacing.sm),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: MohanaColors.primary600,
            ),
          ),
        ],
      ),
    );
  }
}
