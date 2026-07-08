import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mensaje_chat.dart';
import '../models/sala_chat.dart';
import '../services/api_service.dart';
import '../services/media_service.dart';

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

  // Estado general del chat bloqueado.
  bool _usuarioBloqueado = false;

  // Dirección del bloqueo.
  // Esto evita que el usuario bloqueado pueda desbloquear el chat.
  bool _yoBloqueeAlOtro = false;
  bool _meBloqueoElOtro = false;

  bool _marcandoNotificacionesMensaje = false;

  // Realtime original para mensajes.
  RealtimeChannel? _realtimeChannel;

  // Realtime nuevo para bloqueo/desbloqueo.
  RealtimeChannel? _bloqueosRealtimeChannel;

  // Fallback por si Supabase Realtime no está habilitado en la tabla bloqueos.
  Timer? _bloqueosFallbackTimer;

  String? _error;
  List<MensajeChat> _mensajes = [];

  int get otroUsuarioId {
    return widget.sala.obtenerOtroUsuarioId(widget.miUsuarioId);
  }

  String _textoEstadoAppBar() {
    if (_yoBloqueeAlOtro) {
      return 'Bloqueado por ti';
    }

    if (_meBloqueoElOtro) {
      return 'Te bloqueó';
    }

    if (_usuarioBloqueado) {
      return 'Chat bloqueado';
    }

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

  Future<void> _inicializarChat() async {
    await _verificarBloqueoExistente();
    await _cargarMensajes();

    // Si el usuario abrió el chat, asumimos que ya leyó los mensajes.
    // No toca Supabase Realtime ni modifica la recepción/envío del chat.
    await _marcarNotificacionesMensajeComoLeidas();

    // Realtime original de mensajes. Se mantiene intacto.
    _conectarWebSocket();

    // Realtime nuevo para bloqueo/desbloqueo.
    _conectarRealtimeBloqueos();

    // Respaldo si Supabase Realtime no está habilitado en la tabla bloqueos.
    _iniciarFallbackBloqueos();
  }

  Future<void> _marcarNotificacionesMensajeComoLeidas({
    bool esperarBackend = false,
  }) async {
    if (_marcandoNotificacionesMensaje) return;

    _marcandoNotificacionesMensaje = true;

    try {
      // Cuando llega un mensaje por Realtime, la notificación puede demorar
      // un poco en crearse por backend/eventos. Este delay ayuda a alcanzarla.
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

            // Adaptar las claves si vienen en snake_case desde la base de datos.
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

              // Si el mensaje llegó mientras estoy dentro del chat,
              // se considera leído visualmente.
              // Solo marcamos notificaciones si el mensaje viene del otro usuario.
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

            // En DELETE Supabase puede no entregar todas las columnas si la tabla
            // no tiene REPLICA IDENTITY FULL. Por seguridad verificamos igual.
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

    final yoBloqueeAlOtro = origen == yo && bloqueado == otro;
    final meBloqueoElOtro = origen == otro && bloqueado == yo;

    return yoBloqueeAlOtro || meBloqueoElOtro;
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

      // Fallback: si por algún motivo no se pudo determinar la dirección,
      // igual verificamos si existe bloqueo entre ambos.
      // Si existe bloqueo pero no sabemos quién bloqueó, se deshabilita el desbloqueo.
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

      // El mensaje llegará por Supabase Realtime y se insertará automáticamente.
      // No se fuerza recarga para no romper el comportamiento realtime existente.
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

        if (enviado) {
          // El mensaje llegará por Supabase Realtime y se insertará automáticamente.
        } else {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.block, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bloquear Usuario',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Quieres bloquear a $nombreUsuario?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Después del bloqueo, esta sala de chat quedará deshabilitada y no podrán enviarse más mensajes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Sí, bloquear',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
            content: Text(
              'Usuario bloqueado. El chat quedó deshabilitado.',
            ),
          ),
        );

        // Refuerzo local: por si el backend tarda en reflejar el cambio.
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
        SnackBar(
          content: Text('Error al bloquear usuario: $e'),
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_open, size: 48, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              'Desbloquear Usuario',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Quieres desbloquear a $nombreUsuario?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Después del desbloqueo, esta sala de chat volverá a estar activa y podrán enviarse mensajes nuevamente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Sí, desbloquear',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _desbloquearUsuario();
    }
  }

  Future<void> _desbloquearUsuario() async {
    if (_isBlocking) {
      return;
    }

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
          color: esMio ? Colors.blue.shade600 : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: esMio ? const Radius.circular(20) : Radius.zero,
            bottomRight: esMio ? Radius.zero : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                  color: esMio ? Colors.white : Colors.black87,
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _isSending ? null : _subirImagen,
              icon: Icon(Icons.add_photo_alternate, color: Colors.blue.shade400),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            IconButton.filled(
              onPressed: _isSending ? null : _enviarMensaje,
              style: IconButton.styleFrom(backgroundColor: Colors.blue.shade600),
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
        color: Colors.red[50],
        padding: const EdgeInsets.all(12),
        child: Text(
          'Bloqueaste a ${widget.otroUsuarioNombre ?? 'Usuario $otroUsuarioId'}. El chat está deshabilitado hasta que tú lo desbloquees.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (_meBloqueoElOtro) {
      return Container(
        width: double.infinity,
        color: Colors.red[50],
        padding: const EdgeInsets.all(12),
        child: const Text(
          'Este usuario te bloqueó. No puedes enviar mensajes ni desbloquear este chat.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (_usuarioBloqueado) {
      return Container(
        width: double.infinity,
        color: Colors.red[50],
        padding: const EdgeInsets.all(12),
        child: Text(
          'Chat bloqueado entre usuario ${widget.miUsuarioId} y usuario $otroUsuarioId.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.blue[50],
      padding: const EdgeInsets.all(12),
      child: Text(
        'MatchSocial ${widget.sala.matchSocialId} · Chat habilitado por match',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
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
            : const Icon(Icons.lock_open, color: Colors.green),
        tooltip: 'Desbloquear usuario',
      );
    }

    if (_meBloqueoElOtro) {
      return IconButton(
        onPressed: null,
        icon: Icon(Icons.lock, color: Colors.grey.shade400),
        tooltip: 'No puedes desbloquear un bloqueo realizado por el otro usuario',
      );
    }

    if (_usuarioBloqueado) {
      return IconButton(
        onPressed: null,
        icon: Icon(Icons.lock, color: Colors.grey.shade400),
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
          : const Icon(Icons.block, color: Colors.red),
      tooltip: 'Bloquear usuario',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _usuarioBloqueado ? Colors.red[100] : Colors.blue[100],
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
                      color: _usuarioBloqueado ? Colors.red : Colors.blue,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otroUsuarioNombre ?? 'Usuario $otroUsuarioId',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _textoEstadoAppBar(),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
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