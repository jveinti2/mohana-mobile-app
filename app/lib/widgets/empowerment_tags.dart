import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class EmpowermentTags extends StatefulWidget {
  final List<String> initialTags;
  final ValueChanged<List<String>>? onChanged;

  const EmpowermentTags({
    super.key,
    this.initialTags = const ['#Mujeres', '#Cultura'],
    this.onChanged,
  });

  @override
  State<EmpowermentTags> createState() => _EmpowermentTagsState();
}

class _EmpowermentTagsState extends State<EmpowermentTags> {
  late List<String> _tags;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Nueva Etiqueta',
          style: GoogleFonts.breeSerif(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: '#NuevaEtiqueta',
          ),
          autofocus: true,
          onSubmitted: (_) => _confirmAdd(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: _confirmAdd,
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _confirmAdd() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _tags.add(text.startsWith('#') ? text : '#$text');
      });
      widget.onChanged?.call(_tags);
    }
    _controller.clear();
    Navigator.pop(context);
  }

  void _removeTag(int index) {
    setState(() => _tags.removeAt(index));
    widget.onChanged?.call(_tags);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: MohanaSpacing.sm,
      runSpacing: MohanaSpacing.sm,
      children: [
        ..._tags.asMap().entries.map((entry) => Chip(
              label: Text(entry.value),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => _removeTag(entry.key),
              deleteIconColor: MohanaColors.onPrimary,
              backgroundColor: MohanaColors.primary,
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MohanaColors.onPrimary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: MohanaRadius.smAll,
                side: BorderSide.none,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )),
        ActionChip(
          label: Text(
            '+ Agregar',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MohanaColors.onSurfaceVariant,
            ),
          ),
          onPressed: _addTag,
          backgroundColor: MohanaColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: MohanaRadius.smAll,
            side: const BorderSide(color: MohanaColors.outlineVariant),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}
