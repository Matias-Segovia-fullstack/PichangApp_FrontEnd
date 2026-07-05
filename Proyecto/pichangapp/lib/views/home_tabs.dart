import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'match_sport_view.dart';
import 'chats_view.dart';
import 'notifications_view.dart';
import 'profile_view.dart';
import 'login_view.dart';
import '../services/api_service.dart';

class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key});

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  int _selectedIndex = 0;
  int _notificacionesNoLeidas = 0;
  bool _contadorInicializado = false;

  Timer? _notificacionesTimer;
  Timer? _sesionTimer;

  @override
  void initState() {
    super.initState();
    _validarSesionActual();
    _cargarContadorNotificaciones();

    _notificacionesTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _cargarContadorNotificaciones(mostrarSnackBar: true),
    );

    _sesionTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _validarSesionActual(),
    );
  }

  @override
  void dispose() {
    _notificacionesTimer?.cancel();
    _sesionTimer?.cancel();
    super.dispose();
  }

  Future<void> _validarSesionActual() async {
    final token = await _storage.read(key: 'jwt_token');

    if (token == null || token.isEmpty) {
      await _cerrarSesionPorTokenVencido();
      return;
    }

    final usuario = await _apiService.obtenerUsuarioActual(token);

    if (usuario == null) {
      await _cerrarSesionPorTokenVencido();
    }
  }

  Future<void> _cerrarSesionPorTokenVencido() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'username');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tu sesión expiró. Vuelve a iniciar sesión.'),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  Future<void> _cargarContadorNotificaciones({
    bool mostrarSnackBar = false,
  }) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final userIdString = await _storage.read(key: 'user_id');

      if (token == null || token.isEmpty || userIdString == null) {
        return;
      }

      final userId = int.tryParse(userIdString);

      if (userId == null) {
        return;
      }

      final data = await _apiService.obtenerNotificacionesUsuario(
        usuarioId: userId,
        token: token,
      );

      final noLeidas = data.where((item) {
        if (item is Map<String, dynamic>) {
          return item['leida'] != true;
        }

        return false;
      }).length;

      if (!mounted) return;

      final habiaContador = _contadorInicializado;
      final contadorAnterior = _notificacionesNoLeidas;

      setState(() {
        _notificacionesNoLeidas = noLeidas;
        _contadorInicializado = true;
      });

      if (mostrarSnackBar &&
          habiaContador &&
          noLeidas > contadorAnterior &&
          _selectedIndex != 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              noLeidas == 1
                  ? 'Tienes 1 notificación nueva.'
                  : 'Tienes $noLeidas notificaciones nuevas.',
            ),
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),
          ),
        );
      }
    } catch (_) {
      // No bloqueamos la app por un fallo puntual del servicio de notificaciones.
    }
  }

  Widget _iconoConBadge(IconData icon) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (_notificacionesNoLeidas > 0)
          Positioned(
            right: -8,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                _notificacionesNoLeidas > 99
                    ? '99+'
                    : _notificacionesNoLeidas.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      _cargarContadorNotificaciones();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const MatchSportView(),
      const ChatsView(),
      NotificationsView(
        onNotificationsChanged: _cargarContadorNotificaciones,
      ),
      const ProfileView(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.sports_basketball),
            label: 'Descubrir',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: _iconoConBadge(Icons.notifications),
            label: 'Avisos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}