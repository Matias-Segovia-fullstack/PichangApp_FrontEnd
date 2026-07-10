import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'views/home_tabs.dart';
import 'views/login_view.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pqukomxvkdmxceywkltx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxdWtvbXh2a2RteGNleXdrbHR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAxNjY3OTAsImV4cCI6MjA5NTc0Mjc5MH0.EALqagSTlT_eGBEHc1Z48-tHEqDPigPbckWBR3SMwAQ',
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

    final estadoToken = await apiService.tokenSigueVigente(token);

    if (estadoToken == false) {
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
      title: 'MatchFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
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