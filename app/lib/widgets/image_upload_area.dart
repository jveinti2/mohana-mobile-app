import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class ImageUploadArea extends StatelessWidget {
  final VoidCallback? onTap;

  const ImageUploadArea({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: MohanaColors.outlineVariant,
          radius: MohanaRadius.lg,
          strokeWidth: 1.5,
          dashWidth: 8,
          dashGap: 5,
        ),
        child: Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: MohanaColors.surfaceContainerLow,
            borderRadius: MohanaRadius.lgAll,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 40,
                color: MohanaColors.primary,
              ),
              const SizedBox(height: MohanaSpacing.sm),
              Text(
                'Toca para subir imagen',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MohanaColors.onSurface,
                ),
              ),
              const SizedBox(height: MohanaSpacing.xxs),
              Text(
                'O arrastra y suelta aquí (JPG, PNG)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: MohanaColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = min(distance + dashWidth, metric.length);
        result.addPath(metric.extractPath(distance, end), Offset.zero);
        distance = end + dashGap;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
