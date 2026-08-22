import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohana/models/podcast_item.dart';
import 'package:mohana/widgets/program_grid_card.dart';

/// La cuadrícula de "Todos los programas" usaba una proporción fija y el
/// conteo de episodios se salía de la tarjeta. Ahora el alto se calcula, así
/// que aquí se comprueba que no vuelva a desbordarse.
void main() {
  const program = PodcastItem(
    id: '12112848',
    title: 'Mujeres y melodías del Magdalena Medio',
    description: '',
    body: '',
    imageUrl: '',
    episodes: '740',
  );

  /// Monta la cuadrícula igual que la pantalla real: dos columnas y el alto
  /// que la propia tarjeta declara.
  Future<void> pumpGrid(
    WidgetTester tester, {
    required Size screen,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: screen,
          textScaler: TextScaler.linear(textScale),
        ),
        child: const MaterialApp(
          home: Scaffold(body: _Grid(program: program)),
        ),
      ),
    );
    await tester.pump();
  }

  /// El título ocupa dos líneas y el conteo de episodios va debajo: si la
  /// tarjeta se queda corta, alguno de los dos se recorta o se sale.
  void expectTextFits(WidgetTester tester, {double textScale = 1.0}) {
    expect(tester.takeException(), isNull);

    final card = tester.getRect(find.byType(ProgramGridCard).first);
    final title = tester.getRect(find.text(program.title).first);
    final count = tester.getRect(find.text('740 episodios').first);

    // Dos líneas de título (13 px de alto de línea 1.25), no una recortada.
    expect(
      title.height,
      greaterThan(13 * 1.25 * 1.5 * textScale),
      reason: 'el título se quedó en una línea: la tarjeta es demasiado baja',
    );
    // Y el conteo cabe entero dentro de la tarjeta.
    expect(count.height, greaterThan(0));
    expect(
      count.bottom,
      lessThanOrEqualTo(card.bottom + 0.5),
      reason: 'el conteo de episodios se sale de la tarjeta',
    );
  }

  testWidgets('el texto cabe en una pantalla estrecha', (tester) async {
    await pumpGrid(tester, screen: const Size(320, 640));

    expectTextFits(tester);
  });

  testWidgets('el texto cabe en una pantalla ancha', (tester) async {
    await pumpGrid(tester, screen: const Size(600, 900));

    expectTextFits(tester);
  });

  testWidgets('el texto cabe con la letra ampliada por accesibilidad', (
    tester,
  ) async {
    await pumpGrid(tester, screen: const Size(360, 720), textScale: 1.3);

    expectTextFits(tester, textScale: 1.3);
  });
}

/// Réplica mínima de la cuadrícula de la pantalla de podcasts.
class _Grid extends StatelessWidget {
  final PodcastItem program;

  const _Grid({required this.program});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: ProgramGridCard.extentFor(context),
            ),
            delegate: SliverChildBuilderDelegate(
              (_, _) => ProgramGridCard(program: program, onTap: () {}),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }
}
