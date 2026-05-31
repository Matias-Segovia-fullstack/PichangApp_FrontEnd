import 'package:flutter/material.dart';

class AuthController {
  // Controladores para capturar el texto de los inputs
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final rutController = TextEditingController();
  final nameController = TextEditingController();
  
  // Para mostrar el género calculado automáticamente
  String generoCalculado = "Escribe tu RUT...";

  // Función para validar RUT y calcular género de forma simulada
  void procesarRut(String rut) {
    // Limpiar el rut de puntos y guiones
    String limpio = rut.replaceAll('.', '').replaceAll('-', '').trim();
    if (limpio.length < 2) {
      generoCalculado = "RUT Inválido";
      return;
    }

    // Lógica simulada de negocio: Tomamos el penúltimo dígito para definir género
    // En Chile, históricamente los números de serie pares/impares ayudaban a esto en registros,
    // aquí dejamos la lógica orientada para que el backend la procese real después.
    String penultimoDigito = limpio.substring(limpio.length - 2, limpio.length - 1);
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

  // Simulación de Login con JWT futuro
  bool simularLogin() {
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      // Aquí el día de mañana guardaremos el JWT en el Storage local
      return true; 
    }
    return false;
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    rutController.dispose();
    nameController.dispose();
  }
}