import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'match_sport_view.dart';
import 'chats_view.dart';
import 'notifications_view.dart';
import 'profile_view.dart';
import 'login_view.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key});

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  int _selectedIndex = 0;
  int _notificacionesNoLeidas = 0;
  int _notificacionesVersion = 0;

  bool _validandoSesion = false;
  bool _cargandoContador = false;

  Timer? _notificacionesTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validarSesionSiCorresponde();
      _cargarContadorNotificaciones();
    });

    _notificacionesTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _cargarContadorNotificaciones(),
    );
  }

  @override
  void dispose() {
    _notificacionesTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validarSesionSiCorresponde();
      _cargarContadorNotificaciones();

      if (_selectedIndex == 2 && mounted) {
        setState(() {
          _notificacionesVersion++;
        });
      }
    }
  }

  Future<void> _validarSesionSiCorresponde() async {
    if (_validandoSesion) return;

    _validandoSesion = true;

    try {
      final token = await _storage.read(key: 'jwt_token');

      if (token == null || token.isEmpty) {
        await _forzarLogin();
        return;
      }

      final estadoToken = await _apiService.tokenSigueVigente(token);

      if (estadoToken == false) {
        await _storage.delete(key: 'jwt_token');
        await _storage.delete(key: 'user_id');
        await _storage.delete(key: 'username');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu sesión expiró. Vuelve a iniciar sesión.'),
          ),
        );

        await _forzarLogin();
      }
    } finally {
      _validandoSesion = false;
    }
  }

  Future<void> _forzarLogin() async {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  bool _estaLeida(dynamic valor) {
    if (valor is bool) return valor;
    if (valor is String) return valor.toLowerCase() == 'true';
    if (valor is int) return valor == 1;
    return false;
  }

  Future<void> _cargarContadorNotificaciones() async {
    if (_cargandoContador) return;

    _cargandoContador = true;

    try {
      final userIdString = await _storage.read(key: 'user_id');

      if (userIdString == null || userIdString.isEmpty) {
        return;
      }

      final usuarioId = int.tryParse(userIdString);

      if (usuarioId == null) {
        return;
      }

      final data = await _apiService.obtenerNotificacionesUsuario(
        usuarioId: usuarioId,
      );

      final noLeidas = data.where((item) {
        if (item is Map) {
          return !_estaLeida(item['leida']);
        }
        return false;
      }).length;

      if (!mounted) return;

      if (_notificacionesNoLeidas != noLeidas) {
        setState(() {
          _notificacionesNoLeidas = noLeidas;
          _notificacionesVersion++;
        });
      }
    } catch (e) {
      debugPrint('No se pudo cargar contador de notificaciones: $e');
    } finally {
      _cargandoContador = false;
    }
  }

  Widget _iconoConBadge(IconData icon) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (_notificacionesNoLeidas > 0)
          Positioned(
            right: -9,
            top: -7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              decoration: BoxDecoration(
                color: AppTheme.danger,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.surface, width: 1.5),
              ),
              child: Text(
                _notificacionesNoLeidas > 99
                    ? '99+'
                    : _notificacionesNoLeidas.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
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

      if (index == 2) {
        _notificacionesVersion++;
      }
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
        refreshVersion: _notificacionesVersion,
        onNotificationsChanged: _cargarContadorNotificaciones,
      ),
      const ProfileView(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primarySoft,
        unselectedItemColor: AppTheme.textSecondary,
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