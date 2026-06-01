import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/sala_chat.dart';
import '../services/api_service.dart';
import 'chat_detail_view.dart';

class ChatsView extends StatefulWidget {
  const ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String? _error;
  String? _token;
  int? _miUsuarioId;
  List<SalaChat> _salas = [];

  @override
  void initState() {
    super.initState();
    _cargarSalas();
  }

  Future<void> _cargarSalas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final userIdString = await _storage.read(key: 'user_id');

      if (token == null || token.isEmpty || userIdString == null) {
        throw Exception('No existe sesión activa.');
      }

      final userId = int.tryParse(userIdString);

      if (userId == null) {
        throw Exception('ID de usuario inválido.');
      }

      final data = await _apiService.obtenerSalasUsuario(
        usuarioId: userId,
        token: token,
      );

      final salas = data
          .whereType<Map<String, dynamic>>()
          .map(SalaChat.fromJson)
          .where((sala) => sala.id != 0)
          .toList();

      if (!mounted) return;

      setState(() {
        _token = token;
        _miUsuarioId = userId;
        _salas = salas;
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

  Widget _estadoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes chats',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando tengas un MatchSocial, RabbitMQ creará una sala automáticamente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarSalas,
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar chats'),
            ),
          ],
        ),
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
              'No se pudieron cargar los chats',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarSalas,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaSalas() {
    final miUsuarioId = _miUsuarioId!;
    final token = _token!;

    return RefreshIndicator(
      onRefresh: _cargarSalas,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _salas.length,
        itemBuilder: (context, index) {
          final sala = _salas[index];
          final otroUsuarioId = sala.obtenerOtroUsuarioId(miUsuarioId);

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: const Icon(Icons.person, color: Colors.blue),
              ),
              title: Text(
                'Chat con usuario $otroUsuarioId',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Sala ${sala.id} · Match ${sala.matchSocialId} · ${sala.estado}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailView(
                      sala: sala,
                      miUsuarioId: miUsuarioId,
                      token: token,
                    ),
                  ),
                );
              },
            ),
          );
        },
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
    } else if (_salas.isEmpty) {
      body = _estadoVacio();
    } else {
      body = _listaSalas();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats reales'),
        actions: [
          IconButton(
            onPressed: _cargarSalas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}