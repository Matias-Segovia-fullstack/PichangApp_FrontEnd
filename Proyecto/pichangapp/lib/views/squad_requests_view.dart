import 'package:flutter/material.dart';

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

  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;
  List<SolicitudSquad> _solicitudes = [];

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
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
        const SnackBar(
          content: Text('Solicitud aceptada. Usuario agregado al squad.'),
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
        const SnackBar(
          content: Text('Solicitud rechazada.'),
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
            'Usuario #${solicitud.usuarioId}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Quiere entrar a tu squad.',
            style: TextStyle(
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