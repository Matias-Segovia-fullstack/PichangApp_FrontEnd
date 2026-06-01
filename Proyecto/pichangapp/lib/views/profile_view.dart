import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import 'login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _usuario;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('No existe sesión activa.');
      }

      final usuario = await _apiService.obtenerUsuarioActual(token);

      if (!mounted) return;

      setState(() {
        _usuario = usuario;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'username');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  String _texto(dynamic value) {
    if (value == null) return 'No definido';
    return value.toString();
  }

  Widget _fila(String titulo, String valor) {
    return ListTile(
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(valor),
    );
  }

  Widget _contenidoPerfil() {
    final usuario = _usuario;

    if (usuario == null) {
      return const Center(
        child: Text('No se encontró información del usuario.'),
      );
    }

    final profile = usuario['profile'];
    final atributos = profile is Map<String, dynamic>
        ? profile['atributosDeportivos']
        : null;

    return RefreshIndicator(
      onRefresh: _cargarPerfil,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: Colors.blue[100],
            child: const Icon(
              Icons.person,
              size: 56,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_texto(usuario['nombre'])} ${_texto(usuario['apellido'])}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '@${_texto(usuario['username'])}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                _fila('ID', _texto(usuario['id'])),
                _fila('Email', _texto(usuario['email'])),
                _fila('Cuenta activa', _texto(usuario['enabled'])),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _fila(
                  'Descripción deportiva',
                  profile is Map<String, dynamic>
                      ? _texto(profile['descripcion'])
                      : 'No definida',
                ),
                _fila(
                  'Edad',
                  profile is Map<String, dynamic>
                      ? _texto(profile['edad'])
                      : 'No definida',
                ),
                _fila(
                  'Deporte principal',
                  profile is Map<String, dynamic>
                      ? _texto(profile['deportePrincipal'])
                      : 'No definido',
                ),
                _fila(
                  'Altura',
                  atributos is Map<String, dynamic>
                      ? '${_texto(atributos['altura'])} cm'
                      : 'No definida',
                ),
                _fila(
                  'Posición',
                  atributos is Map<String, dynamic>
                      ? _texto(atributos['posicion'])
                      : 'No definida',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _estadoError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 70, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar el perfil',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarPerfil,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = _estadoError();
    } else {
      body = _contenidoPerfil();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            onPressed: _cargarPerfil,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}