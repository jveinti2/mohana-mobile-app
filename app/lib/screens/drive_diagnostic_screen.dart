import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/design_tokens.dart';
import '../config/drive_config.dart';
import '../services/drive_service.dart';

/// Pantalla de diagnóstico visual del CMS de Drive.
///
/// Recorre paso a paso las llamadas que hace `ContentService` y muestra
/// el resultado de cada una con colores (verde/rojo) para detectar dónde falla.
class DriveDiagnosticScreen extends StatefulWidget {
  const DriveDiagnosticScreen({super.key});

  @override
  State<DriveDiagnosticScreen> createState() => _DriveDiagnosticScreenState();
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

class _DriveDiagnosticScreenState extends State<DriveDiagnosticScreen> {
  final List<_DiagnosticStep> _steps = [];
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  void _add(_DiagnosticStep step) {
    if (!mounted) return;
    setState(() => _steps.add(step));
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _steps.clear();
      _running = true;
    });

    // Paso 1: configuración
    if (!DriveConfig.isConfigured) {
      _add(const _DiagnosticStep(
        title: 'Configuración',
        ok: false,
        errorText: 'DriveConfig no está configurado (apiKey o rootFolderId vacíos)',
      ));
      setState(() => _running = false);
      return;
    }
    _add(_DiagnosticStep(
      title: 'Configuración',
      detail: 'API Key: ${_maskKey(DriveConfig.apiKey)}\nRoot: ${DriveConfig.rootFolderId}',
      ok: true,
    ));

    // Paso 2: listar carpetas raíz
    Map<String, String> sectionMap = {};
    try {
      final rootFolders = await DriveService.listFolders(DriveConfig.rootFolderId);
      for (final folder in rootFolders) {
        sectionMap[folder.name.toLowerCase()] = folder.id;
      }
      _add(_DiagnosticStep(
        title: 'Carpetas en mohana_app/',
        detail: rootFolders.isEmpty
            ? '⚠️ Sin carpetas (¿permisos?)'
            : rootFolders.map((f) => '• ${f.name}  →  ${f.id}').join('\n'),
        ok: rootFolders.isNotEmpty,
        errorText: rootFolders.isEmpty
            ? 'La raíz responde pero no devuelve subcarpetas. Verifica que mohana_app esté compartido "Cualquier persona con el enlace".'
            : null,
      ));
    } catch (e) {
      _add(_DiagnosticStep(
        title: 'Carpetas en mohana_app/',
        ok: false,
        errorText: e.toString(),
      ));
      setState(() => _running = false);
      return;
    }

    // Paso 3: chequear cada sección esperada
    final expectedSections = [
      DriveConfig.titularFolder,
      DriveConfig.articulosFolder,
      DriveConfig.podcastsFolder,
      DriveConfig.podcastDestacadoFolder,
    ];

    for (final section in expectedSections) {
      final id = sectionMap[section];
      if (id == null) {
        _add(_DiagnosticStep(
          title: 'Sección: $section',
          ok: false,
          errorText: 'No existe carpeta "$section" en la raíz',
        ));
        continue;
      }
      await _diagnoseSection(section, id);
    }

    setState(() => _running = false);
  }

  Future<void> _diagnoseSection(String name, String folderId) async {
    // Para "articulos" y "podcasts" son contenedores de subcarpetas
    final isContainer = name == DriveConfig.articulosFolder ||
        name == DriveConfig.podcastsFolder;

    if (isContainer) {
      try {
        final subfolders = await DriveService.listFolders(folderId);
        _add(_DiagnosticStep(
          title: '$name/ (contenedor)',
          detail: subfolders.isEmpty
              ? '⚠️ Sin subcarpetas'
              : '${subfolders.length} subcarpeta(s):\n${subfolders.map((f) => '  • ${f.name}').join('\n')}',
          ok: true,
        ));
        for (final sub in subfolders) {
          await _diagnoseLeafFolder('$name/${sub.name}', sub.id);
        }
      } catch (e) {
        _add(_DiagnosticStep(
          title: '$name/ (contenedor)',
          ok: false,
          errorText: e.toString(),
        ));
      }
    } else {
      await _diagnoseLeafFolder(name, folderId);
    }
  }

  Future<void> _diagnoseLeafFolder(String label, String folderId) async {
    try {
      final files = await DriveService.listFiles(folderId);
      final mdFiles = files.where((f) => f.isMarkdown).toList();
      final imgFiles = files.where((f) => f.isImage).toList();
      final otherFiles = files
          .where((f) => !f.isMarkdown && !f.isImage && !f.isFolder)
          .toList();

      final lines = <String>[
        'Total archivos: ${files.length}',
      ];
      for (final f in files) {
        lines.add('  • ${f.name}  [${f.mimeType}]');
      }

      final problems = <String>[];
      if (mdFiles.isEmpty) problems.add('Sin archivo .md');
      if (mdFiles.length > 1) {
        problems.add('Múltiples .md (${mdFiles.length}) — solo se usará uno');
      }
      if (imgFiles.length > 1) {
        problems.add('Múltiples imágenes (${imgFiles.length}) — solo se usará una');
      }
      if (otherFiles.isNotEmpty) {
        problems.add(
            'Archivos no reconocidos: ${otherFiles.map((f) => f.name).join(", ")}');
      }

      _add(_DiagnosticStep(
        title: label,
        detail: lines.join('\n') +
            (problems.isEmpty ? '' : '\n\n⚠️ ${problems.join("\n⚠️ ")}'),
        ok: mdFiles.isNotEmpty,
        errorText: mdFiles.isEmpty ? 'No hay contenido.md en esta carpeta' : null,
      ));

      // Intentar descargar el markdown
      if (mdFiles.isNotEmpty) {
        try {
          final content = await DriveService.downloadText(mdFiles.first.id);
          final preview = content.length > 200
              ? '${content.substring(0, 200)}...'
              : content;
          _add(_DiagnosticStep(
            title: '$label → ${mdFiles.first.name}',
            detail: 'Bytes: ${content.length}\nPreview:\n$preview',
            ok: true,
          ));
        } catch (e) {
          _add(_DiagnosticStep(
            title: '$label → ${mdFiles.first.name}',
            ok: false,
            errorText: e.toString(),
          ));
        }
      }
    } catch (e) {
      _add(_DiagnosticStep(
        title: label,
        ok: false,
        errorText: e.toString(),
      ));
    }
  }

  String _maskKey(String key) {
    if (key.length <= 10) return '***';
    return '${key.substring(0, 6)}...${key.substring(key.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MohanaColors.background,
      appBar: AppBar(
        title: Text(
          'Diagnóstico Drive',
          style: GoogleFonts.epilogue(
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
            onPressed: _running ? null : _runDiagnostic,
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: MohanaRadius.mdAll,
      ),
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
                  style: GoogleFonts.epilogue(
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
              style: GoogleFonts.robotoMono(
                fontSize: 11,
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
