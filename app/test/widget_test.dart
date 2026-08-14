import 'package:flutter_test/flutter_test.dart';
import 'package:mohana/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MohanaApp());
    await tester.pumpAndSettle();

    expect(find.text('Radio'), findsOneWidget);
    expect(find.text('Muro'), findsOneWidget);
  });
}
