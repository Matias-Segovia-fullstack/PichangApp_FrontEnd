import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/solicitud_squad.dart';
import '../models/squad.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SquadRequestsView extends StatefulWidget {
  final Squad squad;
  final int adminId;

  const SquadRequestsView({
    super.key,
    required this.squad,
    required this.adminId,
  });

  @override
  State<SquadRequestsView> createState() => _SquadRequestsViewState();
}

class _SquadRequestsViewState extends State<SquadRequestsView> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;
  List<SolicitudSquad> _solicitudes = [];

  final Map<int, String> _nombresUsuarios = {};

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  String _nombreVisibleUsuario(int usuarioId) {
    return _nombresUsuarios[usuarioId] ?? 'Usuario #$usuarioId';
  }

  String _resolverNombreUsuario(Map<String, dynamic>? data, int usuarioId) {
    if (data == null) {
      return 'Usuario #$usuarioId';
    }

    final username = data['username']?.toString().trim() ??
        data['nombreUsuario']?.toString().trim() ??
        data['userName']?.toString().trim();

    if (username != null && username.isNotEmpty) {
      return username.startsWith('@') ? username : '@$username';
    }

    final nombre = data['nombre']?.toString().trim() ?? '';
    final apellido = data['apellido']?.toString().trim() ?? '';
    final nombreCompleto = '$nombre $apellido'.trim();

    if (nombreCompleto.isNotEmpty) {
      return nombreCompleto;
    }

    return 'Usuario #$usuarioId';
  }

  Future<void> _cargarNombreUsuario(int usuarioId) async {
    if (_nombresUsuarios.containsKey(usuarioId)) return;

    try {
      final token = await _storage.read(key: 'jwt_token');

      if (token == null || token.isEmpty) {
        return;
      }

      final data = await _apiService.obtenerUsuarioPorId(
        usuarioId: usuarioId,
        token: token,
      );

      final nombre = _resolverNombreUsuario(data, usuarioId);

      if (!mounted) return;

      setState(() {
        _nombresUsuarios[usuarioId] = nombre;
      });
    } catch (e) {
      debugPrint('No se pudo cargar nombre de usuario $usuarioId: $e');
    }
  }

  Future<void> _cargarNombresUsuarios(Iterable<int> usuariosIds) async {
    final idsUnicos = usuariosIds.toSet();

    for (final usuarioId in idsUnicos) {
      await _cargarNombreUsuario(usuarioId);
    }
  }

  Future<void> _cargarSolicitudes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.listarSolicitudesSquad(
        squadId: widget.squad.id,
        adminId: widget.adminId,
      );

      final solicitudes = data
          .whereType<Map<String, dynamic>>()
          .map(SolicitudSquad.fromJson)
          .toList();

      await _cargarNombresUsuarios(
        solicitudes.map((solicitud) => solicitud.usuarioId),
      );

      if (!mounted) return;

      setState(() {
        _solicitudes = solicitudes;
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

  Future<void> _aceptar(SolicitudSquad solicitud) async {
    if (_isActionLoading) return;

    setState(() {
      _isActionLoading = true;
    });

    final ok = await _apiService.aceptarSolicitudSquad(
      solicitudId: solicitud.id,
      adminId: widget.adminId,
    );

    if (!mounted) return;

    setState(() {
      _isActionLoading = false;
    });

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_nombreVisibleUsuario(solicitud.usuarioId)} fue agregado al squad.',
          ),
        ),
      );

      await _cargarSolicitudes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo aceptar la solicitud.'),
        ),
      );
    }
  }

  Future<void> _rechazar(SolicitudSquad solicitud) async {
    if (_isActionLoading) return;

    setState(() {
      _isActionLoading = true;
    });

    final ok = await _apiService.rechazarSolicitudSquad(
      solicitudId: solicitud.id,
      adminId: widget.adminId,
    );

    if (!mounted) return;

    setState(() {
      _isActionLoading = false;
    });

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solicitud de ${_nombreVisibleUsuario(solicitud.usuarioId)} rechazada.',
          ),
        ),
      );

      await _cargarSolicitudes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo rechazar la solicitud.'),
        ),
      );
    }
  }

  Widget _emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_disabled,
              size: 72,
              color: AppTheme.primarySoft,
            ),
            SizedBox(height: 18),
            Text(
              'No hay solicitudes pendientes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cuando alguien solicite entrar a tu squad aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _solicitudCard(SolicitudSquad solicitud) {
    final nombre = _nombreVisibleUsuario(solicitud.usuarioId);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombre,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Usuario #${solicitud.usuarioId} quiere entrar a tu squad.',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isActionLoading ? null : () => _rechazar(solicitud),
                  icon: const Icon(Icons.close),
                  label: const Text('Rechazar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isActionLoading ? null : () => _aceptar(solicitud),
                  icon: const Icon(Icons.check),
                  label: const Text('Aceptar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.success,
                  ),
                ),
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
            'Error al cargar solicitudes:\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    if (_solicitudes.isEmpty) {
      return _emptyState();
    }

    return RefreshIndicator(
      onRefresh: _cargarSolicitudes,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _solicitudes.length,
        itemBuilder: (context, index) {
          return _solicitudCard(_solicitudes[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        title: Text(
          'Solicitudes · ${widget.squad.nombre}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _cargarSolicitudes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _contenido(),
    );
  }
}