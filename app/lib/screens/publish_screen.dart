import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../widgets/mohana_app_bar.dart';
import '../widgets/empowerment_tags.dart';
import '../widgets/image_upload_area.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _urlController = TextEditingController();
  List<String> _tags = ['#Mujeres', '#Cultura'];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _handlePublish() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Nota publicada exitosamente',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: MohanaColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MohanaAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: MohanaSpacing.screenH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: MohanaSpacing.lg),

            // Title
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Crear ',
                    style: GoogleFonts.breeSerif(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: MohanaColors.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: 'Nueva Nota',
                    style: GoogleFonts.breeSerif(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: MohanaColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MohanaSpacing.sm),
            Text(
              'Publica contenido relevante para la comunidad de La Mohana.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: MohanaColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const SizedBox(height: MohanaSpacing.sectionGap),

            // Title field
            _FormLabel('TÍTULO DE LA NOTA'),
            const SizedBox(height: MohanaSpacing.sm),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Escribe un título impactante...',
              ),
            ),

            const SizedBox(height: MohanaSpacing.xl),

            // Image upload
            _FormLabel('IMAGEN DESTACADA'),
            const SizedBox(height: MohanaSpacing.sm),
            ImageUploadArea(onTap: () {}),

            const SizedBox(height: MohanaSpacing.xl),

            // Body field
            _FormLabel('CUERPO DE LA NOTA'),
            const SizedBox(height: MohanaSpacing.sm),
            TextField(
              controller: _bodyController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Relata la historia aquí...',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: MohanaSpacing.xl),

            // Tags
            _FormLabel('ETIQUETAS DE EMPODERAMIENTO'),
            const SizedBox(height: MohanaSpacing.sm),
            EmpowermentTags(
              initialTags: _tags,
              onChanged: (tags) => _tags = tags,
            ),

            const SizedBox(height: MohanaSpacing.xl),

            // URL field
            _FormLabel('ENLACE DE REFERENCIA'),
            const SizedBox(height: MohanaSpacing.sm),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
              ),
            ),

            const SizedBox(height: MohanaSpacing.xxl),

            // Publish button
            MohanaTheme.gradientButton(
              onPressed: _handlePublish,
              label: 'PUBLICAR AHORA',
              icon: Icons.send,
            ),

            // Bottom clearance
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;

  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: MohanaColors.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}
