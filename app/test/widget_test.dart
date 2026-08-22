import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohana/main.dart';

void main() {
  testWidgets('la app arranca en el splash con los logos', (tester) async {
    await tester.pumpWidget(const MohanaApp());
    // Sin pumpAndSettle: el splash anima en bucle y nunca quedaría quieto.
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);

    final assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => i.image)
        .whereType<AssetImage>()
        .map((a) => a.assetName)
        .toList();

    // El logo de la OFP ya no es el JPEG opaco, sino el PNG con transparencia.
    expect(assets, contains('assets/images/logo_ofp.png'));
    expect(assets, contains('assets/images/logo_emisora.png'));
  });
}
