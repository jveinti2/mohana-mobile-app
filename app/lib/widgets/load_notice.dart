import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';

/// Aviso discreto para el contenido que no se pudo cargar, con acción de
/// reintento. Sustituye a los `catch` mudos: si un programa de iVoox no llega,
/// se dice y se ofrece recuperarlo sin recargar todo lo demás.
class LoadNotice extends StatelessWidget {
  final String message;

  /// Detalle opcional (por ejemplo, los nombres de los programas que fallaron).
  final String? detail;
  final VoidCallback? onRetry;
  final bool busy;

  const LoadNotice({
    super.key,
    required this.message,
    this.detail,
    this.onRetry,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
      child: Container(
        padding: const EdgeInsets.all(MohanaSpacing.md),
        decoration: MohanaDecorations.tonalCard,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 20,
              color: MohanaColors.warning,
            ),
            const SizedBox(width: MohanaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MohanaColors.onSurface,
                    ),
                  ),
                  if (detail != null && detail!.isNotEmpty) ...[
                    const SizedBox(height: MohanaSpacing.xxs),
                    Text(
                      detail!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: MohanaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: MohanaSpacing.sm),
            if (busy)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MohanaColors.primary,
                ),
              )
            else if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MohanaSpacing.sm,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Reintentar',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MohanaColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
