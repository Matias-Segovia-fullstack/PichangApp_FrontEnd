import 'package:flutter/material.dart';
import '../constants/deportes.dart';
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

  Map<String, dynamic>? get _profile {
    final data = _usuario;

    if (data == null) return null;

    final profile = data['profile'];

    if (profile is Map<String, dynamic>) {
      return profile;
    }

    if (profile is Map) {
      return Map<String, dynamic>.from(profile);
    }

    return null;
  }

  Map<String, dynamic>? get _atributosDeportivos {
    final profile = _profile;

    if (profile == null) return null;

    final atributos = profile['atributosDeportivos'];

    if (atributos is Map<String, dynamic>) {
      return atributos;
    }

    if (atributos is Map) {
      return Map<String, dynamic>.from(atributos);
    }

    return null;
  }

  dynamic _valorRaw(List<String> keys) {
    final data = _usuario;
    final profile = _profile;
    final atributos = _atributosDeportivos;

    for (final key in keys) {
      final value = data?[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }

    for (final key in keys) {
      final value = profile?[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }

    for (final key in keys) {
      final value = atributos?[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  String _valorTexto(
    List<String> keys, {
    String fallback = 'No disponible',
  }) {
    final value = _valorRaw(keys);

    if (value == null) return fallback;

    final texto = value.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  int? _valorInt(List<String> keys) {
    final value = _valorRaw(keys);

    if (value == null) return null;

    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  String? _fotoUrl() {
    final value = _valorRaw([
      'fotoUrl',
      'foto_url',
      'profileImageUrl',
      'imagenPerfil',
      'avatarUrl',
      'foto',
    ]);

    if (value == null) return null;

    final texto = value.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    return texto;
  }

  String _username() {
    final username = _valorTexto(
      ['username', 'nombreUsuario', 'userName'],
      fallback: '',
    );

    if (username.isEmpty) {
      return '@usuario${widget.usuarioId}';
    }

    return username.startsWith('@') ? username : '@$username';
  }

  String _nombrePrincipal() {
    final nombreCompleto = _valorTexto(
      ['nombreCompleto', 'fullName'],
      fallback: '',
    );

    if (nombreCompleto.isNotEmpty) {
      return nombreCompleto;
    }

    final nombre = _valorTexto(
      ['nombre', 'name'],
      fallback: '',
    );

    final apellido = _valorTexto(
      ['apellido', 'lastName'],
      fallback: '',
    );

    final completo = '$nombre $apellido'.trim();

    if (completo.isNotEmpty) {
      return completo;
    }

    return _username();
  }

  String _edadTexto() {
    final edad = _valorInt(['edad', 'age']);

    if (edad == null || edad <= 0) {
      return 'No disponible';
    }

    return '$edad años';
  }

  String _alturaTexto() {
    final altura = _valorInt(['altura', 'heightCm', 'estatura']);

    if (altura == null || altura <= 0) {
      return 'No disponible';
    }

    return '$altura cm';
  }

  String _pesoTexto() {
    final peso = _valorInt(['peso', 'weightKg']);

    if (peso == null || peso <= 0) {
      return 'No disponible';
    }

    return '$peso kg';
  }

  Widget _seccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Text(
        titulo,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _infoCard({
    required List<Widget> children,
  }) {
    final visibles = children
        .where((child) => child.runtimeType != SizedBox)
        .toList();

    if (visibles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool showDivider = true,
  }) {
    if (value.trim().isEmpty || value == 'No disponible') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 23,
                ),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: AppTheme.border,
          ),
      ],
    );
  }

  Widget _headerPerfil() {
    final foto = _fotoUrl();
    final nombre = _nombrePrincipal();
    final username = _username();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
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
            nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            username,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.primarySoft,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenidoPerfil() {
    final descripcion = _valorTexto(
      [
        'descripcion',
        'description',
        'bio',
        'biografia',
        'presentacion',
      ],
      fallback: 'Jugador amateur de PichangApp',
    );

    final deportePrincipal = _valorTexto(
      [
        'deportePrincipal',
        'deporte',
        'sport',
        'deporteFavorito',
      ],
      fallback: 'No disponible',
    );

    final posicion = _valorTexto(
      [
        'posicion',
        'position',
        'rolDeportivo',
      ],
      fallback: 'No disponible',
    );

    final guardia = _valorTexto(
      [
        'guardia',
        'stance',
      ],
      fallback: 'No disponible',
    );

    final sexo = _valorTexto(
      [
        'sexo',
        'gender',
      ],
      fallback: 'No disponible',
    );

    return RefreshIndicator(
      onRefresh: _cargarUsuario,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _headerPerfil(),

          _seccionTitulo('Perfil Deportivo'),
          _infoCard(
            children: [
              _infoTile(
                icon: Icons.description_outlined,
                iconColor: Colors.orangeAccent,
                title: 'Descripción',
                value: descripcion,
              ),
              _infoTile(
                icon: Icons.cake_outlined,
                iconColor: Colors.pinkAccent,
                title: 'Edad',
                value: _edadTexto(),
              ),
              _infoTile(
                icon: Icons.sports_basketball,
                iconColor: Colors.redAccent,
                title: 'Deporte Principal',
                value: AppDeportes.existe(deportePrincipal)
                    ? AppDeportes.nombre(deportePrincipal)
                    : deportePrincipal,
              ),
              _infoTile(
                icon: Icons.height,
                iconColor: Colors.cyanAccent,
                title: 'Altura',
                value: _alturaTexto(),
              ),
              _infoTile(
                icon: Icons.sports_soccer,
                iconColor: Colors.amberAccent,
                title: 'Posición',
                value: posicion,
              ),
              _infoTile(
                icon: Icons.monitor_weight_outlined,
                iconColor: Colors.deepOrangeAccent,
                title: 'Peso',
                value: _pesoTexto(),
              ),
              _infoTile(
                icon: Icons.sports_mma,
                iconColor: Colors.lightGreenAccent,
                title: 'Guardia',
                value: guardia,
              ),
              _infoTile(
                icon: Icons.person_outline,
                iconColor: Colors.purpleAccent,
                title: 'Sexo',
                value: sexo,
                showDivider: false,
              ),
            ],
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