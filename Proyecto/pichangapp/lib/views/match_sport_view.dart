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
      if (userId == null) throw Exception('El ID del usuario no es válido.');

      final usuariosRaw = await _apiService.descubrirUsuarios(excludeId: userId, token: token);
      final usuariosInteractuados = await _apiService.obtenerUsuariosInteractuados(usuarioId: userId);
      final usuariosInteractuadosSet = usuariosInteractuados.toSet();

      final deportistas = usuariosRaw
          .whereType<Map<String, dynamic>>()
          .map(Deportista.fromJson)
          .where((d) => d.id != 0 && !usuariosInteractuadosSet.contains(d.id))
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
  // Nota: Ya no verificamos _indiceActual aquí porque el Dismissible 
  // dispara esto para la tarjeta específica que ya está en proceso de irse.
  if (_miUsuarioId == null) return;

  final deportista = _deportistas[_indiceActual];
  
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tipo == tipoLike ? 'Like enviado a ${deportista.nombreCompleto}' : 'Dislike enviado a ${deportista.nombreCompleto}')),
      );
    }
    // Solo avanzamos el estado lógico aquí
    setState(() => _indiceActual++);
    
  } catch (e) {
    if (!mounted) return;
    final mensaje = _limpiarError(e).toLowerCase();
    
    if (mensaje.contains('ya ha interactuado') || mensaje.contains('conflict') || mensaje.contains('409')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya habías interactuado con este usuario.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $mensaje')));
    }
    // Si hay error, obligamos a recargar la lista para recuperar la coherencia visual
    _cargarDeportistas();
  }
}

  void _avanzarTarjeta() => setState(() { _indiceActual++; _isSending = false; });

  String _limpiarError(Object e) => e.toString().length <= 180 ? e.toString() : '${e.toString().substring(0, 180)}...';

  Future<void> _mostrarMatch(Deportista d) async {
  await showGeneralDialog(
    context: context,
    pageBuilder: (context, anim1, anim2) => Container(),
    transitionBuilder: (context, anim1, anim2, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.5, end: 1.0).animate(anim1),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Encabezado con color deportivo
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: const Center(
                  child: Icon(Icons.emoji_events, size: 80, color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('¡HAY MATCH DEPORTIVO!', 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blue)),
                    const SizedBox(height: 15),
                    Text('${d.nombreCompleto} quiere jugar contigo.', 
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    const Text('RabbitMQ debería crear una sala de chat automáticamente.', 
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('¡Vamos a jugar!', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  // --- UI Estilizada ---
  Widget _infoChip(String texto, IconData icono) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: Colors.blue.shade800),
          const SizedBox(width: 6),
          Text(texto, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _construirTarjeta(Deportista deportista) {
  return Column(
    children: [
      Expanded(
        child: Dismissible(
          key: ValueKey(deportista.id),
          direction: DismissDirection.horizontal,
          onDismissed: (direction) {
            final tipo = (direction == DismissDirection.startToEnd) ? tipoLike : tipoDislike;
            _enviarInteraccion(tipo);
          },
          // Pasamos un Container vacío para que no se vea ningún color ni icono
          background: Container(), 
          secondaryBackground: Container(),
          
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(color: Colors.blue, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: Image.network(
                      deportista.fotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.blue.shade50,
                        child: const Icon(Icons.person, size: 80, color: Colors.blue),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deportista.edad > 0 
                              ? '${deportista.nombreCompleto}, ${deportista.edad}' 
                              : deportista.nombreCompleto,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                        ),
                        Text('@${deportista.username}', 
                             style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _infoChip(deportista.deportePrincipal, Icons.sports_soccer),
                          _infoChip(deportista.posicion, Icons.place),
                          _infoChip(deportista.altura, Icons.height),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      _buildActionButtons(),
    ],
  );
}


  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btnAccion(Icons.close, Colors.red, () => _enviarInteraccion(tipoDislike)),
          _btnAccion(Icons.sports_soccer, Colors.green, () => _enviarInteraccion(tipoLike)),
        ],
      ),
    );
  }

  Widget _btnAccion(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
      child: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _isSending ? null : onPressed,
        child: _isSending ? const CircularProgressIndicator(strokeWidth: 2) : Icon(icon, size: 32, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) body = const Center(child: CircularProgressIndicator());
    else if (_error != null) body = _estadoError();
    else if (_deportistas.isEmpty || _indiceActual >= _deportistas.length) body = _estadoVacio();
    else body = _construirTarjeta(_deportistas[_indiceActual]);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Descubrir', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [IconButton(onPressed: _cargarDeportistas, icon: const Icon(Icons.refresh, color: Colors.white))],
      ),
      body: body,
    );
  }

  Widget _estadoVacio() => Center(child: Padding(padding: const EdgeInsets.all(26), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.sports, size: 80, color: Colors.blue), const Text('No hay más deportistas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), ElevatedButton.icon(onPressed: _cargarDeportistas, icon: const Icon(Icons.refresh), label: const Text('Recargar'))])));
  Widget _estadoError() => Center(child: Padding(padding: const EdgeInsets.all(26), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 70, color: Colors.red), const Text('Error al cargar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(_error ?? ''), ElevatedButton.icon(onPressed: _cargarDeportistas, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))])));
}