import 'package:flutter_test/flutter_test.dart';
import 'package:pichangapp/controllers/chat_controller.dart';
import 'package:pichangapp/models/deportista.dart';
import 'package:pichangapp/models/login_response.dart';
import 'package:pichangapp/models/mensaje_chat.dart';
import 'package:pichangapp/models/sala_chat.dart';

void main() {
  group('Modelos del frontend', () {
    test('debe convertir respuesta de login desde JSON', () {
      final json = {
        'token': 'jwt-prueba',
        'username': 'ep3_user_a',
        'userId': 11,
        'message': 'Login exitoso',
      };

      final response = LoginResponse.fromJson(json);

      expect(response.token, 'jwt-prueba');
      expect(response.username, 'ep3_user_a');
      expect(response.userId, 11);
      expect(response.message, 'Login exitoso');
    });

    test('debe convertir una sala de chat desde JSON', () {
      final json = {
        'id': 7,
        'matchSocialId': 8,
        'usuarioAId': 11,
        'usuarioBId': 12,
        'estado': 'ACTIVA',
        'fechaCreacion': '2026-06-22T10:00:00',
      };

      final sala = SalaChat.fromJson(json);

      expect(sala.id, 7);
      expect(sala.matchSocialId, 8);
      expect(sala.usuarioAId, 11);
      expect(sala.usuarioBId, 12);
      expect(sala.estado, 'ACTIVA');
      expect(sala.fechaCreacion, '2026-06-22T10:00:00');
    });

    test('debe obtener el otro usuario de una sala', () {
      final sala = SalaChat.fromJson({
        'id': 7,
        'matchSocialId': 8,
        'usuarioAId': 11,
        'usuarioBId': 12,
        'estado': 'ACTIVA',
        'fechaCreacion': '2026-06-22T10:00:00',
      });

      expect(sala.obtenerOtroUsuarioId(11), 12);
      expect(sala.obtenerOtroUsuarioId(12), 11);
      expect(sala.obtenerOtroUsuarioId(99), 0);
    });

    test('debe convertir un mensaje de chat desde JSON', () {
      final json = {
        'id': 20,
        'salaChatId': 7,
        'remitenteId': 11,
        'contenido': 'Mensaje de prueba EP3',
        'tipoMensaje': 'TEXTO',
        'mediaUrl': null,
        'fechaEnvio': '2026-06-22T10:30:00',
      };

      final mensaje = MensajeChat.fromJson(json);

      expect(mensaje.id, 20);
      expect(mensaje.salaChatId, 7);
      expect(mensaje.remitenteId, 11);
      expect(mensaje.contenido, 'Mensaje de prueba EP3');
      expect(mensaje.tipoMensaje, 'TEXTO');
      expect(mensaje.mediaUrl, null);
      expect(mensaje.fechaEnvio, '2026-06-22T10:30:00');
    });

    test('debe convertir un deportista Basket desde JSON', () {
      final json = <String, dynamic>{
        'id': 11,
        'username': 'ep3_user_a',
        'nombre': 'Usuario',
        'apellido': 'PruebaA',
        'email': 'ep3_user_a@pichangapp.cl',
        'profile': <String, dynamic>{
          'descripcion': 'Jugador de basket',
          'edad': 22,
          'fotoUrl': 'https://example.com/foto.png',
          'deportePrincipal': 'BASKET',
          'atributosDeportivos': <String, dynamic>{
            'altura': 180,
            'posicion': 'Base',
          },
        },
      };

      final deportista = Deportista.fromJson(json);

      expect(deportista.id, 11);
      expect(deportista.username, 'ep3_user_a');
      expect(deportista.nombreCompleto, 'Usuario PruebaA');
      expect(deportista.descripcion, 'Jugador de basket');
      expect(deportista.edad, 22);
      expect(deportista.deportePrincipal, 'BASKET');
      expect(deportista.altura, '180 cm');
      expect(deportista.posicion, 'Base');
    });

    test('debe usar datos por defecto si el deportista no tiene perfil', () {
      final json = <String, dynamic>{
        'id': 12,
        'username': 'ep3_user_b',
        'nombre': 'Usuario',
        'apellido': 'PruebaB',
        'email': 'ep3_user_b@pichangapp.cl',
      };

      final deportista = Deportista.fromJson(json);

      expect(deportista.id, 12);
      expect(deportista.nombreCompleto, 'Usuario PruebaB');
      expect(deportista.descripcion, 'Sin descripción deportiva');
      expect(deportista.edad, 0);
      expect(deportista.deportePrincipal, 'DEPORTE');
      expect(deportista.posicion, 'Sin posición');
      expect(deportista.altura, 'Sin altura');
    });
  });

  group('ChatController', () {
    test('debe entregar la lista de chats simulados', () {
      final controller = ChatController();

      final chats = controller.obtenerChatsSimulados();

      expect(chats.length, 3);
      expect(chats.first.chatId, 'chat_001');
      expect(chats.first.athleteName, 'Carlos, 28');
      expect(chats.first.isUnread, true);
    });

    test('debe entregar mensajes del chat seleccionado', () {
      final controller = ChatController();

      final mensajes = controller.obtenerMensajesPorChat('chat_001');

      expect(mensajes.length, 3);
      expect(mensajes.first.messageId, 'm1');
      expect(mensajes.first.senderId, 'user_88');
      expect(
        mensajes.last.text,
        '¡Genial! ¿Nos vemos el sábado en la cancha entonces?',
      );
    });

    test('debe retornar lista vacia si el chat no existe', () {
      final controller = ChatController();

      final mensajes = controller.obtenerMensajesPorChat('chat_inexistente');

      expect(mensajes, isEmpty);
    });
  });
}