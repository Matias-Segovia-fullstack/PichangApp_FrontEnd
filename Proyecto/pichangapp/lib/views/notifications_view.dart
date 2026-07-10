import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/notificacion.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'my_squads_view.dart';

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
        debugPrint(
          'No se pudieron actualizar notificaciones en segundo plano: $e',
        );
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
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Text(
          notificacion.titulo,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          notificacion.mensaje,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          if (notificacion.esSquadAceptada)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MySquadsView(),
                  ),
                );
              },
              child: const Text('Ver mis squads'),
            ),
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

    if (notificacion.esSquadSolicitud) {
      return Icons.group_add;
    }

    if (notificacion.esSquadAceptada) {
      return Icons.groups_2;
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

    if (notificacion.esSquadSolicitud) {
      return Colors.lightBlueAccent;
    }

    if (notificacion.esSquadAceptada) {
      return AppTheme.success;
    }

    if (notificacion.esMensaje) {
      return AppTheme.primarySoft;
    }

    return AppTheme.textSecondary;
  }

  Widget _estadoVacio() {
    return RefreshIndicator(
      onRefresh: () => _cargarNotificaciones(),
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.notifications_none,
            size: 86,
            color: AppTheme.primarySoft,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin notificaciones',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando tengas un match deportivo o novedades de squads, aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
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
            const Icon(
              Icons.error_outline,
              size: 72,
              color: AppTheme.danger,
            ),
            const SizedBox(height: 14),
            const Text(
              'No se pudieron cargar las notificaciones',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
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
                  color: AppTheme.textPrimary,
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
                color: notificacion.leida
                    ? AppTheme.surface
                    : AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: notificacion.leida
                      ? AppTheme.border
                      : AppTheme.primarySoft,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withOpacity(0.16),
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
                                  color: AppTheme.textPrimary,
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
                                  color: AppTheme.primarySoft,
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
                            color: AppTheme.textSecondary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notificacion.fechaCreacion,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
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
            onPressed: () => _cargarNotificaciones(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}