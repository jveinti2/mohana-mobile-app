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
    // Con la letra ampliada, "Reintentar" al lado del mensaje dejaba al aviso
    // sin ancho: el texto se partía en un chorro de líneas y el botón se salía
    // por la derecha. A partir de cierto tamaño la acción baja a su propia
    // línea y el aviso vuelve a caber.
    final apilado = MediaQuery.textScalerOf(context).scale(12) > 16;

    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
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
    );

    final Widget? accion = busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: MohanaColors.primary,
            ),
          )
        : onRetry == null
        ? null
        : TextButton(
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
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: MohanaColors.primary,
              ),
            ),
          );

    const icono = Icon(
      Icons.cloud_off_rounded,
      size: 20,
      color: MohanaColors.warning,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
      child: Container(
        padding: const EdgeInsets.all(MohanaSpacing.md),
        decoration: MohanaDecorations.tonalCard,
        child: apilado
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icono,
                      const SizedBox(width: MohanaSpacing.sm),
                      Expanded(child: texto),
                    ],
                  ),
                  if (accion != null)
                    Align(alignment: Alignment.centerRight, child: accion),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icono,
                  const SizedBox(width: MohanaSpacing.sm),
                  Expanded(child: texto),
                  const SizedBox(width: MohanaSpacing.sm),
                  ?accion,
                ],
              ),
      ),
    );
  }
}
