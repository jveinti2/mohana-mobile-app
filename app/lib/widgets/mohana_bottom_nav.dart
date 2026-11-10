import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../screens/radio_screen.dart';
import '../services/audio_service.dart';

/// Secciones principales de la app, en el orden en que se muestran.
enum MohanaTab {
  inicio(Icons.home_rounded, Icons.home_outlined, 'Inicio'),
  podcasts(Icons.podcasts_rounded, Icons.podcasts_outlined, 'Podcasts'),
  premium(
    Icons.workspace_premium_rounded,
    Icons.workspace_premium_outlined,
    'Exclusivo',
  ),
  posts(Icons.article_rounded, Icons.article_outlined, 'Posts'),
  nosotras(Icons.diversity_1_rounded, Icons.diversity_1_outlined, 'Nosotras');

  final IconData activeIcon;
  final IconData icon;

  /// No se pinta: la barra es solo de iconos. Queda como etiqueta de
  /// accesibilidad y como texto del tooltip al mantener pulsado.
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
///
/// Solo iconos, sin texto. La pestaña activa se distingue por el color y por
/// la píldora lila de fondo, no por una etiqueta.
///
/// En el centro, separado de las pestañas, va el botón del directo: la emisora
/// es lo primero de la app y desde cualquier sección —incluso mientras suena
/// un episodio— tiene que poderse volver a ella de un toque.
class MohanaBottomNav extends StatelessWidget {
  /// Lado del icono de cada pestaña. Vive aquí porque el cálculo del relleno
  /// de la píldora lo necesita y no puede desviarse del que se pinta.
  static const _iconSize = 24.0;

  /// Pestañas que van a la izquierda del botón del directo; el resto van a la
  /// derecha. Se deriva del número de pestañas en vez de repartirlas a mano:
  /// con cuatro daba 2 y con cinco sigue dando 2, y añadir otra no obliga a
  /// recordar este sitio. El botón del centro no es una pestaña, solo parte la
  /// fila en dos.
  static int get _antesDelDirecto => MohanaTab.values.length ~/ 2;

  final MohanaTab current;
  final ValueChanged<MohanaTab> onSelect;

  /// Acción del botón del directo. Por defecto vuelve al stream de la emisora
  /// y abre su reproductor.
  final VoidCallback? onLive;

  const MohanaBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
    this.onLive,
  });

  /// Vuelve a la emisora en vivo y abre [RadioScreen].
  ///
  /// Si ya está en el directo no lo reanuda: el usuario pudo haberlo pausado a
  /// propósito, y aquí solo pidió ver el reproductor.
  void _openLive(BuildContext context) {
    if (onLive != null) {
      onLive!();
      return;
    }
    final audio = AudioService();
    if (!audio.isLive) audio.playLive();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RadioScreen()));
  }

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // El relleno de la píldora se saca del ancho real en vez de ser
          // fijo. Con cinco pestañas en una pantalla de 320 px cada una se
          // queda en 52 px, pero la píldora de la seleccionada pedía 56
          // (16 + 24 + 16) y se desbordaba. Así en un teléfono normal sigue
          // siendo el de siempre y solo se aprieta donde no cabe.
          //
          // No depende del tamaño de la letra porque la barra no pinta texto,
          // y se mide sobre `maxWidth` y no sobre la pantalla para que en
          // apaisado cuente los márgenes del SafeArea.
          final porPestana =
              (constraints.maxWidth - _LiveButton.total) /
              MohanaTab.values.length;
          final relleno = ((porPestana - _iconSize) / 2 - 1).clamp(
            MohanaSpacing.xs,
            MohanaSpacing.base,
          );

          return Row(
            children: [
              for (final tab in MohanaTab.values.take(_antesDelDirecto))
                Expanded(
                  child: _NavItem(
                    tab: tab,
                    selected: tab == current,
                    relleno: relleno,
                    onTap: () => onSelect(tab),
                  ),
                ),
              _LiveButton(onTap: () => _openLive(context)),
              for (final tab in MohanaTab.values.skip(_antesDelDirecto))
                Expanded(
                  child: _NavItem(
                    tab: tab,
                    selected: tab == current,
                    relleno: relleno,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final MohanaTab tab;
  final bool selected;
  final VoidCallback onTap;

  /// Relleno horizontal de la píldora, calculado por la barra a partir del
  /// ancho disponible. Ver el comentario en [MohanaBottomNav.build].
  final double relleno;

  const _NavItem({
    required this.tab,
    required this.selected,
    required this.relleno,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? MohanaColors.primary
        : MohanaColors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: Tooltip(
        message: tab.label,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: MohanaSpacing.sm),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(
                  horizontal: relleno,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? MohanaColors.primary100
                      : Colors.transparent,
                  borderRadius: MohanaRadius.pillAll,
                ),
                child: Icon(
                  selected ? tab.activeIcon : tab.icon,
                  size: MohanaBottomNav._iconSize,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Acceso permanente al directo de la emisora.
///
/// Va en gradiente de marca para que no se lea como una pestaña más: no
/// cambia de sección, cambia lo que suena. El punto rosa avisa de que el
/// directo ya está sonando.
class _LiveButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LiveButton({required this.onTap});

  static const _size = 44.0;

  /// Lo que ocupa de verdad en la fila: el círculo más su margen. La barra lo
  /// resta del ancho disponible para repartir las pestañas, así que la cuenta
  /// vive aquí y no duplicada allí.
  static const total = _size + MohanaSpacing.sm * 2;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioService(),
      builder: (context, _) {
        final audio = AudioService();
        final onAir = audio.isLive && audio.isPlaying;
        final label = onAir
            ? 'Radio en vivo, sonando'
            : 'Escuchar radio en vivo';

        return Padding(
          padding: const EdgeInsets.all(MohanaSpacing.sm),
          child: Semantics(
            button: true,
            label: label,
            child: Tooltip(
              message: label,
              excludeFromSemantics: true,
              // El gradiente y la sombra van fuera del Material: dentro, el
              // recorte circular del ripple se comería el halo.
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  gradient: MohanaGradients.brand,
                  shape: BoxShape.circle,
                  boxShadow: [MohanaShadows.miniPlayer],
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.radio_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        if (onAir)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: MohanaColors.liveIndicator,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
