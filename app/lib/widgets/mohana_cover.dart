import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Imagen de un contenido (programa, episodio o artículo) con respaldo de
/// marca.
///
/// Es el único sitio donde se decide qué se ve cuando falta la imagen: da
/// igual la sección o de dónde venga el contenido, si no hay carátula —o si la
/// que hay no se puede descargar— se pinta el logo de la emisora sobre el lila
/// de marca, nunca un hueco vacío.
class MohanaCover extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Radio de las esquinas. Sin valor, la imagen va sin recortar.
  final BorderRadius? borderRadius;

  const MohanaCover({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  /// Portada cuadrada de lado [size].
  const MohanaCover.square({
    super.key,
    required this.url,
    required double size,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : width = size,
       height = size;

  @override
  Widget build(BuildContext context) {
    final image = url.isEmpty
        ? const MohanaCoverFallback()
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, _) => const MohanaCoverFallback(),
            errorWidget: (_, _, _) => const MohanaCoverFallback(),
          );

    final sized = (width != null || height != null)
        ? SizedBox(width: width, height: height, child: image)
        : image;

    return borderRadius == null
        ? sized
        : ClipRRect(borderRadius: borderRadius!, child: sized);
  }
}

/// Respaldo de marca: el logo de la emisora sobre el lila del fondo tonal.
///
/// Se usa tanto mientras carga la imagen como cuando no hay ninguna, así que
/// nunca aparece un rectángulo vacío ni un icono suelto.
class MohanaCoverFallback extends StatelessWidget {
  const MohanaCoverFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // El logo ocupa la mayor parte del espacio, con aire alrededor para
        // que respire igual en una miniatura de 36 px que en una portada de 200.
        final side = constraints.hasBoundedWidth && constraints.hasBoundedHeight
            ? (constraints.maxWidth < constraints.maxHeight
                  ? constraints.maxWidth
                  : constraints.maxHeight)
            : 96.0;

        return Container(
          width: constraints.hasBoundedWidth ? constraints.maxWidth : null,
          height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [MohanaColors.tonalMid, MohanaColors.tonalTop],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.all(side * 0.12),
          child: Image.asset(
            'assets/images/logo_emisora.png',
            fit: BoxFit.contain,
            // Las miniaturas no necesitan decodificar el asset completo.
            cacheWidth: side < 200 ? 320 : null,
          ),
        );
      },
    );
  }
}
