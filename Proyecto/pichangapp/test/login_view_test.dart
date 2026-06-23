import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pichangapp/views/login_view.dart';

void main() {
  group('LoginView', () {
    testWidgets('debe mostrar errores si se intenta iniciar sesion con campos vacios', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginView(),
        ),
      );

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();

      expect(find.text('Ingresa tu usuario'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('debe mostrar mensaje cuando se presiona login con Google', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginView(),
        ),
      );

      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();

      expect(
        find.text('Google Login queda pendiente. Usa login con username.'),
        findsOneWidget,
      );
    });
  });
}