import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
<<<<<<< HEAD
  // Usamos 10.0.2.2 porque es el "localhost" del emulador de Android.
  // Así el celular virtual se puede conectar al backend en tu computadora.
=======
  // Detecta automáticamente en qué entorno estás ejecutando la app y asigna la IP correcta.
  // Así ningún colaborador tendrá problemas si usa Web, Android, Windows o iOS.
>>>>>>> 90df64d199223ec33d13c29e63e1631f07af081c
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8001/api'; // Chrome / Web
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001/api';  // Emulador Android
    } else {
      return 'http://127.0.0.1:8001/api'; // Windows / iOS / Mac
    }
  }
<<<<<<< HEAD

  static String get loginUrl => baseUrl.replaceAll('/api', '/login');
=======
>>>>>>> 90df64d199223ec33d13c29e63e1631f07af081c

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
}