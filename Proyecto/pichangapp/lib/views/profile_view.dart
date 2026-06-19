import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/media_service.dart';
import 'login_view.dart';
import 'edit_profile_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ApiService _apiService = ApiService();
  final MediaService _mediaService = MediaService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _usuario;
  String? _fotoPerfilUrl;

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
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _storage.delete(key: 'jwt_token');
              await _storage.delete(key: 'user_id');
              await _storage.delete(key: 'username');

              if (!mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _subirFotoPerfil() async {
    final userId = _usuario?['id']?.toString();
    if (userId == null) return;

    try {
      final url = await _mediaService.pickCompressAndUploadImage(
        bucket: 'user-media',
        folder: 'perfil_$userId',
      );

      if (url != null && url.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _fotoPerfilUrl = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _texto(dynamic value) {
    if (value == null) return 'No definido';
    return value.toString();
  }

  Widget _infoCard({
    required String titulo,
    required String valor,
    required IconData icon,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.blue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor ?? Colors.blue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Foto de perfil y nombre
          Center(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.blue[100],
                        backgroundImage: _fotoPerfilUrl != null
                            ? NetworkImage(_fotoPerfilUrl!)
                            : null,
                        child: _fotoPerfilUrl == null
                            ? Icon(
                                Icons.person,
                                size: 64,
                                color: Colors.blue[400],
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _subirFotoPerfil,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${_texto(usuario['nombre'])} ${_texto(usuario['apellido'])}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${_texto(usuario['username'])}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!, width: 1),
                  ),
                  child: Text(
                    usuario['enabled'] == true ? 'Cuenta activa' : 'Cuenta inactiva',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Información básica
          _sectionTitle('Información de Cuenta'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                _infoCard(
                  titulo: 'Email',
                  valor: _texto(usuario['email']),
                  icon: Icons.email_outlined,
                  iconColor: Colors.blue,
                ),
                Divider(height: 12, color: Colors.grey[200]),
                _infoCard(
                  titulo: 'ID Usuario',
                  valor: '#${_texto(usuario['id'])}',
                  icon: Icons.badge_outlined,
                  iconColor: Colors.indigo,
                ),
              ],
            ),
          ),

          // Información deportiva
          _sectionTitle('Perfil Deportivo'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                _infoCard(
                  titulo: 'Descripción',
                  valor: profile is Map<String, dynamic>
                      ? _texto(profile['descripcion'])
                      : 'No definida',
                  icon: Icons.description_outlined,
                  iconColor: Colors.orange,
                ),
                Divider(height: 12, color: Colors.grey[200]),
                _infoCard(
                  titulo: 'Edad',
                  valor: profile is Map<String, dynamic>
                      ? '${_texto(profile['edad'])} años'
                      : 'No definida',
                  icon: Icons.cake_outlined,
                  iconColor: Colors.pink,
                ),
                Divider(height: 12, color: Colors.grey[200]),
                _infoCard(
                  titulo: 'Deporte Principal',
                  valor: profile is Map<String, dynamic>
                      ? _texto(profile['deportePrincipal'])
                      : 'No definido',
                  icon: Icons.sports_basketball_outlined,
                  iconColor: Colors.red,
                ),
                if (atributos is Map<String, dynamic>) ...[
                  Divider(height: 12, color: Colors.grey[200]),
                  _infoCard(
                    titulo: 'Altura',
                    valor: '${_texto(atributos['altura'])} cm',
                    icon: Icons.height,
                    iconColor: Colors.cyan,
                  ),
                  if (atributos['posicion'] != null) ...[
                    Divider(height: 12, color: Colors.grey[200]),
                    _infoCard(
                      titulo: 'Posición',
                      valor: _texto(atributos['posicion']),
                      icon: Icons.sports_soccer_outlined,
                      iconColor: Colors.amber,
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Botones de acción
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileView(usuarioActual: _usuario ?? {}),
                      ),
                    );

                    if (resultado == true && mounted) {
                      _cargarPerfil();
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar Perfil'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.red[300]!),
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _estadoError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No se pudo cargar el perfil',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _cargarPerfil,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar Nuevamente'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                backgroundColor: Colors.blue,
              ),
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
      body = const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    } else if (_error != null) {
      body = _estadoError();
    } else {
      body = _contenidoPerfil();
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _cargarPerfil,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: body,
    );
  }
}