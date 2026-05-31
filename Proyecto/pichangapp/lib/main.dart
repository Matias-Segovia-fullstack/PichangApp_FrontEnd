import 'package:flutter/material.dart';
import 'views/login_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Quita la etiqueta roja de "DEBUG"
      title: 'SportMatch',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginView(), // Llama a nuestra vista como pantalla inicial
    );
  }
}