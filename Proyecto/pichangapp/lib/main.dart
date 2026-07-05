import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/api_service.dart';
import 'views/home_tabs.dart';
import 'views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pqukomxvkdmxceywkltx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJIUzI1NiIsInJlZiI6InBxdWtvbXh2a2RteGNleXdrbHR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAxNjY3OTAsImV4cCI6MjA5NTc0Mjc5MH0.EALqagSTlT_eGBEHc1Z48-tHEqDPigPbckWBR3SMwAQ',
  );

  runApp(const PichangApp());
}

class PichangApp extends StatelessWidget {
  const PichangApp({super.key});

  Future<bool> checkLoginStatus() async {
    const storage = FlutterSecureStorage();
    final apiService = ApiService();

    final token = await storage.read(key: 'jwt_token');
    final userId = await storage.read(key: 'user_id');

    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      return false;
    }

    final usuario = await apiService.obtenerUsuarioActual(token);

    if (usuario == null) {
      await storage.delete(key: 'jwt_token');
      await storage.delete(key: 'user_id');
      await storage.delete(key: 'username');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PichangApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.data == true) {
            return const HomeTabs();
          }

          return const LoginView();
        },
      ),
    );
  }
}