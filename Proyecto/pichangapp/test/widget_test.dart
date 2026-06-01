import 'package:flutter_test/flutter_test.dart';
import 'package:pichangapp/main.dart';

void main() {
  testWidgets('La app carga sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const PichangApp());
    await tester.pump();

    expect(find.text('PichangApp'), findsOneWidget);
  });
}