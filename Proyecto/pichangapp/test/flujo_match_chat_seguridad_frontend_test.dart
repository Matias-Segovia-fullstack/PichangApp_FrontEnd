import 'package:flutter_test/flutter_test.dart';
import 'package:pichangapp/models/deportista.dart';
import 'package:pichangapp/models/mensaje_chat.dart';
import 'package:pichangapp/models/sala_chat.dart';
import 'package:pichangapp/services/api_service.dart';

void main() {
  group('Frontend - Discover y Match', () {
    test('debe mostrar solo deportistas disponibles para interactuar', () {
      final miUsuarioId = 11;
      final usuariosYaInteractuados = {12};

      final usuariosRaw = <Map<String, dynamic>>[
        {
          'id': 11,
          'username': 'yo',
          'nombre': 'Usuario',
          'apellido': 'Actual',
          'email': 'yo@pichangapp.cl',
          'profile': {
            'descripcion': 'Mi propio perfil',
            'edad': 22,
            'deportePrincipal': 'BASKET',
            'atributosDeportivos': {
              'altura': 180,
              'posicion': 'Base',
            },
          },
        },
        {
          'id': 12,
          'username': 'usuario_ya_interactuado',
          'nombre': 'Usuario',
          'apellido': 'Interactuado',
          'email': 'interactuado@pichangapp.cl',
          'profile': {
            'descripcion': 'Perfil ya interactuado',
            'edad': 23,
            'deportePrincipal': 'BASKET',
            'atributosDeportivos': {
              'altura': 175,
              'posicion': 'Escolta',
            },
          },
        },
        {
          'id': 13,
          'username': 'usuario_disponible',
          'nombre': 'Usuario',
          'apellido': 'Disponible',
          'email': 'disponible@pichangapp.cl',
          'profile': {
            'descripcion': 'Perfil disponible para match',
            'edad': 24,
            'deportePrincipal': 'BASKET',
            'atributosDeportivos': {
              'altura': 182,
              'posicion': 'Alero',
            },
          },
        },
      ];

      final deportistasDisponibles = usuariosRaw
          .map(Deportista.fromJson)
          .where((deportista) => deportista.id != miUsuarioId)
          .where((deportista) => !usuariosYaInteractuados.contains(deportista.id))
          .toList();

      expect(deportistasDisponibles.length, 1);
      expect(deportistasDisponibles.first.id, 13);
      expect(deportistasDisponibles.first.username, 'usuario_disponible');
      expect(deportistasDisponibles.first.nombreCompleto, 'Usuario Disponible');
      expect(deportistasDisponibles.first.posicion, 'Alero');
      expect(deportistasDisponibles.first.altura, '182 cm');
    });

    test('debe interpretar correctamente un deportista recibido desde el backend', () {
      final json = <String, dynamic>{
        'id': 20,
        'username': 'basket_test',
        'nombre': 'Carlos',
        'apellido': 'Rojas',
        'email': 'carlos@pichangapp.cl',
        'profile': {
          'descripcion': 'Jugador de basket para prueba frontend',
          'edad': 28,
          'fotoUrl': 'https://example.com/foto.png',
          'deportePrincipal': 'BASKET',
          'atributosDeportivos': {
            'altura': 185,
            'posicion': 'Pivot',
          },
        },
      };

      final deportista = Deportista.fromJson(json);

      expect(deportista.id, 20);
      expect(deportista.username, 'basket_test');
      expect(deportista.nombreCompleto, 'Carlos Rojas');
      expect(deportista.descripcion, 'Jugador de basket para prueba frontend');
      expect(deportista.edad, 28);
      expect(deportista.deportePrincipal, 'BASKET');
      expect(deportista.posicion, 'Pivot');
      expect(deportista.altura, '185 cm');
    });
  });

  group('Frontend - Chat', () {
    test('debe identificar al otro usuario dentro de una sala de chat', () {
      final sala = SalaChat.fromJson({
        'id': 7,
        'matchSocialId': 50,
        'usuarioAId': 11,
        'usuarioBId': 12,
        'estado': 'ACTIVA',
        'fechaCreacion': '2026-06-22T10:00:00',
      });

      expect(sala.obtenerOtroUsuarioId(11), 12);
      expect(sala.obtenerOtroUsuarioId(12), 11);
      expect(sala.obtenerOtroUsuarioId(99), 0);
    });

    test('debe convertir una sala de chat recibida desde el backend', () {
      final sala = SalaChat.fromJson({
        'id': 7,
        'matchSocialId': 50,
        'usuarioAId': 11,
        'usuarioBId': 12,
        'estado': 'ACTIVA',
        'fechaCreacion': '2026-06-22T10:00:00',
      });

      expect(sala.id, 7);
      expect(sala.matchSocialId, 50);
      expect(sala.usuarioAId, 11);
      expect(sala.usuarioBId, 12);
      expect(sala.estado, 'ACTIVA');
      expect(sala.fechaCreacion, '2026-06-22T10:00:00');
    });

    test('debe convertir un mensaje de texto recibido desde el backend', () {
      final mensaje = MensajeChat.fromJson({
        'id': 100,
        'salaChatId': 7,
        'remitenteId': 11,
        'contenido': 'Hola, ¿jugamos este sábado?',
        'tipoMensaje': 'TEXTO',
        'mediaUrl': null,
        'fechaEnvio': '2026-06-22T10:30:00',
      });

      expect(mensaje.id, 100);
      expect(mensaje.salaChatId, 7);
      expect(mensaje.remitenteId, 11);
      expect(mensaje.contenido, 'Hola, ¿jugamos este sábado?');
      expect(mensaje.tipoMensaje, 'TEXTO');
      expect(mensaje.mediaUrl, null);
      expect(mensaje.fechaEnvio, '2026-06-22T10:30:00');
    });

    test('debe convertir un mensaje con imagen recibido desde el backend', () {
      final mensaje = MensajeChat.fromJson({
        'id': 101,
        'salaChatId': 7,
        'remitenteId': 12,
        'contenido': '[Imagen]',
        'tipoMensaje': 'IMAGEN',
        'mediaUrl': 'https://example.com/imagen-chat.png',
        'fechaEnvio': '2026-06-22T10:35:00',
      });

      expect(mensaje.id, 101);
      expect(mensaje.salaChatId, 7);
      expect(mensaje.remitenteId, 12);
      expect(mensaje.contenido, '[Imagen]');
      expect(mensaje.tipoMensaje, 'IMAGEN');
      expect(mensaje.mediaUrl, 'https://example.com/imagen-chat.png');
    });
  });

  group('Frontend - Seguridad y servicios', () {
    test('debe tener configurada la URL del microservicio de match', () {
      expect(ApiService.matchBaseUrl, 'http://168.129.178.109:8081');
    });

    test('debe tener configurada la URL del microservicio de comunicacion', () {
      expect(ApiService.comunicacionBaseUrl, 'http://168.129.178.109:8082');
    });

    test('debe tener configurada la URL del microservicio de seguridad', () {
      expect(ApiService.seguridadBaseUrl, 'http://168.129.178.109:8004');
    });

    test('debe tener configurada la URL del microservicio de usuarios', () {
      expect(ApiService.usuarioBaseUrl, 'http://168.129.178.109:8001');
    });
  });
}