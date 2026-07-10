import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PublicUserProfileView extends StatefulWidget {
  final int usuarioId;

  const PublicUserProfileView({
    super.key,
    required this.usuarioId,
  });

  @override
  State<PublicUserProfileView> createState() => _PublicUserProfileViewState();
}

class _PublicUserProfileViewState extends State<PublicUserProfileView> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _usuario;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('No se pudo validar la sesión.');
      }

      final data = await _apiService.obtenerUsuarioPorId(
        usuarioId: widget.usuarioId,
        token: token,
      );

      if (data == null) {
        throw Exception('No se pudo cargar el perfil del usuario.');
      }

      if (!mounted) return;

      setState(() {
        _usuario = data;
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

  String _valorTexto(List<String> keys, {String fallback = 'No disponible'}) {
    final data = _usuario;

    if (data == null) return fallback;

    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }

  int? _valorInt(List<String> keys) {
    final data = _usuario;

    if (data == null) return null;

    for (final key in keys) {
      final value = data[key];

      if (value is int) return value;
      if (value is num) return value.toInt();

      final parsed = int.tryParse(value?.toString() ?? '');

      if (parsed != null) return parsed;
    }

    return null;
  }

  String? _fotoUrl() {
    final data = _usuario;

    if (data == null) return null;

    final value = data['fotoUrl'] ??
        data['foto_url'] ??
        data['profileImageUrl'] ??
        data['imagenPerfil'] ??
        data['avatarUrl'];

    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    return value.toString().trim();
  }

  String _username() {
    final raw = _valorTexto(
      ['username', 'nombreUsuario', 'userName'],
      fallback: '',
    );

    if (raw.isEmpty) return '@usuario${widget.usuarioId}';

    return raw.startsWith('@') ? raw : '@$raw';
  }

  String _nombrePrincipal() {
    final nombreCompleto = _valorTexto(
      ['nombreCompleto', 'fullName'],
      fallback: '',
    );

    if (nombreCompleto.isNotEmpty) {
      return nombreCompleto;
    }

    final nombre = _valorTexto(['nombre', 'name'], fallback: '');
    final apellido = _valorTexto(['apellido', 'lastName'], fallback: '');

    final completo = '$nombre $apellido'.trim();

    if (completo.isNotEmpty) {
      return completo;
    }

    return _username();
  }

  String _edadTexto() {
    final edad = _valorInt(['edad', 'age']);

    if (edad == null || edad <= 0) {
      return '';
    }

    return '$edad años';
  }

  Widget _chip({
    required IconData icon,
    required String label,
  }) {
    if (label.trim().isEmpty || label == 'No disponible') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.primarySoft.withOpacity(0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: AppTheme.primarySoft,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    if (value.trim().isEmpty || value == 'No disponible') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primarySoft,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenidoPerfil() {
    final foto = _fotoUrl();
    final nombre = _nombrePrincipal();
    final edad = _edadTexto();
    final titulo = edad.isEmpty ? nombre : '$nombre, $edad';

    final deporte = _valorTexto(
      ['deporteFavorito', 'deporte', 'sport'],
      fallback: '',
    );

    final posicion = _valorTexto(
      ['posicion', 'position'],
      fallback: '',
    );

    final sexo = _valorTexto(
      ['sexo', 'gender'],
      fallback: '',
    );

    final altura = _valorInt(['altura', 'heightCm']);
    final bio = _valorTexto(
      ['bio', 'biografia', 'descripcion', 'description'],
      fallback: '',
    );

    final nivel = _valorTexto(
      ['nivel', 'nivelJuego', 'skillLevel'],
      fallback: '',
    );

    final ciudad = _valorTexto(
      ['ciudad', 'comuna', 'ubicacion', 'location'],
      fallback: '',
    );

    return RefreshIndicator(
      onRefresh: _cargarUsuario,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 58,
                  backgroundColor: AppTheme.primary.withOpacity(0.18),
                  backgroundImage: foto != null ? NetworkImage(foto) : null,
                  child: foto == null
                      ? const Icon(
                          Icons.person,
                          size: 58,
                          color: AppTheme.primarySoft,
                        )
                      : null,
                ),
                const SizedBox(height: 18),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _username(),
                  style: const TextStyle(
                    color: AppTheme.primarySoft,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _chip(icon: Icons.sports_basketball, label: deporte),
                    _chip(icon: Icons.sports, label: posicion),
                    _chip(icon: Icons.person, label: sexo),
                    if (altura != null && altura > 0)
                      _chip(icon: Icons.height, label: '$altura cm'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _infoTile(
            icon: Icons.sports_basketball,
            title: 'Deporte',
            value: deporte,
          ),
          _infoTile(
            icon: Icons.sports,
            title: 'Posición',
            value: posicion,
          ),
          _infoTile(
            icon: Icons.trending_up,
            title: 'Nivel',
            value: nivel,
          ),
          _infoTile(
            icon: Icons.location_on,
            title: 'Ubicación',
            value: ciudad,
          ),
        ],
      ),
    );
  }

  Widget _contenido() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primarySoft,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error al cargar perfil:\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return _contenidoPerfil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        title: const Text(
          'Perfil',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _cargarUsuario,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _contenido(),
    );
  }
}