import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pichangapp/main.dart';

void main() {
  testWidgets('La app carga sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const PichangApp());

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MaterialApp), findsOneWidget); 
  });


  
}