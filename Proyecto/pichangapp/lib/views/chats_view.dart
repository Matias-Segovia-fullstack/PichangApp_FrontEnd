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
  Map<int, bool> _salasBloqueadas = {};
  Map<int, String> _nombresUsuarios = {};
  Map<int, String?> _fotosUsuarios = {};

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

      final Map<int, bool> bloqueos = {};
      final Map<int, String> nombres = {};
      final Map<int, String?> fotos = {};
      for (final sala in salas) {
        final otroUsuarioId = sala.obtenerOtroUsuarioId(userId);
        if (otroUsuarioId != 0) {
          final existeBloqueo = await _apiService.existeBloqueoEntreUsuarios(
            usuarioAId: userId,
            usuarioBId: otroUsuarioId,
          );
          bloqueos[sala.id] = existeBloqueo;

          final otroUsuario = await _apiService.obtenerUsuarioPorId(
            usuarioId: otroUsuarioId,
            token: token,
          );
          
          if (otroUsuario != null && otroUsuario['nombre'] != null) {
            String nombreMostrado = otroUsuario['nombre'].toString();
            if (otroUsuario['apellido'] != null) {
              nombreMostrado += ' ${otroUsuario['apellido']}';
            }
            nombres[otroUsuarioId] = nombreMostrado;
          } else if (otroUsuario != null && otroUsuario['username'] != null) {
            nombres[otroUsuarioId] = otroUsuario['username'].toString();
          } else {
            nombres[otroUsuarioId] = 'Usuario $otroUsuarioId';
          }
          
          if (otroUsuario != null && otroUsuario['profile'] != null) {
            fotos[otroUsuarioId] = otroUsuario['profile']['fotoUrl'];
          } else {
            fotos[otroUsuarioId] = null;
          }
        } else {
          bloqueos[sala.id] = false;
          nombres[0] = 'Usuario Desconocido';
          fotos[0] = null;
        }
      }

      if (!mounted) return;

      setState(() {
        _token = token;
        _miUsuarioId = userId;
        _salas = salas;
        _salasBloqueadas = bloqueos;
        _nombresUsuarios = nombres;
        _fotosUsuarios = fotos;
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
      child: ListView.separated( // Cambiado a ListView.separated para más orden
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _salas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final sala = _salas[index];
          final otroUsuarioId = sala.obtenerOtroUsuarioId(miUsuarioId);
          final bool esBloqueada = _salasBloqueadas[sala.id] ?? false;
          final String nombreUsuario = _nombresUsuarios[otroUsuarioId] ?? 'Usuario $otroUsuarioId';
          final String? fotoUrl = _fotosUsuarios[otroUsuarioId];

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24), // Bordes estilo "cancha"
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: esBloqueada ? Colors.red : Colors.blue, width: 2),
                ),
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (!esBloqueada && fotoUrl != null && fotoUrl.isNotEmpty)
                      ? NetworkImage(fotoUrl)
                      : null,
                  child: (!esBloqueada && fotoUrl != null && fotoUrl.isNotEmpty)
                      ? null
                      : Icon(esBloqueada ? Icons.block : Icons.person, color: esBloqueada ? Colors.red : Colors.blue),
                ),
              ),
              title: Text(
                nombreUsuario,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  esBloqueada ? 'Chat Bloqueado' : 'Match deportivo activo',
                  style: TextStyle(
                    color: esBloqueada ? Colors.red.shade600 : Colors.blue.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue.shade300),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailView(
                      sala: sala,
                      miUsuarioId: miUsuarioId,
                      token: token,
                      otroUsuarioNombre: nombreUsuario,
                      otroUsuarioFoto: fotoUrl,
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
      backgroundColor: Colors.grey.shade50, // Fondo más limpio
      appBar: AppBar(
        title: const Text('Chats Deportivos', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _cargarSalas, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: body,
    );
  }
}