import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/notificacion.dart';
import '../services/api_service.dart';

class NotificationsView extends StatefulWidget {
  final VoidCallback? onNotificationsChanged;

  const NotificationsView({
    super.key,
    this.onNotificationsChanged,
  });

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String? _error;
  String? _token;
  int? _usuarioId;
  List<Notificacion> _notificaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
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

      final data = await _apiService.obtenerNotificacionesUsuario(
        usuarioId: userId,
        token: token,
      );

      final notificaciones = data
          .whereType<Map<String, dynamic>>()
          .map(Notificacion.fromJson)
          .where((notificacion) => notificacion.id != 0)
          .toList();

      if (!mounted) return;

      setState(() {
        _token = token;
        _usuarioId = userId;
        _notificaciones = notificaciones;
        _isLoading = false;
      });

      widget.onNotificationsChanged?.call();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _marcarComoLeida(Notificacion notificacion) async {
    if (notificacion.leida) {
      _mostrarDetalle(notificacion);
      return;
    }

    final token = _token;

    if (token == null || token.isEmpty) {
      return;
    }

    final ok = await _apiService.marcarNotificacionComoLeida(
      notificacionId: notificacion.id,
      token: token,
    );

    if (!mounted) return;

    if (ok) {
      setState(() {
        _notificaciones = _notificaciones
            .map(
              (item) => item.id == notificacion.id
                  ? Notificacion(
                      id: item.id,
                      usuarioId: item.usuarioId,
                      titulo: item.titulo,
                      mensaje: item.mensaje,
                      tipo: item.tipo,
                      leida: true,
                      fechaCreacion: item.fechaCreacion,
                    )
                  : item,
            )
            .toList();
      });

      widget.onNotificationsChanged?.call();
    }

    _mostrarDetalle(notificacion);
  }

  Future<void> _marcarTodasComoLeidas() async {
    final token = _token;

    if (token == null || token.isEmpty) {
      return;
    }

    final pendientes = _notificaciones.where((n) => !n.leida).toList();

    if (pendientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay notificaciones pendientes.')),
      );
      return;
    }

    for (final notificacion in pendientes) {
      await _apiService.marcarNotificacionComoLeida(
        notificacionId: notificacion.id,
        token: token,
      );
    }

    await _cargarNotificaciones();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notificaciones marcadas como leídas.')),
    );
  }

  void _mostrarDetalle(Notificacion notificacion) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(notificacion.titulo),
        content: Text(notificacion.mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  IconData _icono(Notificacion notificacion) {
    if (notificacion.esMatch) {
      return Icons.emoji_events;
    }

    if (notificacion.esMensaje) {
      return Icons.chat_bubble;
    }

    return Icons.notifications;
  }

  Color _color(Notificacion notificacion) {
    if (notificacion.esMatch) {
      return Colors.orange;
    }

    if (notificacion.esMensaje) {
      return Colors.blue;
    }

    return Colors.grey;
  }

  Widget _estadoVacio() {
    return RefreshIndicator(
      onRefresh: _cargarNotificaciones,
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.notifications_none,
            size: 90,
            color: Colors.blue.shade300,
          ),
          const SizedBox(height: 18),
          const Text(
            'Sin notificaciones',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando tengas un match o recibas un mensaje, aparecerá aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: _cargarNotificaciones,
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
            ),
          ),
        ],
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
            const Icon(Icons.error_outline, size: 72, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'No se pudieron cargar las notificaciones',
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
              onPressed: _cargarNotificaciones,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaNotificaciones() {
    final noLeidas = _notificaciones.where((n) => !n.leida).length;

    return RefreshIndicator(
      onRefresh: _cargarNotificaciones,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _notificaciones.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    noLeidas == 1
                        ? '1 notificación sin leer'
                        : '$noLeidas notificaciones sin leer',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _marcarTodasComoLeidas,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Marcar todas'),
                ),
              ],
            );
          }

          final notificacion = _notificaciones[index - 1];
          final color = _color(notificacion);

          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _marcarComoLeida(notificacion),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: notificacion.leida ? Colors.white : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: notificacion.leida
                      ? Colors.grey.shade200
                      : Colors.blue.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withOpacity(0.14),
                    child: Icon(
                      _icono(notificacion),
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notificacion.titulo,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notificacion.leida
                                      ? FontWeight.w700
                                      : FontWeight.w900,
                                ),
                              ),
                            ),
                            if (!notificacion.leida)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notificacion.mensaje,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notificacion.fechaCreacion,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
    } else if (_notificaciones.isEmpty) {
      body = _estadoVacio();
    } else {
      body = _listaNotificaciones();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _cargarNotificaciones,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}