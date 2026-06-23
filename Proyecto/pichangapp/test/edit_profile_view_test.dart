import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pichangapp/views/edit_profile_view.dart';

void main() {
  group('EditProfileView', () {
    testWidgets('debe cargar correctamente un perfil de Basket', (tester) async {
      final usuarioBasket = <String, dynamic>{
        'id': 11,
        'username': 'ep3_user_a',
        'nombre': 'Usuario',
        'apellido': 'PruebaA',
        'email': 'ep3_user_a@pichangapp.cl',
        'profile': <String, dynamic>{
          'descripcion': 'Jugador base de prueba EP3',
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

      expect(find.text('Editar Perfil'), findsOneWidget);
      expect(find.text('Descripción Deportiva'), findsOneWidget);
      expect(find.text('Edad'), findsOneWidget);
      expect(find.text('Deporte Principal'), findsOneWidget);
      expect(find.text('Altura'), findsOneWidget);
      expect(find.text('Posición'), findsOneWidget);
      expect(find.text('BASKET'), findsOneWidget);
      expect(find.text('Base'), findsOneWidget);

      final campos = tester.widgetList<TextField>(find.byType(TextField)).toList();

      expect(campos[0].controller?.text, 'Jugador base de prueba EP3');
      expect(campos[1].controller?.text, '22');
      expect(campos[2].controller?.text, '180');
    });

    testWidgets('debe cargar correctamente un perfil de Boxeo', (tester) async {
      final usuarioBoxeo = <String, dynamic>{
        'id': 12,
        'username': 'ep3_user_b',
        'nombre': 'Usuario',
        'apellido': 'PruebaB',
        'email': 'ep3_user_b@pichangapp.cl',
        'profile': <String, dynamic>{
          'descripcion': 'Boxeador de prueba EP3',
          'edad': 24,
          'deportePrincipal': 'BOXEO',
          'atributosDeportivos': <String, dynamic>{
            'peso': 75,
            'guardia': 'Ortodoxa',
          },
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileView(usuarioActual: usuarioBoxeo),
        ),
      );

      expect(find.text('Editar Perfil'), findsOneWidget);
      expect(find.text('Peso'), findsOneWidget);
      expect(find.text('Guardia'), findsOneWidget);
      expect(find.text('BOXEO'), findsOneWidget);
      expect(find.text('Ortodoxa'), findsOneWidget);

      final campos = tester.widgetList<TextField>(find.byType(TextField)).toList();

      expect(campos[0].controller?.text, 'Boxeador de prueba EP3');
      expect(campos[1].controller?.text, '24');
      expect(campos[2].controller?.text, '75');
    });

    testWidgets('debe mostrar error si la edad esta vacia', (tester) async {
      final usuarioEdadVacia = <String, dynamic>{
        'id': 13,
        'username': 'ep3_user_c',
        'nombre': 'Usuario',
        'apellido': 'PruebaC',
        'email': 'ep3_user_c@pichangapp.cl',
        'profile': <String, dynamic>{
          'descripcion': 'Usuario con edad vacía',
          'edad': null,
          'deportePrincipal': 'BASKET',
          'atributosDeportivos': <String, dynamic>{
            'altura': 180,
            'posicion': 'Base',
          },
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileView(usuarioActual: usuarioEdadVacia),
        ),
      );

      await tester.ensureVisible(find.text('Guardar Cambios'));
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pump();

      expect(
        find.text('Por favor ingresa una edad válida'),
        findsOneWidget,
      );
    });

    testWidgets('debe mostrar error si la altura esta vacia en Basket', (tester) async {
      final usuarioSinAltura = <String, dynamic>{
        'id': 14,
        'username': 'ep3_user_d',
        'nombre': 'Usuario',
        'apellido': 'PruebaD',
        'email': 'ep3_user_d@pichangapp.cl',
        'profile': <String, dynamic>{
          'descripcion': 'Jugador Basket sin altura',
          'edad': 22,
          'deportePrincipal': 'BASKET',
          'atributosDeportivos': <String, dynamic>{
            'altura': null,
            'posicion': 'Base',
          },
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileView(usuarioActual: usuarioSinAltura),
        ),
      );

      await tester.ensureVisible(find.text('Guardar Cambios'));
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pump();

      expect(
        find.text('Por favor ingresa una altura válida'),
        findsOneWidget,
      );
    });

    testWidgets('debe mostrar error si el peso esta vacio en Boxeo', (tester) async {
      final usuarioSinPeso = <String, dynamic>{
        'id': 15,
        'username': 'ep3_user_e',
        'nombre': 'Usuario',
        'apellido': 'PruebaE',
        'email': 'ep3_user_e@pichangapp.cl',
        'profile': <String, dynamic>{
          'descripcion': 'Boxeador sin peso',
          'edad': 24,
          'deportePrincipal': 'BOXEO',
          'atributosDeportivos': <String, dynamic>{
            'peso': null,
            'guardia': 'Ortodoxa',
          },
        },
      };

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileView(usuarioActual: usuarioSinPeso),
        ),
      );

      await tester.ensureVisible(find.text('Guardar Cambios'));
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pump();

      expect(
        find.text('Por favor ingresa un peso válido'),
        findsOneWidget,
      );
    });
  });
}