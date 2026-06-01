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
      Map<String, dynamic>? data = await _apiService.loginUsuario(username, password);
      
      // 2. Si el login fue exitoso, guardamos el token y el userId bajo llave
      if (data != null && data['token'] != null) {
        String token = data['token'];
        String userId = data['userId'].toString();
        
        await _storage.write(key: 'jwt_token', value: token);
        await _storage.write(key: 'user_id', value: userId);
        
        return token;
      }
    }
    return null;
  }

  // 3. Nueva función para cuando el usuario quiera cerrar sesión
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_id');
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