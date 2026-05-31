import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Detecta automáticamente en qué entorno estás ejecutando la app y asigna la IP correcta.
  // Así ningún colaborador tendrá problemas si usa Web, Android, Windows o iOS.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8001/api'; // Chrome / Web
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001/api';  // Emulador Android
    } else {
      return 'http://127.0.0.1:8001/api'; // Windows / iOS / Mac
    }
  }

  /// Realiza la petición POST al backend para registrar un nuevo usuario.
  /// Retorna [true] si la cuenta se creó exitosamente (código 201 o 200).
  /// En caso de error (red o validación), captura la excepción y retorna [false].
  Future<bool> registrarUsuario(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        // Manejo de errores de validación (ej. 400 Bad Request)
        return false;
      }
    } on SocketException {
      // Error de conectividad (backend apagado o red inaccesible)
      return false;
    } catch (e) {
      // Otros errores no previstos
      return false;
    }
  }
}
