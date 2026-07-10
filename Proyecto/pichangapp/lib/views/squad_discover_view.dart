import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../models/squad.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'create_squad_view.dart';
import 'my_squads_view.dart';

class SquadDiscoverView extends StatefulWidget {
  final VoidCallback? onCambiarAModoPersonas;

  const SquadDiscoverView({
    super.key,
    this.onCambiarAModoPersonas,
  });

  @override
  State<SquadDiscoverView> createState() => _SquadDiscoverViewState();
}

class _SquadDiscoverViewState extends State<SquadDiscoverView> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;
  List<Squad> _squads = [];

  double? _miLatitud;
  double? _miLongitud;
  double _distanciaMaxKm = 500;
  String _deporte = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargarSquads();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      final servicioHabilitado = await Geolocator.isLocationServiceEnabled();

      if (!servicioHabilitado) {
        return;
      }

      LocationPermission permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever ||
          permiso == LocationPermission.unableToDetermine) {
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _miLatitud = posicion.latitude;
      _miLongitud = posicion.longitude;
    } catch (e) {
      debugPrint('No se pudo obtener ubicación para squads: $e');
    }
  }

  Future<void> _cargarSquads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _obtenerUbicacion();

      final userIdString = await _storage.read(key: 'user_id');
      final userId = int.tryParse(userIdString ?? '');

      if (userId == null) {
        throw Exception('No se pudo identificar el usuario.');
      }

      final data = await _apiService.descubrirSquads(
        usuarioId: userId,
        deporte: _deporte,
        latitud: _miLatitud,
        longitud: _miLongitud,
        distanciaMaxKm: _distanciaMaxKm,
      );

      final squads = data
          .whereType<Map<String, dynamic>>()
          .map(Squad.fromJson)
          .toList();

      if (!mounted) return;

      setState(() {
        _squads = squads;
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

  Future<void> _solicitarEntrada(Squad squad) async {
    if (_isActionLoading) return;

    setState(() {
      _isActionLoading = true;
    });

    final userIdString = await _storage.read(key: 'user_id');
    final userId = int.tryParse(userIdString ?? '');

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        _isActionLoading = false;
      });

      return;
    }

    final ok = await _apiService.solicitarEntradaSquad(
      squadId: squad.id,
      usuarioId: userId,
    );

    if (!mounted) return;

    setState(() {
      _isActionLoading = false;
    });

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud enviada al administrador del squad.'),
        ),
      );

      await _cargarSquads();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar la solicitud.'),
        ),
      );
    }
  }

  Future<void> _abrirCrearSquad() async {
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateSquadView(),
      ),
    );

    if (creado == true && mounted) {
      _cargarSquads();
    }
  }

  Future<void> _abrirMisSquads() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MySquadsView(),
      ),
    );

    if (mounted) {
      _cargarSquads();
    }
  }

  void _abrirFiltros() {
    double distanciaTemporal = _distanciaMaxKm;
    String deporteTemporal = _deporte;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Filtros de Squads',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      value: deporteTemporal,
                      dropdownColor: AppTheme.surface,
                      decoration: InputDecoration(
                        labelText: 'Deporte',
                        labelStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                        DropdownMenuItem(value: 'BASKET', child: Text('Basket')),
                        DropdownMenuItem(value: 'BOXEO', child: Text('Boxeo')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          deporteTemporal = value;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Distancia máxima: ${distanciaTemporal.round()} km',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: distanciaTemporal,
                      min: 1,
                      max: 500,
                      divisions: 499,
                      label: '${distanciaTemporal.round()} km',
                      onChanged: (value) {
                        setDialogState(() {
                          distanciaTemporal = value.roundToDouble();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _deporte = deporteTemporal;
                          _distanciaMaxKm = distanciaTemporal;
                        });

                        Navigator.pop(context);
                        _cargarSquads();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Aplicar filtros'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.groups_2_outlined,
              size: 72,
              color: AppTheme.primarySoft,
            ),
            const SizedBox(height: 18),
            const Text(
              'No hay squads disponibles',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea uno o cambia los filtros para encontrar grupos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _abrirCrearSquad,
              icon: const Icon(Icons.add),
              label: const Text('Crear Squad'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _squadCard(Squad squad) {
    final solicitudTexto = squad.solicitudPendiente
        ? 'Solicitud enviada'
        : squad.estaCompleto
            ? 'Completo'
            : 'Solicitar entrar';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withOpacity(0.18),
                  child: const Icon(
                    Icons.groups,
                    color: AppTheme.primarySoft,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        squad.nombre,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${squad.deporte} · ${squad.integrantesTexto}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              squad.distanciaTexto,
              style: const TextStyle(
                color: AppTheme.primarySoft,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              squad.descripcion,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isActionLoading
                        ? null
                        : () {
                            setState(() {
                              _squads.removeWhere(
                                (item) => item.id == squad.id,
                              );
                            });
                          },
                    icon: const Icon(Icons.close),
                    label: const Text('Pasar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isActionLoading ||
                            squad.solicitudPendiente ||
                            squad.estaCompleto
                        ? null
                        : () => _solicitarEntrada(squad),
                    icon: const Icon(Icons.sports_basketball),
                    label: Text(solicitudTexto),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
            'Error al cargar squads:\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    if (_squads.isEmpty) {
      return _emptyState();
    }

    return RefreshIndicator(
      onRefresh: _cargarSquads,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _squads.length,
        itemBuilder: (context, index) {
          return _squadCard(_squads[index]);
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
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onCambiarAModoPersonas,
          icon: const Icon(Icons.person),
          tooltip: 'Ver personas',
        ),
        title: const Text(
          'Squads',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _abrirMisSquads,
            icon: const Icon(Icons.list_alt),
            tooltip: 'Mis Squads',
          ),
          IconButton(
            onPressed: _abrirCrearSquad,
            icon: const Icon(Icons.add),
            tooltip: 'Crear Squad',
          ),
          IconButton(
            onPressed: _abrirFiltros,
            icon: const Icon(Icons.tune),
            tooltip: 'Filtros',
          ),
          IconButton(
            onPressed: _cargarSquads,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _contenido(),
    );
  }
}