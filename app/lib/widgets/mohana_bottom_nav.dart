import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';

/// Secciones principales de la app, en el orden en que se muestran.
enum MohanaTab {
  inicio(Icons.home_rounded, Icons.home_outlined, 'Inicio'),
  podcasts(Icons.podcasts_rounded, Icons.podcasts_outlined, 'Podcasts'),
  posts(Icons.article_rounded, Icons.article_outlined, 'Posts'),
  nosotras(Icons.diversity_1_rounded, Icons.diversity_1_outlined, 'Nosotras');

  final IconData activeIcon;
  final IconData icon;
  final String label;

  const MohanaTab(this.activeIcon, this.icon, this.label);
}

/// Pestaña activa de la app, para poder cambiarla desde cualquier pantalla
/// (por ejemplo, el "Ver todos" de la sección de podcasts del home).
class AppTabs {
  AppTabs._();

  static final ValueNotifier<MohanaTab> current = ValueNotifier(
    MohanaTab.inicio,
  );

  static void go(MohanaTab tab) => current.value = tab;
}

/// Navegación inferior de la app. Va debajo del mini reproductor, así que se
/// mantiene baja y sin relieve: el peso visual lo lleva el contenido.
class MohanaBottomNav extends StatelessWidget {
  final MohanaTab current;
  final ValueChanged<MohanaTab> onSelect;

  const MohanaBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MohanaColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: MohanaColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          for (final tab in MohanaTab.values)
            Expanded(
              child: _NavItem(
                tab: tab,
                selected: tab == current,
                onTap: () => onSelect(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final MohanaTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? MohanaColors.primary
        : MohanaColors.onSurfaceVariant;

    return InkResponse(
      onTap: onTap,
      radius: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MohanaSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? tab.activeIcon : tab.icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
