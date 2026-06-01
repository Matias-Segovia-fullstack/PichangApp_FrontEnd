import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/login_response.dart';
import '../services/api_service.dart';

class AuthController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final rutController = TextEditingController();
  final nameController = TextEditingController();
  final apellidoController = TextEditingController();
  final usernameController = TextEditingController();

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> registrar() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        nameController.text.trim().isEmpty ||
        apellidoController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty) {
      return false;
    }

    final Map<String, dynamic> userData = {
      'nombre': nameController.text.trim(),
      'apellido': apellidoController.text.trim(),
      'username': usernameController.text.trim(),
      'email': emailController.text.trim(),
      'password': passwordController.text,
      'profile': {
        'descripcion': 'Jugador amateur de PichangApp',
        'edad': 25,
        'fotoUrl': 'https://via.placeholder.com/150',
        'deportePrincipal': 'BASKET',
        'atributosDeportivos': {
          'altura': 180,
          'posicion': 'Base',
        },
      },
    };

    return _apiService.registrarUsuario(userData);
  }

  Future<LoginResponse?> login() async {
    final String username = usernameController.text.trim();
    final String password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      return null;
    }

    final LoginResponse? response = await _apiService.loginUsuario(username, password);

    if (response != null && response.token.isNotEmpty && response.userId > 0) {
      await _storage.write(key: 'jwt_token', value: response.token);
      await _storage.write(key: 'user_id', value: response.userId.toString());
      await _storage.write(key: 'username', value: response.username);
    }

    return response;
  }

  Future<String?> getToken() {
    return _storage.read(key: 'jwt_token');
  }

  Future<int?> getUserId() async {
    final value = await _storage.read(key: 'user_id');

    if (value == null) {
      return null;
    }

    return int.tryParse(value);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'username');
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