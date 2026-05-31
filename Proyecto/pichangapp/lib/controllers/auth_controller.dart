import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final rutController = TextEditingController();
  final nameController = TextEditingController();
  final apellidoController = TextEditingController();
  final usernameController = TextEditingController();

  final ApiService _apiService = ApiService();
  
  // 1. Instanciamos la bóveda de seguridad
  final _storage = const FlutterSecureStorage();

  Future<bool> registrar() async {
    if (emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        nameController.text.isNotEmpty &&
        apellidoController.text.isNotEmpty &&
        usernameController.text.isNotEmpty) {
      Map<String, dynamic> userData = {
        "nombre": nameController.text.trim(),
        "apellido": apellidoController.text.trim(),
        "username": usernameController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text,
      };

      bool exito = await _apiService.registrarUsuario(userData);
      return exito;
    }
    return false;
  }

  Future<String?> login() async {
    String username = usernameController.text.trim();
    String password = passwordController.text;

    if (username.isNotEmpty && password.isNotEmpty) {
      String? token = await _apiService.loginUsuario(username, password);
      
      // 2. Si el login fue exitoso, guardamos el token bajo llave
      if (token != null) {
        await _storage.write(key: 'jwt_token', value: token);
      }
      
      return token; 
    }
    return null;
  }

  // 3. Nueva función para cuando el usuario quiera cerrar sesión
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    rutController.dispose();
    nameController.dispose();
    apellidoController.dispose();
    usernameController.dispose();
  }
}