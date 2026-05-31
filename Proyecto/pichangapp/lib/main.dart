import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'views/login_view.dart';
import 'views/home_tabs.dart';

void main() {
  runApp(const PichangApp());
}

class PichangApp extends StatelessWidget {
  const PichangApp({super.key});

  // Función del Portero: Revisa la bóveda del celular
  Future<bool> checkLoginStatus() async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'jwt_token');
    
    // Si el token existe, retorna true (sesión activa)
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PichangApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // FutureBuilder espera a que el "Portero" termine de revisar
      home: FutureBuilder<bool>(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          // Mientras busca en la bóveda, muestra un símbolo de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Si encontró la pulsera (token == true), entra directo al club (HomeTabs)
          if (snapshot.data == true) {
            return const HomeTabs();
          } 
          // Si no hay pulsera o fue borrada, va a la fila (LoginView)
          else {
            return const LoginView();
          }
        },
      ),
    );
  }
}