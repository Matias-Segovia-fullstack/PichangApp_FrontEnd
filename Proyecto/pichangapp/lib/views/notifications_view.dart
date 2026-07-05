import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/notificacion.dart';
import '../services/api_service.dart';

class NotificationsView extends StatefulWidget {
  final VoidCallback? onNotificationsChanged;
  final int refreshVersion;

  const NotificationsView({
    super.key,
    this.onNotificationsChanged,
    this.refreshVersion = 0,
  });

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  bool _actualizandoSilencioso = false;
  String? _error;
  List<Notificacion> _notificaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  @override
  void didUpdateWidget(covariant NotificationsView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.refreshVersion != oldWidget.refreshVersion) {
      _cargarNotificaciones(silencioso: true);
    }
  }

  Future<void> _cargarNotificaciones({bool silencioso = false}) async {
    if (_actualizandoSilencioso && silencioso) return;

    if (silencioso) {
      _actualizandoSilencioso = true;
    }

    if (!silencioso && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final userIdString = await _storage.read(key: 'user_id');

      if (userIdString == null || userIdString.isEmpty) {
        throw Exception('No existe usuario en sesión.');
      }

      final usuarioId = int.tryParse(userIdString);

      if (usuarioId == null) {
        throw Exception('ID de usuario inválido.');
      }

      final data = await _apiService.obtenerNotificacionesUsuario(
        usuarioId: usuarioId,
      );

      final notificaciones = data
          .whereType<Map<String, dynamic>>()
          .map(Notificacion.fromJson)
          .where((n) => n.id != 0)
          .toList();

      if (!mounted) return;

      setState(() {
        _notificaciones = notificaciones;
        _isLoading = false;
        _error = null;
      });

      widget.onNotificationsChanged?.call();
    } catch (e) {
      if (!mounted) return;

      if (silencioso) {
        debugPrint('No se pudieron actualizar notificaciones en segundo plano: $e');
        return;
      }

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    } finally {
      if (silencioso) {
        _actualizandoSilencioso = false;
      }
    }
  }

  Future<void> _abrirNotificacion(Notificacion notificacion) async {
    if (!notificacion.leida) {
      final ok = await _apiService.marcarNotificacionComoLeida(
        notificacionId: notificacion.id,
      );

      if (ok && mounted) {
        setState(() {
          _notificaciones = _notificaciones.map((item) {
            if (item.id != notificacion.id) return item;

            return Notificacion(
              id: item.id,
              usuarioId: item.usuarioId,
              titulo: item.titulo,
              mensaje: item.mensaje,
              tipo: item.tipo,
              leida: true,
              fechaCreacion: item.fechaCreacion,
            );
          }).toList();
        });

        widget.onNotificationsChanged?.call();
      }
    }

    if (!mounted) return;

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
      return Icons.sports_score;
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
      onRefresh: () => _cargarNotificaciones(),
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.notifications_none,
            size: 86,
            color: Colors.blue.shade300,
          ),
          const SizedBox(height: 16),
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
            'Cuando tengas un match o recibas mensajes, aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 22),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _cargarNotificaciones(),
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
            const SizedBox(height: 14),
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
              onPressed: () => _cargarNotificaciones(),
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista() {
    final noLeidas = _notificaciones.where((n) => !n.leida).length;

    return RefreshIndicator(
      onRefresh: () => _cargarNotificaciones(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _notificaciones.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                noLeidas == 1
                    ? '1 notificación sin leer'
                    : '$noLeidas notificaciones sin leer',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            );
          }

          final notificacion = _notificaciones[index - 1];
          final color = _color(notificacion);

          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _abrirNotificacion(notificacion),
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
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(_icono(notificacion), color: color),
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
      body = _lista();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _cargarNotificaciones(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}