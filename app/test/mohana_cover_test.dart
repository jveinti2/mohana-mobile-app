import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohana/widgets/mohana_cover.dart';

/// El respaldo de imagen tiene que valer para cualquier sección: da igual si
/// el contenido viene de iVoox o de Drive, si no trae carátula se ve el logo
/// de la emisora y nunca un hueco.
void main() {
  Future<void> pumpCover(WidgetTester tester, Widget cover) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: cover))),
    );
  }

  /// Nombre del asset, desenvolviendo el `ResizeImage` con el que las
  /// miniaturas limitan la resolución de decodificado.
  String? assetNameOf(ImageProvider provider) {
    if (provider is ResizeImage) return assetNameOf(provider.imageProvider);
    if (provider is AssetImage) return provider.assetName;
    if (provider is ExactAssetImage) return provider.assetName;
    return null;
  }

  List<String> assetsIn(WidgetTester tester) => tester
      .widgetList<Image>(find.byType(Image))
      .map((i) => assetNameOf(i.image))
      .whereType<String>()
      .toList();

  testWidgets('sin URL se pinta el logo de la emisora', (tester) async {
    await pumpCover(tester, const MohanaCover.square(url: '', size: 120));

    expect(find.byType(MohanaCoverFallback), findsOneWidget);
    expect(assetsIn(tester), contains('assets/images/logo_emisora.png'));
  });

  testWidgets('el respaldo también sirve de miniatura', (tester) async {
    await pumpCover(tester, const MohanaCover.square(url: '', size: 36));

    expect(find.byType(MohanaCoverFallback), findsOneWidget);
    expect(tester.getSize(find.byType(MohanaCoverFallback)), const Size(36, 36));
  });

  testWidgets('respeta el tamaño pedido', (tester) async {
    await pumpCover(tester, const MohanaCover.square(url: '', size: 200));

    expect(tester.getSize(find.byType(MohanaCover)), const Size(200, 200));
  });

  testWidgets('sin tamaño fijo ocupa el espacio disponible', (tester) async {
    await pumpCover(
      tester,
      const SizedBox(width: 150, height: 90, child: MohanaCover(url: '')),
    );

    expect(find.byType(MohanaCoverFallback), findsOneWidget);
    expect(tester.getSize(find.byType(MohanaCoverFallback)), const Size(150, 90));
  });
}
