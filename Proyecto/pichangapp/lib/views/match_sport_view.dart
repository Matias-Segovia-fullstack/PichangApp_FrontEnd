import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/deportista.dart';
import '../services/api_service.dart';

class MatchSportView extends StatefulWidget {
  const MatchSportView({super.key});

  @override
  State<MatchSportView> createState() => _MatchSportViewState();
}

class _MatchSportViewState extends State<MatchSportView> {
  static const String tipoLike = 'ME_GUSTA';
  static const String tipoDislike = 'DISME_GUSTA';

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<Deportista> _deportistas = [];
  int _indiceActual = 0;
  int? _miUsuarioId;

  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDeportistas();
  }

  Future<void> _cargarDeportistas() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _indiceActual = 0;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final userIdString = await _storage.read(key: 'user_id');

      if (token == null || token.isEmpty || userIdString == null) {
        throw Exception('No existe sesión activa. Vuelve a iniciar sesión.');
      }

      final userId = int.tryParse(userIdString);

      if (userId == null) {
        throw Exception('El ID del usuario guardado no es válido.');
      }

      final usuariosRaw = await _apiService.descubrirUsuarios(
        excludeId: userId,
        token: token,
      );

      final usuariosInteractuados = await _apiService.obtenerUsuariosInteractuados(
        usuarioId: userId,
      );

      final usuariosInteractuadosSet = usuariosInteractuados.toSet();

      final deportistas = usuariosRaw
          .whereType<Map<String, dynamic>>()
          .map(Deportista.fromJson)
          .where((deportista) => deportista.id != 0)
          .where((deportista) => !usuariosInteractuadosSet.contains(deportista.id))
          .toList();

      if (!mounted) return;

      setState(() {
        _miUsuarioId = userId;
        _deportistas = deportistas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _limpiarError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _enviarInteraccion(String tipo) async {
    if (_isSending) return;
    if (_miUsuarioId == null) return;
    if (_indiceActual >= _deportistas.length) return;

    final deportista = _deportistas[_indiceActual];

    setState(() {
      _isSending = true;
    });

    try {
      final hayMatch = await _apiService.enviarInteraccion(
        usuarioOrigenId: _miUsuarioId!,
        usuarioDestinoId: deportista.id,
        tipo: tipo,
      );

      if (!mounted) return;

      if (hayMatch) {
        await _mostrarMatch(deportista);
      } else {
        final texto = tipo == tipoLike
            ? 'Like enviado a ${deportista.nombreCompleto}'
            : 'Dislike enviado a ${deportista.nombreCompleto}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(texto)),
        );
      }

      _avanzarTarjeta();
    } catch (e) {
      if (!mounted) return;

      final mensaje = _limpiarError(e);

      final esInteraccionDuplicada =
          mensaje.toLowerCase().contains('ya ha interactuado') ||
          mensaje.toLowerCase().contains('conflict') ||
          mensaje.contains('409');

      if (esInteraccionDuplicada) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya habías interactuado con este usuario. Se ocultará de la lista.'),
          ),
        );

        _avanzarTarjeta();
        return;
      }

      setState(() {
        _isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo registrar la interacción: $mensaje'),
        ),
      );
    }
  }

  void _avanzarTarjeta() {
    setState(() {
      _indiceActual++;
      _isSending = false;
    });
  }

  String _limpiarError(Object e) {
    final texto = e.toString();

    if (texto.length <= 180) {
      return texto;
    }

    return '${texto.substring(0, 180)}...';
  }

  Future<void> _mostrarMatch(Deportista deportista) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¡Nuevo MatchSocial!'),
        content: Text(
          '${deportista.nombreCompleto} también te dio Like. RabbitMQ debería crear una sala de chat automáticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String texto, IconData icono) {
    return Chip(
      avatar: Icon(icono, size: 18),
      label: Text(texto),
    );
  }

  Widget _construirTarjeta(Deportista deportista) {
    return Column(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(20),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: Image.network(
                      deportista.fotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: Colors.blue[100],
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 90,
                              color: Colors.blue,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deportista.edad > 0
                            ? '${deportista.nombreCompleto}, ${deportista.edad}'
                            : deportista.nombreCompleto,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '@${deportista.username}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _infoChip(
                            deportista.deportePrincipal,
                            Icons.sports_basketball,
                          ),
                          _infoChip(
                            deportista.posicion,
                            Icons.place,
                          ),
                          _infoChip(
                            deportista.altura,
                            Icons.height,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        deportista.descripcion,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 34, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'btn_dislike',
                onPressed: _isSending
                    ? null
                    : () => _enviarInteraccion(tipoDislike),
                backgroundColor: Colors.white,
                child: _isSending
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.close, size: 34, color: Colors.red),
              ),
              FloatingActionButton(
                heroTag: 'btn_like',
                onPressed: _isSending
                    ? null
                    : () => _enviarInteraccion(tipoLike),
                backgroundColor: Colors.white,
                child: _isSending
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.favorite, size: 34, color: Colors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _estadoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'No hay más deportistas disponibles',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No quedan usuarios nuevos por descubrir. Puedes crear otro usuario o usar otra cuenta para seguir probando el flujo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarDeportistas,
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
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
              'No se pudieron cargar deportistas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarDeportistas,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar nuevamente'),
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
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = _estadoError();
    } else if (_deportistas.isEmpty || _indiceActual >= _deportistas.length) {
      body = _estadoVacio();
    } else {
      body = _construirTarjeta(_deportistas[_indiceActual]);
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Descubrir deportistas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _cargarDeportistas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}