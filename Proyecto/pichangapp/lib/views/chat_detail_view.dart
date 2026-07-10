import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mensaje_chat.dart';
import '../models/sala_chat.dart';
import '../services/api_service.dart';
import '../services/media_service.dart';
import '../theme/app_theme.dart';
import 'public_user_profile_view.dart';

class ChatDetailView extends StatefulWidget {
  final SalaChat sala;
  final int miUsuarioId;
  final String token;
  final String? otroUsuarioNombre;
  final String? otroUsuarioFoto;

  const ChatDetailView({
    super.key,
    required this.sala,
    required this.miUsuarioId,
    required this.token,
    this.otroUsuarioNombre,
    this.otroUsuarioFoto,
  });

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final ApiService _apiService = ApiService();
  final MediaService _mediaService = MediaService();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = true;
  bool _isSending = false;
  bool _isBlocking = false;
  bool _verificandoBloqueo = false;

  bool _usuarioBloqueado = false;
  bool _yoBloqueeAlOtro = false;
  bool _meBloqueoElOtro = false;
  bool _marcandoNotificacionesMensaje = false;

  RealtimeChannel? _realtimeChannel;
  RealtimeChannel? _bloqueosRealtimeChannel;
  Timer? _bloqueosFallbackTimer;

  String? _error;
  List<MensajeChat> _mensajes = [];

  int get otroUsuarioId {
    return widget.sala.obtenerOtroUsuarioId(widget.miUsuarioId);
  }

  String _textoEstadoAppBar() {
    if (_yoBloqueeAlOtro) return 'Bloqueado por ti';
    if (_meBloqueoElOtro) return 'Te bloqueó';
    if (_usuarioBloqueado) return 'Chat bloqueado';
    return 'Chat Activo';
  }

  @override
  void initState() {
    super.initState();
    _inicializarChat();
  }

  @override
  void dispose() {
    _bloqueosFallbackTimer?.cancel();
    _bloqueosRealtimeChannel?.unsubscribe();
    _realtimeChannel?.unsubscribe();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _abrirPerfilUsuario(int usuarioId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicUserProfileView(
          usuarioId: usuarioId,
        ),
      ),
    );
  }

  Future<void> _inicializarChat() async {
    await _verificarBloqueoExistente();
    await _cargarMensajes();
    await _marcarNotificacionesMensajeComoLeidas();

    _conectarWebSocket();
    _conectarRealtimeBloqueos();
    _iniciarFallbackBloqueos();
  }

  Future<void> _marcarNotificacionesMensajeComoLeidas({
    bool esperarBackend = false,
  }) async {
    if (_marcandoNotificacionesMensaje) return;

    _marcandoNotificacionesMensaje = true;

    try {
      if (esperarBackend) {
        await Future.delayed(const Duration(milliseconds: 900));
      }

      await _apiService.marcarNotificacionesMensajeComoLeidas(
        usuarioId: widget.miUsuarioId,
      );
    } catch (e) {
      debugPrint('No se pudieron marcar notificaciones de mensaje: $e');
    } finally {
      _marcandoNotificacionesMensaje = false;
    }
  }

  void _conectarWebSocket() {
    debugPrint('Iniciando conexión Supabase Realtime para sala ${widget.sala.id}');

    _realtimeChannel = Supabase.instance.client
        .channel('public:mensajes_chat:sala_${widget.sala.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes_chat',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sala_id',
            value: widget.sala.id,
          ),
          callback: (payload) {
            debugPrint('Nuevo mensaje recibido vía Supabase Realtime');

            final data = payload.newRecord;

            final mensajeMap = {
              'id': data['id'],
              'salaChatId': data['sala_id'],
              'remitenteId': data['remitente_id'],
              'contenido': data['contenido'],
              'tipoMensaje': data['tipo_mensaje'],
              'mediaUrl': data['media_url'],
              'fechaEnvio': data['fecha_envio'],
            };

            final nuevoMensaje = MensajeChat.fromJson(mensajeMap);

            if (mounted) {
              setState(() {
                if (!_mensajes.any((m) => m.id == nuevoMensaje.id)) {
                  _mensajes.insert(0, nuevoMensaje);
                }
              });

              if (nuevoMensaje.remitenteId != widget.miUsuarioId) {
                _marcarNotificacionesMensajeComoLeidas(
                  esperarBackend: true,
                );
              }
            }
          },
        )
        .subscribe();
  }

  void _conectarRealtimeBloqueos() {
    debugPrint(
      'Iniciando conexión Supabase Realtime para bloqueos entre ${widget.miUsuarioId} y $otroUsuarioId',
    );

    _bloqueosRealtimeChannel = Supabase.instance.client
        .channel('public:bloqueos:chat_${widget.miUsuarioId}_$otroUsuarioId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bloqueos',
          callback: (payload) {
            debugPrint('Cambio INSERT recibido en bloqueos');

            final data = payload.newRecord;

            if (_bloqueoAfectaEsteChat(data)) {
              _verificarBloqueoExistente();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'bloqueos',
          callback: (payload) {
            debugPrint('Cambio DELETE recibido en bloqueos');
            _verificarBloqueoExistente();
          },
        )
        .subscribe();
  }

  bool _bloqueoAfectaEsteChat(Map<String, dynamic> data) {
    final origen = int.tryParse(
      (data['id_usuario_origen'] ??
                  data['idUsuarioOrigen'] ??
                  data['usuario_origen_id'] ??
                  data['usuarioOrigenId'])
              ?.toString() ??
          '',
    );

    final bloqueado = int.tryParse(
      (data['id_usuario_bloqueado'] ??
                  data['idUsuarioBloqueado'] ??
                  data['usuario_bloqueado_id'] ??
                  data['usuarioBloqueadoId'])
              ?.toString() ??
          '',
    );

    if (origen == null || bloqueado == null) {
      return false;
    }

    final yo = widget.miUsuarioId;
    final otro = otroUsuarioId;

    return (origen == yo && bloqueado == otro) ||
        (origen == otro && bloqueado == yo);
  }

  void _iniciarFallbackBloqueos() {
    _bloqueosFallbackTimer?.cancel();

    _bloqueosFallbackTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (!mounted) return;
        _verificarBloqueoExistente();
      },
    );
  }

  Future<void> _verificarBloqueoExistente() async {
    if (_verificandoBloqueo) return;

    _verificandoBloqueo = true;

    try {
      final yoBloqueeAlOtro = await _apiService.usuarioBloqueoA(
        usuarioOrigenId: widget.miUsuarioId,
        usuarioBloqueadoId: otroUsuarioId,
      );

      final meBloqueoElOtro = await _apiService.usuarioBloqueoA(
        usuarioOrigenId: otroUsuarioId,
        usuarioBloqueadoId: widget.miUsuarioId,
      );

      bool existeBloqueoEntreAmbos = yoBloqueeAlOtro || meBloqueoElOtro;

      if (!existeBloqueoEntreAmbos) {
        existeBloqueoEntreAmbos = await _apiService.existeBloqueoEntreUsuarios(
          usuarioAId: widget.miUsuarioId,
          usuarioBId: otroUsuarioId,
        );
      }

      if (!mounted) return;

      final cambioEstado = _yoBloqueeAlOtro != yoBloqueeAlOtro ||
          _meBloqueoElOtro != meBloqueoElOtro ||
          _usuarioBloqueado != existeBloqueoEntreAmbos;

      if (cambioEstado) {
        setState(() {
          _yoBloqueeAlOtro = yoBloqueeAlOtro;
          _meBloqueoElOtro = meBloqueoElOtro;
          _usuarioBloqueado = existeBloqueoEntreAmbos;
        });
      }
    } catch (e) {
      debugPrint('Error verificando bloqueo en tiempo real: $e');
    } finally {
      _verificandoBloqueo = false;
    }
  }

  Future<void> _cargarMensajes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.obtenerMensajes(
        salaId: widget.sala.id,
        token: widget.token,
      );

      final mensajes = data
          .whereType<Map<String, dynamic>>()
          .map(MensajeChat.fromJson)
          .where((mensaje) => mensaje.id != 0)
          .toList();

      if (!mounted) return;

      setState(() {
        _mensajes = mensajes;
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

  Future<void> _enviarMensaje() async {
    final contenido = _messageController.text.trim();

    if (contenido.isEmpty || _isSending || _usuarioBloqueado) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final enviado = await _apiService.enviarMensaje(
      salaId: widget.sala.id,
      remitenteId: widget.miUsuarioId,
      contenido: contenido,
      token: widget.token,
    );

    if (!mounted) return;

    if (enviado) {
      _messageController.clear();
    } else {
      await _verificarBloqueoExistente();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo enviar el mensaje. Puede existir un bloqueo entre los usuarios.',
          ),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });
  }

  Future<void> _subirImagen() async {
    if (_usuarioBloqueado) return;

    try {
      final url = await _mediaService.pickCompressAndUploadImage(
        bucket: 'chat-media',
        folder: 'sala_${widget.sala.id}',
      );

      if (url != null && url.isNotEmpty && mounted) {
        setState(() {
          _isSending = true;
        });

        final enviado = await _apiService.enviarMensaje(
          salaId: widget.sala.id,
          remitenteId: widget.miUsuarioId,
          contenido: '[Imagen]',
          tipoMensaje: 'IMAGEN',
          mediaUrl: url,
          token: widget.token,
        );

        if (!mounted) return;

        if (!enviado) {
          await _verificarBloqueoExistente();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo enviar la imagen. Puede existir un bloqueo.',
              ),
            ),
          );
        }

        setState(() {
          _isSending = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir imagen: $e')),
      );
    }
  }

  Future<void> _confirmarBloqueo() async {
    final nombreUsuario = widget.otroUsuarioNombre ?? 'Usuario $otroUsuarioId';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.border),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.block,
                size: 48,
                color: AppTheme.danger,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bloquear Usuario',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Quieres bloquear a $nombreUsuario?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Después del bloqueo, esta sala de chat quedará deshabilitada y no podrán enviarse más mensajes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            child: const Text('Sí, bloquear'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _bloquearUsuario();
    }
  }

  Future<void> _bloquearUsuario() async {
    if (_isBlocking || _usuarioBloqueado) {
      return;
    }

    setState(() {
      _isBlocking = true;
    });

    try {
      final bloqueado = await _apiService.bloquearUsuario(
        idUsuarioOrigen: widget.miUsuarioId,
        idUsuarioBloqueado: otroUsuarioId,
      );

      if (!mounted) return;

      if (bloqueado) {
        setState(() {
          _isBlocking = false;
          _usuarioBloqueado = true;
          _yoBloqueeAlOtro = true;
          _meBloqueoElOtro = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario bloqueado. El chat quedó deshabilitado.'),
          ),
        );

        await _verificarBloqueoExistente();
      } else {
        setState(() {
          _isBlocking = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo bloquear al usuario. Revisa que msvc-seguridad esté corriendo.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isBlocking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al bloquear usuario: $e')),
      );
    }
  }

  Future<void> _confirmarDesbloqueo() async {
    if (!_yoBloqueeAlOtro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes desbloquear este chat porque el bloqueo lo realizó el otro usuario.',
          ),
        ),
      );
      return;
    }

    final nombreUsuario = widget.otroUsuarioNombre ?? 'Usuario $otroUsuarioId';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.border),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_open,
                size: 48,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Desbloquear Usuario',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Quieres desbloquear a $nombreUsuario?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Después del desbloqueo, esta sala de chat volverá a estar activa y podrán enviarse mensajes nuevamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
            ),
            child: const Text('Sí, desbloquear'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _desbloquearUsuario();
    }
  }

  Future<void> _desbloquearUsuario() async {
    if (_isBlocking) return;

    if (!_yoBloqueeAlOtro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes desbloquear este chat porque el bloqueo lo realizó el otro usuario.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isBlocking = true;
    });

    try {
      final desbloqueado = await _apiService.desbloquearUsuario(
        idUsuarioOrigen: widget.miUsuarioId,
        idUsuarioBloqueado: otroUsuarioId,
      );

      if (!mounted) return;

      if (desbloqueado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario desbloqueado. El chat vuelve a estar disponible.'),
          ),
        );

        await _verificarBloqueoExistente();

        if (!mounted) return;

        setState(() {
          _isBlocking = false;
        });

        if (!_usuarioBloqueado) {
          await _cargarMensajes();
          await _marcarNotificacionesMensajeComoLeidas();
        }
      } else {
        setState(() {
          _isBlocking = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo desbloquear al usuario. Revisa msvc-seguridad.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isBlocking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al desbloquear usuario: $e')),
      );
    }
  }

  Widget _mensajeBubble(MensajeChat mensaje) {
    final esMio = mensaje.remitenteId == widget.miUsuarioId;
    final esImagen = mensaje.tipoMensaje == 'IMAGEN' ||
        (mensaje.mediaUrl != null && mensaje.mediaUrl!.isNotEmpty);

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: esMio ? AppTheme.primary : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: esMio ? const Radius.circular(20) : Radius.zero,
            bottomRight: esMio ? Radius.zero : const Radius.circular(20),
          ),
          border: esMio
              ? null
              : Border.all(color: AppTheme.border.withOpacity(0.7)),
        ),
        child: Column(
          crossAxisAlignment:
              esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (esImagen)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  mensaje.mediaUrl ?? mensaje.contenido,
                  width: 200,
                ),
              )
            else
              Text(
                mensaje.contenido,
                style: TextStyle(
                  color: esMio ? Colors.white : AppTheme.textPrimary,
                  fontSize: 15,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _contenidoMensajes() {
    if (_isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error al cargar mensajes:\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    if (_mensajes.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'Aún no hay mensajes.\nEscribe el primero.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async {
          await _verificarBloqueoExistente();
          await _cargarMensajes();
          await _marcarNotificacionesMensajeComoLeidas();
        },
        child: ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: _mensajes.length,
          itemBuilder: (context, index) {
            return _mensajeBubble(_mensajes[index]);
          },
        ),
      ),
    );
  }

  Widget _inputMensaje() {
    if (_usuarioBloqueado) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          top: BorderSide(color: AppTheme.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _isSending ? null : _subirImagen,
              icon: const Icon(
                Icons.add_photo_alternate,
                color: AppTheme.primarySoft,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppTheme.primarySoft),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isSending ? null : _enviarMensaje,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerEstado() {
    if (_yoBloqueeAlOtro) {
      return Container(
        width: double.infinity,
        color: AppTheme.danger.withOpacity(0.12),
        padding: const EdgeInsets.all(12),
        child: Text(
          'Bloqueaste a ${widget.otroUsuarioNombre ?? 'Usuario $otroUsuarioId'}. El chat está deshabilitado hasta que tú lo desbloquees.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.danger,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (_meBloqueoElOtro) {
      return Container(
        width: double.infinity,
        color: AppTheme.danger.withOpacity(0.12),
        padding: const EdgeInsets.all(12),
        child: const Text(
          'Este usuario te bloqueó. No puedes enviar mensajes ni desbloquear este chat.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.danger,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (_usuarioBloqueado) {
      return Container(
        width: double.infinity,
        color: AppTheme.danger.withOpacity(0.12),
        padding: const EdgeInsets.all(12),
        child: Text(
          'Chat bloqueado entre usuario ${widget.miUsuarioId} y usuario $otroUsuarioId.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.danger,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: AppTheme.primary.withOpacity(0.12),
      padding: const EdgeInsets.all(12),
      child: Text(
        'Chat habilitado por match',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.primarySoft,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _botonBloquear() {
    if (_yoBloqueeAlOtro) {
      return IconButton(
        onPressed: _isBlocking ? null : _confirmarDesbloqueo,
        icon: _isBlocking
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.lock_open, color: AppTheme.success),
        tooltip: 'Desbloquear usuario',
      );
    }

    if (_meBloqueoElOtro) {
      return IconButton(
        onPressed: null,
        icon: const Icon(Icons.lock, color: AppTheme.textSecondary),
        tooltip: 'No puedes desbloquear un bloqueo realizado por el otro usuario',
      );
    }

    if (_usuarioBloqueado) {
      return IconButton(
        onPressed: null,
        icon: const Icon(Icons.lock, color: AppTheme.textSecondary),
        tooltip: 'Chat bloqueado',
      );
    }

    return IconButton(
      onPressed: _isBlocking ? null : _confirmarBloqueo,
      icon: _isBlocking
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.block, color: AppTheme.danger),
      tooltip: 'Bloquear usuario',
    );
  }

  Widget _avatarOtroUsuario() {
    return InkWell(
      onTap: () => _abrirPerfilUsuario(otroUsuarioId),
      borderRadius: BorderRadius.circular(999),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: _usuarioBloqueado
            ? AppTheme.danger.withOpacity(0.16)
            : AppTheme.primarySoft.withOpacity(0.18),
        backgroundImage: (!_usuarioBloqueado &&
                widget.otroUsuarioFoto != null &&
                widget.otroUsuarioFoto!.isNotEmpty)
            ? NetworkImage(widget.otroUsuarioFoto!)
            : null,
        child: (!_usuarioBloqueado &&
                widget.otroUsuarioFoto != null &&
                widget.otroUsuarioFoto!.isNotEmpty)
            ? null
            : Icon(
                _usuarioBloqueado ? Icons.block : Icons.person,
                size: 20,
                color: _usuarioBloqueado
                    ? AppTheme.danger
                    : AppTheme.primarySoft,
              ),
      ),
    );
  }

  Widget _tituloOtroUsuario() {
    return InkWell(
      onTap: () => _abrirPerfilUsuario(otroUsuarioId),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.otroUsuarioNombre ?? 'Usuario $otroUsuarioId',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _textoEstadoAppBar(),
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
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
        title: Row(
          children: [
            _avatarOtroUsuario(),
            const SizedBox(width: 12),
            Expanded(
              child: _tituloOtroUsuario(),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _verificarBloqueoExistente();
              await _cargarMensajes();
              await _marcarNotificacionesMensajeComoLeidas();
            },
            icon: const Icon(Icons.refresh),
          ),
          _botonBloquear(),
        ],
      ),
      body: Column(
        children: [
          _bannerEstado(),
          _contenidoMensajes(),
          _inputMensaje(),
        ],
      ),
    );
  }
}