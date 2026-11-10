import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/design_tokens.dart';
import '../config/hygraph_config.dart';
import '../services/content_service.dart';
import '../services/hygraph_service.dart';

/// Diagnóstico del CMS.
///
/// Sustituye al de Drive, que recorría carpetas paso a paso porque cada
/// artículo eran tres peticiones y podía fallar en cualquiera. Con Hygraph la
/// consulta es una sola: aquí se lanza de verdad y se cuenta lo que vuelve, que
/// es la pregunta que importa cuando alguien dice "publiqué y no sale".
class CmsDiagnosticScreen extends StatefulWidget {
  const CmsDiagnosticScreen({super.key});

  @override
  State<CmsDiagnosticScreen> createState() => _CmsDiagnosticScreenState();
}

class _DiagnosticStep {
  final String title;
  final String? detail;
  final bool ok;
  final String? errorText;

  const _DiagnosticStep({
    required this.title,
    this.detail,
    required this.ok,
    this.errorText,
  });
}

class _CmsDiagnosticScreenState extends State<CmsDiagnosticScreen> {
  final List<_DiagnosticStep> _steps = [];
  bool _running = false;

  static const _query = r'''
query Diagnostico {
  articulos(orderBy: fecha_DESC, first: 100) {
    titulo
    titular
    categoria
    imagen { url }
  }
  podcastsDestacados(first: 5) { titulo url }
  franjas(first: 200) { programa dias horaInicio horaFin }
}
''';

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _add(_DiagnosticStep step) {
    if (!mounted) return;
    setState(() => _steps.add(step));
  }

  Future<void> _run() async {
    setState(() {
      _steps.clear();
      _running = true;
    });

    _add(
      _DiagnosticStep(
        title: HygraphConfig.isConfigured
            ? 'Configuración'
            : 'Configuración incompleta',
        ok: HygraphConfig.isConfigured,
        detail: HygraphConfig.endpoint,
      ),
    );

    if (HygraphConfig.isConfigured) {
      // La caché serviría lo de hace un rato y el diagnóstico mentiría.
      ContentService.invalidate();
      try {
        final data = await HygraphService.query(_query);
        _add(const _DiagnosticStep(title: 'Conexión con el CMS', ok: true));
        _revisarArticulos(data['articulos']);
        _revisarDestacado(data['podcastsDestacados']);
        _revisarParrilla(data['franjas']);
      } on HygraphException catch (e) {
        _add(
          _DiagnosticStep(
            title: 'Conexión con el CMS',
            ok: false,
            errorText: e.toString(),
          ),
        );
      } catch (e) {
        _add(
          _DiagnosticStep(
            title: 'Conexión con el CMS',
            ok: false,
            errorText: '$e',
          ),
        );
      }
    }

    if (mounted) setState(() => _running = false);
  }

  void _revisarArticulos(Object? raw) {
    final articulos = _lista(raw);
    if (articulos.isEmpty) {
      _add(
        const _DiagnosticStep(
          title: 'Artículos',
          ok: false,
          detail: 'No hay ninguno publicado.',
          errorText:
              'Si acabas de escribir uno, revisa que le hayas dado Publish en '
              'el panel. Lo que queda en borrador no llega a la app.',
        ),
      );
      return;
    }

    final titulares = articulos.where((a) => a['titular'] == true).toList();
    final sinImagen = articulos.where((a) => a['imagen'] == null).length;

    _add(
      _DiagnosticStep(
        title: 'Artículos: ${articulos.length}',
        ok: true,
        detail: articulos
            .take(5)
            .map((a) => '· ${a['titulo']}')
            .join('\n'),
      ),
    );

    _add(
      _DiagnosticStep(
        title: titulares.isEmpty
            ? 'Sin titular marcado'
            : 'Titular: ${titulares.first['titulo']}',
        ok: titulares.length == 1,
        detail: titulares.length > 1
            ? 'Hay ${titulares.length} marcados como titular. La app enseña el '
                  'más reciente; los demás salen en la lista normal.'
            : titulares.isEmpty
            ? 'Nadie marcó «Es titular». El inicio enseña la lista sin '
                  'destacado arriba.'
            : null,
      ),
    );

    if (sinImagen > 0) {
      _add(
        _DiagnosticStep(
          title: 'Artículos sin foto: $sinImagen',
          ok: false,
          detail: 'La app pone el logo de la emisora en su lugar, pero una '
              'foto propia se ve mucho mejor.',
        ),
      );
    }
  }

  void _revisarDestacado(Object? raw) {
    final destacados = _lista(raw);
    _add(
      _DiagnosticStep(
        title: destacados.isEmpty
            ? 'Sin podcast destacado'
            : 'Podcast destacado: ${destacados.first['titulo']}',
        ok: destacados.isNotEmpty,
        detail: destacados.length > 1
            ? 'Hay ${destacados.length}. La app enseña el editado más '
                  'recientemente.'
            : null,
      ),
    );
  }

  void _revisarParrilla(Object? raw) {
    final franjas = _lista(raw);
    if (franjas.isEmpty) {
      _add(
        const _DiagnosticStep(
          title: 'Parrilla vacía',
          ok: false,
          detail: 'Sin franjas, el directo enseña el nombre de la emisora en '
              'vez del programa que está sonando.',
        ),
      );
      return;
    }

    // Se cuentan las que la app descarta, que es justo lo que alguien
    // necesita ver cuando "la parrilla está puesta pero no sale nada".
    final utiles = _lista(raw).where((f) {
      final dias = f['dias'];
      return dias is List && dias.isNotEmpty;
    }).length;

    _add(
      _DiagnosticStep(
        title: 'Parrilla: $utiles franjas',
        ok: utiles == franjas.length,
        detail: franjas
            .take(5)
            .map(
              (f) =>
                  '· ${f['programa']}  ${f['horaInicio']}–${f['horaFin']}',
            )
            .join('\n'),
        errorText: utiles < franjas.length
            ? '${franjas.length - utiles} franjas no tienen días marcados y la '
                  'app las ignora.'
            : null,
      ),
    );
  }

  static List<Map<String, dynamic>> _lista(Object? raw) =>
      (raw as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MohanaColors.background,
      appBar: AppBar(
        title: Text(
          'Diagnóstico del CMS',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MohanaColors.onSurface,
          ),
        ),
        backgroundColor: MohanaColors.surface,
        foregroundColor: MohanaColors.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _running ? null : _run,
            tooltip: 'Reintentar',
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(MohanaSpacing.base),
        itemCount: _steps.length + (_running ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: MohanaSpacing.sm),
        itemBuilder: (_, index) {
          if (index >= _steps.length) {
            return const Padding(
              padding: EdgeInsets.all(MohanaSpacing.base),
              child: Center(
                child: CircularProgressIndicator(color: MohanaColors.primary),
              ),
            );
          }
          return _StepCard(step: _steps[index]);
        },
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final _DiagnosticStep step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    final color = step.ok ? MohanaColors.success : MohanaColors.error;
    final bg = step.ok
        ? MohanaColors.success.withValues(alpha: 0.08)
        : MohanaColors.error.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: MohanaRadius.mdAll),
      padding: const EdgeInsets.all(MohanaSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                step.ok ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 18,
              ),
              const SizedBox(width: MohanaSpacing.sm),
              Expanded(
                child: Text(
                  step.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MohanaColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (step.detail != null) ...[
            const SizedBox(height: MohanaSpacing.sm),
            SelectableText(
              step.detail!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: MohanaColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          if (step.errorText != null) ...[
            const SizedBox(height: MohanaSpacing.sm),
            Container(
              padding: const EdgeInsets.all(MohanaSpacing.sm),
              decoration: BoxDecoration(
                color: MohanaColors.surface,
                borderRadius: MohanaRadius.smAll,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SelectableText(
                      step.errorText!,
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        color: MohanaColors.error,
                        height: 1.4,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    color: MohanaColors.onSurfaceVariant,
                    tooltip: 'Copiar',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: step.errorText!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error copiado al portapapeles'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
