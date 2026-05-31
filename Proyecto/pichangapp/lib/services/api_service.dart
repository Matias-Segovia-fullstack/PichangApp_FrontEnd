import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Usamos 10.0.2.2 porque es el "localhost" del emulador de Android.
  // Así el celular virtual se puede conectar al backend en tu computadora.
  static const String baseUrl = 'http://10.0.2.2:8001/api';

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
