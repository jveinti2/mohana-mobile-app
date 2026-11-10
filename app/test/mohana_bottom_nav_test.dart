import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohana/config/theme.dart';
import 'package:mohana/widgets/mohana_bottom_nav.dart';

/// La barra inferior no se desborda cuando no cabe: va dentro de un [Center],
/// así que al faltar ancho el icono se aprieta en silencio. `responsive_test`
/// no la pilla —no salta ningún `FlutterError`— y con cinco pestañas en una
/// pantalla de 320 px era justo lo que pasaba: el icono de la pestaña
/// seleccionada se quedaba por debajo de sus 24 px.
///
/// Por eso aquí se mide en vez de esperar una excepción.
void main() {
  Future<void> montar(
    WidgetTester tester, {
    required double ancho,
    required MohanaTab seleccionada,
  }) async {
    tester.view.physicalSize = Size(ancho, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: MohanaTheme.light,
        home: Scaffold(
          bottomNavigationBar: MohanaBottomNav(
            current: seleccionada,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Tamaño con el que se pintó el icono de [tab].
  Size iconoDe(WidgetTester tester, MohanaTab tab) {
    final icono = find.byIcon(tab.activeIcon);
    expect(icono, findsOneWidget, reason: 'no se pintó el icono de ${tab.label}');
    return tester.getSize(icono);
  }

  // 320 px es el caso que obligó al arreglo: (320 - 60) / 5 = 52 px por
  // pestaña, y la píldora con el relleno de antes pedía 16 + 24 + 16 = 56.
  testWidgets('a 320 px el icono de la pestaña seleccionada no se aprieta', (
    tester,
  ) async {
    await montar(tester, ancho: 320, seleccionada: MohanaTab.premium);

    expect(iconoDe(tester, MohanaTab.premium).width, 24.0);
  });

  testWidgets('a 320 px tampoco se aprieta en el grupo de la izquierda', (
    tester,
  ) async {
    await montar(tester, ancho: 320, seleccionada: MohanaTab.inicio);

    expect(iconoDe(tester, MohanaTab.inicio).width, 24.0);
  });

  testWidgets('en un teléfono normal la píldora mantiene su holgura', (
    tester,
  ) async {
    // El relleno solo se aprieta donde no cabe: a 412 px debe seguir siendo el
    // de siempre, o el arreglo del caso estrecho habría encogido la barra en
    // todos los teléfonos.
    await montar(tester, ancho: 412, seleccionada: MohanaTab.premium);

    final pildora = tester.getSize(
      find.ancestor(
        of: find.byIcon(MohanaTab.premium.activeIcon),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(pildora.width, 24 + MohanaSpacing.base * 2);
  });

  testWidgets('las cinco pestañas y el botón del directo caben en 320 px', (
    tester,
  ) async {
    await montar(tester, ancho: 320, seleccionada: MohanaTab.premium);

    for (final tab in MohanaTab.values) {
      final icono = tab == MohanaTab.premium ? tab.activeIcon : tab.icon;
      expect(
        find.byIcon(icono),
        findsOneWidget,
        reason: 'falta la pestaña ${tab.label}',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
