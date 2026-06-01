import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'views/home_tabs.dart';
import 'views/login_view.dart';

void main() {
  runApp(const PichangApp());
}

class PichangApp extends StatelessWidget {
  const PichangApp({super.key});

  Future<bool> checkLoginStatus() async {
    const storage = FlutterSecureStorage();

    final token = await storage.read(key: 'jwt_token');
    final userId = await storage.read(key: 'user_id');

    return token != null && token.isNotEmpty && userId != null && userId.isNotEmpty;
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
              body: Center(
                child: CircularProgressIndicator(),
              ),
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