import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/deportista.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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
      _isSending = false;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final userIdString = await _storage.read(key: 'user_id');

      if (token == null || token.isEmpty || userIdString == null) {
        throw Exception('No existe sesión activa. Vuelve a iniciar sesión.');
      }

      final userId = int.tryParse(userIdString);

      if (userId == null) {
        throw Exception('El ID del usuario no es válido.');
      }

      final usuariosRaw = await _apiService.descubrirUsuarios(
        excludeId: userId,
        token: token,
      );

      final usuariosInteractuados =
          await _apiService.obtenerUsuariosInteractuados(
        usuarioId: userId,
      );

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
        _isSending = false;
      });
    }
  }

  Future<void> _enviarInteraccion(String tipo) async {
    if (_miUsuarioId == null) return;
    if (_isSending) return;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tipo == tipoLike
                  ? 'Like enviado a ${deportista.nombreCompleto}'
                  : 'Dislike enviado a ${deportista.nombreCompleto}',
            ),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _indiceActual++;
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;

      final mensaje = _limpiarError(e).toLowerCase();

      if (mensaje.contains('ya ha interactuado') ||
          mensaje.contains('conflict') ||
          mensaje.contains('409')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya habías interactuado con este usuario.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $mensaje')),
        );
      }

      setState(() {
        _isSending = false;
      });

      await _cargarDeportistas();
    }
  }

  String _limpiarError(Object e) {
    final texto = e.toString();
    return texto.length <= 180 ? texto : '${texto.substring(0, 180)}...';
  }

  Future<void> _mostrarMatch(Deportista d) async {
    await showGeneralDialog(
      context: context,
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(anim1),
          child: AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(color: AppTheme.border),
            ),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        '¡HAY MATCH DEPORTIVO!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primarySoft,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        '${d.nombreCompleto} quiere jugar contigo.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'RabbitMQ debería crear una sala de chat automáticamente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '¡Vamos a jugar!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(String texto, IconData icono) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppTheme.primarySoft.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: AppTheme.primarySoft),
          const SizedBox(width: 6),
          Text(
            texto,
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

  Widget _construirTarjeta(Deportista deportista) {
    return Column(
      children: [
        Expanded(
          child: Dismissible(
            key: ValueKey(deportista.id),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              final tipo = direction == DismissDirection.startToEnd
                  ? tipoLike
                  : tipoDislike;

              _enviarInteraccion(tipo);
            },
            background: Container(),
            secondaryBackground: Container(),
            child: Card(
              color: AppTheme.surface,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(
                  color: AppTheme.border,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      child: Image.network(
                        deportista.fotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.surfaceAlt,
                          child: const Icon(
                            Icons.person,
                            size: 80,
                            color: AppTheme.primarySoft,
                          ),
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
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '@${deportista.username}',
                            style: const TextStyle(
                              color: AppTheme.primarySoft,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _infoChip(
                                deportista.deportePrincipal,
                                Icons.sports_soccer,
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
          _btnAccion(
            Icons.close,
            AppTheme.danger,
            () => _enviarInteraccion(tipoDislike),
          ),
          _btnAccion(
            Icons.sports_soccer,
            AppTheme.success,
            () => _enviarInteraccion(tipoLike),
          ),
        ],
      ),
    );
  }

  Widget _btnAccion(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: AppTheme.surface,
        onPressed: _isSending ? null : onPressed,
        child: _isSending
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Icon(icon, size: 32, color: color),
      ),
    );
  }

  Widget _estadoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports,
              size: 80,
              color: AppTheme.primarySoft,
            ),
            const SizedBox(height: 14),
            const Text(
              'No hay más deportistas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
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
            const Icon(
              Icons.error_outline,
              size: 70,
              color: AppTheme.danger,
            ),
            const SizedBox(height: 14),
            const Text(
              'Error al cargar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _cargarDeportistas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Descubrir',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
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