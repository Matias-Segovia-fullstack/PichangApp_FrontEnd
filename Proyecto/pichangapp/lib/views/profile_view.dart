import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/media_service.dart';
import '../theme/app_theme.dart';
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

        if (usuario != null && usuario['profile'] != null) {
          _fotoPerfilUrl = usuario['profile']['fotoUrl'];
        }

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
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
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
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppTheme.danger),
            ),
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
        final token = await _storage.read(key: 'jwt_token');

        if (token != null) {
          final profileData = Map<String, dynamic>.from(
            _usuario?['profile'] ?? {},
          );

          profileData['fotoUrl'] = url;

          final success = await _apiService.actualizarPerfilUsuario(
            token: token,
            userId: userId,
            datosActualizacion: profileData,
          );

          if (!success) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Error: No se pudo guardar la foto en el servidor.',
                ),
                backgroundColor: AppTheme.danger,
              ),
            );

            return;
          }
        }

        if (!mounted) return;

        setState(() {
          _fotoPerfilUrl = url;

          if (_usuario != null) {
            _usuario!['profile'] ??= {};
            _usuario!['profile']['fotoUrl'] = url;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir foto: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  String _texto(dynamic value) {
    if (value == null) return 'No definido';
    return value.toString();
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.18),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Divider _divider() {
    return const Divider(
      height: 12,
      color: AppTheme.border,
    );
  }

  Widget _infoCard({
    required String titulo,
    required String valor,
    required IconData icon,
    Color? iconColor,
  }) {
    final color = iconColor ?? AppTheme.primarySoft;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
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
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
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
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDeporteAtributos({
    required String deporte,
    required Map<String, dynamic> atributos,
  }) {
    final children = <Widget>[];

    if (deporte.toUpperCase() == 'BASKET') {
      children.addAll([
        _infoCard(
          titulo: 'Altura',
          valor: '${_texto(atributos['altura'])} cm',
          icon: Icons.height,
          iconColor: Colors.cyan,
        ),
        if (atributos['posicion'] != null) ...[
          _divider(),
          _infoCard(
            titulo: 'Posición',
            valor: _texto(atributos['posicion']),
            icon: Icons.sports_soccer_outlined,
            iconColor: Colors.amber,
          ),
        ],
      ]);
    } else if (deporte.toUpperCase() == 'BOXEO') {
      children.addAll([
        _infoCard(
          titulo: 'Peso',
          valor: '${_texto(atributos['peso'])} kg',
          icon: Icons.monitor_weight,
          iconColor: Colors.purple,
        ),
        if (atributos['guardia'] != null) ...[
          _divider(),
          _infoCard(
            titulo: 'Guardia',
            valor: _texto(atributos['guardia']),
            icon: Icons.sports_martial_arts_outlined,
            iconColor: Colors.deepOrange,
          ),
        ],
      ]);
    }

    return Column(children: children);
  }

  Widget _contenidoPerfil() {
    final usuario = _usuario;

    if (usuario == null) {
      return const Center(
        child: Text(
          'No se encontró información del usuario.',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
      );
    }

    final profile = usuario['profile'];

    final deporte = profile is Map<String, dynamic>
        ? profile['deportePrincipal']
        : null;

    final atributos = profile is Map<String, dynamic>
        ? profile['atributosDeportivos']
        : null;

    return RefreshIndicator(
      onRefresh: _cargarPerfil,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
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
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: AppTheme.surfaceAlt,
                        backgroundImage: _fotoPerfilUrl != null
                            ? NetworkImage(_fotoPerfilUrl!)
                            : null,
                        child: _fotoPerfilUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 64,
                                color: AppTheme.primarySoft,
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
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.surface,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.4),
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
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${_texto(usuario['username'])}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.success.withOpacity(0.45),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    usuario['enabled'] == true
                        ? 'Cuenta activa'
                        : 'Cuenta inactiva',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _sectionTitle('Información de Cuenta'),
          Container(
            decoration: _panelDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                _infoCard(
                  titulo: 'Email',
                  valor: _texto(usuario['email']),
                  icon: Icons.email_outlined,
                  iconColor: AppTheme.primarySoft,
                ),
                _divider(),
                _infoCard(
                  titulo: 'ID Usuario',
                  valor: '#${_texto(usuario['id'])}',
                  icon: Icons.badge_outlined,
                  iconColor: Colors.indigoAccent,
                ),
              ],
            ),
          ),

          _sectionTitle('Perfil Deportivo'),
          Container(
            decoration: _panelDecoration(),
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
                _divider(),
                _infoCard(
                  titulo: 'Edad',
                  valor: profile is Map<String, dynamic>
                      ? '${_texto(profile['edad'])} años'
                      : 'No definida',
                  icon: Icons.cake_outlined,
                  iconColor: Colors.pink,
                ),
                _divider(),
                _infoCard(
                  titulo: 'Deporte Principal',
                  valor: deporte?.toString() ?? 'No definido',
                  icon: Icons.sports_basketball_outlined,
                  iconColor: Colors.redAccent,
                ),
                if (atributos is Map<String, dynamic> && deporte != null) ...[
                  _divider(),
                  _buildDeporteAtributos(
                    deporte: deporte.toString(),
                    atributos: atributos,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileView(
                          usuarioActual: _usuario ?? {},
                        ),
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
                    backgroundColor: AppTheme.primary,
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
                    side: const BorderSide(color: AppTheme.danger),
                    foregroundColor: AppTheme.danger,
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
                color: AppTheme.danger.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.danger,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No se pudo cargar el perfil',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _cargarPerfil,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar Nuevamente'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                backgroundColor: AppTheme.primary,
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
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primarySoft),
        ),
      );
    } else if (_error != null) {
      body = _estadoError();
    } else {
      body = _contenidoPerfil();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _cargarPerfil,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: body,
    );
  }
}