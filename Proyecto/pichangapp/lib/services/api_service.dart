import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Usamos 10.0.2.2 porque es el "localhost" del emulador de Android.
  // Así el celular virtual se puede conectar al backend en tu computadora.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8001/api'; // Chrome / Web
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001/api';  // Emulador Android
    } else {
      return 'http://127.0.0.1:8001/api'; // Windows / iOS / Mac
    }
  }

  static String get baseMatchUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8081/api/v1'; // Chrome / Web
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081/api/v1';  // Emulador Android
    } else {
      return 'http://127.0.0.1:8081/api/v1'; // Windows / iOS / Mac
    }
  }

  static String get baseChatUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8082/api/v1/chat'; // Chrome / Web
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8082/api/v1/chat';  // Emulador Android
    } else {
      return 'http://127.0.0.1:8082/api/v1/chat'; // Windows / iOS / Mac
    }
  }

  static String get loginUrl => baseUrl.replaceAll('/api', '/login');
  /// Retorna [true] si la cuenta se creó exitosamente (código 201 o 200).
  /// En caso de error (red o validación), captura la excepción y retorna [false].
  Future<bool> registrarUsuario(Map<String, dynamic> userData) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    // AQUÍ ESTÁ EL TRUCO:
    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      // Imprime el error que viene del servidor
      print("Error del servidor: ${response.statusCode}");
      print("Cuerpo del error: ${response.body}");
      return false;
    }
  } catch (e) {
    // Imprime el error de conexión
    print("Error en el cliente: $e");
    return false;
  }
}

  /// Realiza la petición de Login.
  /// Retorna el Token JWT como String si es exitoso, o null si falla.
Future<String?> loginUsuario(String username, String password) async {
  try {
    // Usamos loginUrl, que automáticamente cambia a localhost si estás en la Web
    final response = await http.post(
      Uri.parse(loginUrl), 
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['token'];
    } else {
      // Es útil imprimir el código para saber por qué falla (ej. 401 Unauthorized)
      print("Error de Login: ${response.statusCode} - ${response.body}");
      return null; 
    }
  } catch (e) {
    // Esto capturará el error de conexión si el backend está apagado
    print("Excepción al intentar loguear: $e");
    return null;
  }
}

  /// Obtiene la lista de usuarios desde msvc-usuario
  Future<List<dynamic>> getPosiblesMatches() async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'jwt_token');

      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // Usaremos un ID de origen fijo (1) para la demo, asumiendo que es el usuario logueado.
      final int miPropioId = 1;

      // Obtener a los que ya les dio like/dislike
      final interaccionesResponse = await http.get(
        Uri.parse('$baseMatchUrl/interacciones/user/$miPropioId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      List<int> interactedUserIds = [];
      if (interaccionesResponse.statusCode == 200) {
        final List<dynamic> interacciones = jsonDecode(interaccionesResponse.body);
        interactedUserIds = interacciones.map((i) => i['usuarioDestinoId'] as int).toList();
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['_embedded'] != null && data['_embedded']['userResponseDTOList'] != null) {
          final List<dynamic> allUsers = data['_embedded']['userResponseDTOList'];
          // Filtrar los que ya interactuamos y a nosotros mismos
          return allUsers.where((u) {
            int userId = u['id'] ?? 0;
            return userId != miPropioId && !interactedUserIds.contains(userId);
          }).toList();
        }
        return [];
      } else {
        print("Error fetching users: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Excepción fetching users: $e");
      return [];
    }
  }

  /// Envia una interacción (Like/Dislike)
  Future<bool> enviarInteraccion(int usuarioOrigenId, int usuarioDestinoId, String tipo) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'jwt_token');

      final response = await http.post(
        Uri.parse('$baseMatchUrl/interacciones'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "usuarioOrigenId": usuarioOrigenId,
          "usuarioDestinoId": usuarioDestinoId,
          "tipo": tipo // "ME_GUSTA" o "DISME_GUSTA"
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("Error interacción: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Excepción enviando interacción: $e");
      return false;
    }
  }

  /// Obtiene la lista de chats para un usuario
  Future<List<dynamic>> getUserRooms(int userId) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'jwt_token');

      final response = await http.get(
        Uri.parse('$baseChatUrl/salas/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Error fetching rooms: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Excepción fetching rooms: $e");
      return [];
    }
  }

  /// Obtiene los mensajes de una sala
  Future<List<dynamic>> getMensajes(int salaId) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'jwt_token');

      final response = await http.get(
        Uri.parse('$baseChatUrl/salas/$salaId/mensajes'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['content'] != null) {
          return data['content']; // Es un Page de Spring
        }
        return [];
      } else {
        print("Error fetching messages: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Excepción fetching messages: $e");
      return [];
    }
  }

  /// Enviar un mensaje a una sala
  Future<bool> enviarMensaje(int salaId, int emisorId, String texto) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'jwt_token');

      final response = await http.post(
        Uri.parse('$baseChatUrl/salas/$salaId/mensajes'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "remitenteId": emisorId,
          "contenido": texto
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Excepción enviando mensaje: $e");
      return false;
    }
  }

  /// Obtiene los datos de un usuario por su ID
  Future<Map<String, dynamic>?> getUsuario(int id) async {
    try {
      const storage = FlutterSecureStorage();
      String? token = await storage.read(key: 'jwt_token');

      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("Excepción getUsuario: $e");
      return null;
    }
  }
}