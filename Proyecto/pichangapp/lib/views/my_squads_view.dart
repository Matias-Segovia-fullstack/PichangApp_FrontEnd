import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/squad.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'squad_chat_detail_view.dart';
import 'squad_requests_view.dart';

class MySquadsView extends StatefulWidget {
  const MySquadsView({super.key});

  @override
  State<MySquadsView> createState() => _MySquadsViewState();
}

class _MySquadsViewState extends State<MySquadsView> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String? _error;
  int? _miUsuarioId;
  List<Squad> _squads = [];

  @override
  void initState() {
    super.initState();
    _cargarMisSquads();
  }

  Future<void> _cargarMisSquads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userIdString = await _storage.read(key: 'user_id');
      final userId = int.tryParse(userIdString ?? '');

      if (userId == null) {
        throw Exception('No se pudo identificar el usuario.');
      }

      final data = await _apiService.obtenerMisSquads(
        usuarioId: userId,
      );

      final squads = data
          .whereType<Map<String, dynamic>>()
          .map(Squad.fromJson)
          .toList();

      if (!mounted) return;

      setState(() {
        _miUsuarioId = userId;
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

  Future<void> _abrirChat(Squad squad) async {
    final userId = _miUsuarioId;

    if (userId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SquadChatDetailView(
          squad: squad,
          miUsuarioId: userId,
        ),
      ),
    );

    if (mounted) {
      _cargarMisSquads();
    }
  }

  Future<void> _abrirSolicitudes(Squad squad) async {
    final userId = _miUsuarioId;

    if (userId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SquadRequestsView(
          squad: squad,
          adminId: userId,
        ),
      ),
    );

    if (mounted) {
      _cargarMisSquads();
    }
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.groups_2_outlined,
              size: 72,
              color: AppTheme.primarySoft,
            ),
            SizedBox(height: 18),
            Text(
              'Aún no estás en ningún squad',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Crea un squad o solicita entrar a uno desde Descubrir Squads.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _squadCard(Squad squad) {
    final soyAdmin = _miUsuarioId != null && squad.creadorId == _miUsuarioId;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primary.withOpacity(0.18),
                child: const Icon(
                  Icons.groups,
                  color: AppTheme.primarySoft,
                  size: 28,
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
                        fontSize: 20,
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
              if (soyAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppTheme.success.withOpacity(0.4),
                    ),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            squad.descripcion,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _abrirChat(squad),
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat grupal'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                ),
              ),
              if (soyAdmin) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirSolicitudes(squad),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Solicitudes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primarySoft,
                      side: const BorderSide(color: AppTheme.primarySoft),
                    ),
                  ),
                ),
              ],
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
            'Error al cargar tus squads:\n$_error',
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
      onRefresh: _cargarMisSquads,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
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
        title: const Text(
          'Mis Squads',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _cargarMisSquads,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _contenido(),
    );
  }
}