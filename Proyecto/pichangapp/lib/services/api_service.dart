import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';

class ApiService {
  static String get usuarioBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8001';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001';
    }

    return 'http://127.0.0.1:8001';
  }

  static String get matchBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8081';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081';
    }

    return 'http://127.0.0.1:8081';
  }

  static String get comunicacionBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8082';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8082';
    }

    return 'http://127.0.0.1:8082';
  }

  static String get seguridadBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8004';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8004';
    }

    return 'http://127.0.0.1:8004';
  }

  Future<bool> registrarUsuario(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$usuarioBaseUrl/api/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }

      debugPrint('Error registro: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error cliente registro: $e');
      return false;
    }
  }

  Future<LoginResponse?> loginUsuario(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$usuarioBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LoginResponse.fromJson(data);
      }

      debugPrint('Error login: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error cliente login: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> obtenerUsuarioActual(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$usuarioBaseUrl/api/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      debugPrint('Error usuario actual: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error cliente usuario actual: $e');
      return null;
    }
  }

  Future<List<dynamic>> descubrirUsuarios({
    required int excludeId,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$usuarioBaseUrl/api/users/discover?excludeId=$excludeId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception('Error al descubrir usuarios: ${response.statusCode} ${response.body}');
  }

  Future<bool> enviarInteraccion({
    required int usuarioOrigenId,
    required int usuarioDestinoId,
    required String tipo,
  }) async {
    final response = await http.post(
      Uri.parse('$matchBaseUrl/api/v1/interacciones'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuarioOrigenId': usuarioOrigenId,
        'usuarioDestinoId': usuarioDestinoId,
        'tipo': tipo,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hayMatch'] == true;
    }

    throw Exception('Error interacción: ${response.statusCode} ${response.body}');
  }

  Future<List<dynamic>> obtenerSalasUsuario({
    required int usuarioId,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$comunicacionBaseUrl/api/v1/chat/salas/user/$usuarioId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception('Error salas: ${response.statusCode} ${response.body}');
  }

  Future<List<dynamic>> obtenerMensajes({
    required int salaId,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$comunicacionBaseUrl/api/v1/chat/salas/$salaId/mensajes?page=0&size=50'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      if (data is Map<String, dynamic> && data['content'] is List) {
        return data['content'] as List<dynamic>;
      }

      return [];
    }

    throw Exception('Error mensajes: ${response.statusCode} ${response.body}');
  }

  Future<bool> enviarMensaje({
    required int salaId,
    required int remitenteId,
    required String contenido,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$comunicacionBaseUrl/api/v1/chat/salas/$salaId/mensajes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'remitenteId': remitenteId,
        'contenido': contenido,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    }

    debugPrint('Error enviar mensaje: ${response.statusCode}');
    debugPrint('Respuesta backend: ${response.body}');
    return false;
  }

Future<bool> bloquearUsuario({
  required int idUsuarioOrigen,
  required int idUsuarioBloqueado,
}) async {
  try {
    final response = await http
        .post(
          Uri.parse('$seguridadBaseUrl/api/safety/bloquear'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idUsuarioOrigen': idUsuarioOrigen,
            'idUsuarioBloqueado': idUsuarioBloqueado,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    }

    debugPrint('Error bloquear usuario: ${response.statusCode}');
    debugPrint('Respuesta backend: ${response.body}');
    return false;
  } catch (e) {
    debugPrint('Error cliente bloquear usuario: $e');
    return false;
  }
}

  Future<List<int>> obtenerUsuariosInteractuados({
  required int usuarioId,
}) async {
  final response = await http.get(
    Uri.parse('$matchBaseUrl/api/v1/interacciones/usuarios-interactuados/$usuarioId'),
    headers: {
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data is List) {
      return data
          .map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .toList();
    }

    return [];
  }

  throw Exception(
    'Error al obtener usuarios interactuados: ${response.statusCode}',
  );
}

}