import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthController {
  // Controladores para capturar el texto de los inputs
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final rutController = TextEditingController();
  final nameController = TextEditingController();
  final apellidoController = TextEditingController();
  final usernameController = TextEditingController();

  String generoCalculado = "Escribe tu RUT...";

  void procesarRut(String rut) {
    String limpio = rut.replaceAll('.', '').replaceAll('-', '').trim();
    if (limpio.length < 2) {
      generoCalculado = "RUT Inválido";
      return;
    }

    String penultimoDigito = limpio.substring(
      limpio.length - 2,
      limpio.length - 1,
    );
    int? numero = int.tryParse(penultimoDigito);

    if (numero != null) {
      if (numero % 2 == 0) {
        generoCalculado = "Femenino";
      } else {
        generoCalculado = "Masculino";
      }
    } else {
      generoCalculado = "Escribe tu RUT...";
    }
  }

  final ApiService _apiService = ApiService();

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

  Future<bool> login() async {
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      return true;
    }
    return false;
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
