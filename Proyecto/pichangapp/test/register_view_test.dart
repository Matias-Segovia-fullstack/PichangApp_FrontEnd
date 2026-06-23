import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pichangapp/views/register_view.dart';

void main() {
  group('RegisterView', () {
    testWidgets('debe mostrar los campos principales del formulario de registro', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterView(),
        ),
      );

      expect(find.text('Crear cuenta deportiva'), findsOneWidget);
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Apellido'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('RUT opcional'), findsOneWidget);
      expect(find.text('Registrarme'), findsOneWidget);
    });

    testWidgets('debe permitir escribir datos en el formulario de registro', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterView(),
        ),
      );

      await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Usuario');
      await tester.enterText(find.widgetWithText(TextField, 'Apellido'), 'Prueba');
      await tester.enterText(find.widgetWithText(TextField, 'Username'), 'ep3_user_front');
      await tester.enterText(find.widgetWithText(TextField, 'Correo electrónico'), 'ep3_front@pichangapp.cl');
      await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), 'Test123456');

      expect(find.text('Usuario'), findsOneWidget);
      expect(find.text('Prueba'), findsOneWidget);
      expect(find.text('ep3_user_front'), findsOneWidget);
      expect(find.text('ep3_front@pichangapp.cl'), findsOneWidget);
      expect(find.text('Test123456'), findsOneWidget);
    });
  });
}