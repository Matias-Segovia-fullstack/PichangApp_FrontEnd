import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pichangapp/views/login_view.dart';
import 'package:pichangapp/views/edit_profile_view.dart';

void main() {
  group('Flujos funcionales del frontend', () {
    testWidgets('el usuario no puede iniciar sesion con campos vacios', (tester) async {
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

    testWidgets('el usuario puede ir desde login hacia registro y completar el formulario', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginView(),
        ),
      );

      await tester.tap(find.text('¿No tienes cuenta? Regístrate aquí'));
      await tester.pumpAndSettle();

      expect(find.text('Crear cuenta deportiva'), findsOneWidget);

      final campos = tester.widgetList<TextField>(find.byType(TextField)).toList();

      expect(campos.length, greaterThanOrEqualTo(6));

      await tester.enterText(find.byType(TextField).at(0), 'Usuario');
      await tester.enterText(find.byType(TextField).at(1), 'Prueba');
      await tester.enterText(find.byType(TextField).at(2), 'ep3_front');
      await tester.enterText(find.byType(TextField).at(3), 'ep3_front@pichangapp.cl');
      await tester.enterText(find.byType(TextField).at(4), 'Test123456');
      await tester.enterText(find.byType(TextField).at(5), '12345678-9');

      expect(find.text('Usuario'), findsOneWidget);
      expect(find.text('Prueba'), findsOneWidget);
      expect(find.text('ep3_front'), findsOneWidget);
      expect(find.text('ep3_front@pichangapp.cl'), findsOneWidget);
      expect(find.text('Test123456'), findsOneWidget);
      expect(find.text('12345678-9'), findsOneWidget);
    });

    testWidgets('el registro muestra error si se intenta crear cuenta sin datos', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginView(),
        ),
      );

      await tester.tap(find.text('¿No tienes cuenta? Regístrate aquí'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Registrarme'));
      await tester.tap(find.text('Registrarme'));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Error al crear la cuenta. Revisa los datos o usa otro username/email.'),
        findsOneWidget,
      );
    });

    testWidgets('editar perfil cambia campos de Basket a Boxeo', (tester) async {
      final usuarioBasket = <String, dynamic>{
        'id': 11,
        'username': 'ep3_user_a',
        'nombre': 'Usuario',
        'apellido': 'PruebaA',
        'email': 'ep3_user_a@pichangapp.cl',
        'profile': <String, dynamic>{
          'descripcion': 'Jugador de basket para prueba',
          'edad': 22,
          'deportePrincipal': 'BASKET',
          'atributosDeportivos': <String, dynamic>{
            'altura': 180,
            'posicion': 'Base',
          },
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileView(usuarioActual: usuarioBasket),
        ),
      );

      expect(find.text('Altura'), findsOneWidget);
      expect(find.text('Posición'), findsOneWidget);
      expect(find.text('BASKET'), findsOneWidget);
      expect(find.text('Base'), findsOneWidget);

      await tester.tap(find.text('BASKET').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('BOXEO').last);
      await tester.pumpAndSettle();

      expect(find.text('Peso'), findsOneWidget);
      expect(find.text('Guardia'), findsOneWidget);
      expect(find.text('BOXEO'), findsOneWidget);
    });

    testWidgets('editar perfil rechaza Basket sin posicion', (tester) async {
      final usuarioSinPosicion = <String, dynamic>{
        'id': 12,
        'username': 'ep3_user_b',
        'nombre': 'Usuario',
        'apellido': 'PruebaB',
        'email': 'ep3_user_b@pichangapp.cl',
        'profile': <String, dynamic>{
          'descripcion': 'Jugador Basket sin posición',
          'edad': 22,
          'deportePrincipal': 'BASKET',
          'atributosDeportivos': <String, dynamic>{
            'altura': 180,
            'posicion': null,
          },
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileView(usuarioActual: usuarioSinPosicion),
        ),
      );

      await tester.ensureVisible(find.text('Guardar Cambios'));
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pump();

      expect(
        find.text('Por favor selecciona una posición'),
        findsOneWidget,
      );
    });

    testWidgets('editar perfil rechaza Boxeo sin guardia', (tester) async {
      final usuarioSinGuardia = <String, dynamic>{
        'id': 13,
        'username': 'ep3_user_c',
        'nombre': 'Usuario',
        'apellido': 'PruebaC',
        'email': 'ep3_user_c@pichangapp.cl',
        'profile': <String, dynamic>{
          'descripcion': 'Boxeador sin guardia',
          'edad': 24,
          'deportePrincipal': 'BOXEO',
          'atributosDeportivos': <String, dynamic>{
            'peso': 75,
            'guardia': null,
          },
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileView(usuarioActual: usuarioSinGuardia),
        ),
      );

      await tester.ensureVisible(find.text('Guardar Cambios'));
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pump();

      expect(
        find.text('Por favor selecciona una guardia'),
        findsOneWidget,
      );
    });
  });
}