import 'dart:math';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double height;
  final int barCount;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.height = 60,
    this.barCount = 7,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<double> _phases;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _phases = List.generate(
      widget.barCount,
      (_) => _random.nextDouble() * 2 * pi,
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.barCount * 10.0, widget.height),
          painter: _VisualizerPainter(
            progress: _controller.value,
            phases: _phases,
            isPlaying: widget.isPlaying,
            barCount: widget.barCount,
          ),
        );
      },
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final double progress;
  final List<double> phases;
  final bool isPlaying;
  final int barCount;

  _VisualizerPainter({
    required this.progress,
    required this.phases,
    required this.isPlaying,
    required this.barCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 5.0;
    const gap = 4.0;
    final totalWidth = barCount * barWidth + (barCount - 1) * gap;
    final startX = (size.width - totalWidth) / 2;

    final gradient = MohanaGradients.visualizer;
    final shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    final paint = Paint()..shader = shader;

    for (var i = 0; i < barCount; i++) {
      final double heightFraction;
      if (isPlaying) {
        heightFraction =
            0.3 + 0.7 * ((sin(progress * 2 * pi + phases[i]) + 1) / 2);
      } else {
        heightFraction = 0.15 + 0.1 * ((sin(phases[i]) + 1) / 2);
      }

      final barHeight = size.height * heightFraction;
      final x = startX + i * (barWidth + gap);
      final y = (size.height - barHeight) / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_VisualizerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isPlaying != isPlaying;
}
