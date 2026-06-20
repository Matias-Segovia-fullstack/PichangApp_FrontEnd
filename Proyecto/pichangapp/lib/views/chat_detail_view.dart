import 'dart:convert';
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

  const ChatDetailView({
    super.key,
    required this.sala,
    required this.miUsuarioId,
    required this.token,
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
  bool _usuarioBloqueado = false;

  RealtimeChannel? _realtimeChannel;

  String? _error;
  List<MensajeChat> _mensajes = [];

  int get otroUsuarioId {
    return widget.sala.obtenerOtroUsuarioId(widget.miUsuarioId);
  }

  @override
  void initState() {
    super.initState();
    _inicializarChat();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _inicializarChat() async {
    await _verificarBloqueoExistente();
    await _cargarMensajes();
    _conectarWebSocket();
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
            
            // Adaptar las claves si vienen en snake_case desde la base de datos
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
            }
          },
        )
        .subscribe();
  }

  Future<void> _verificarBloqueoExistente() async {
    final existeBloqueo = await _apiService.existeBloqueoEntreUsuarios(
      usuarioAId: widget.miUsuarioId,
      usuarioBId: otroUsuarioId,
    );

    if (!mounted) return;

    setState(() {
      _usuarioBloqueado = existeBloqueo;
    });
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
      // El mensaje llegará por el WebSocket y se insertará automáticamente
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
          // El mensaje llegará por el WebSocket y se insertará automáticamente
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
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bloquear usuario'),
        content: Text(
          '¿Quieres bloquear al usuario $otroUsuarioId? Después del bloqueo no debería poder seguir enviando mensajes contigo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquear'),
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

      setState(() {
        _isBlocking = false;
        _usuarioBloqueado = bloqueado;
      });

      if (bloqueado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Usuario bloqueado. El chat quedó deshabilitado.',
            ),
          ),
        );
      } else {
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

  Widget _mensajeBubble(MensajeChat mensaje) {
    final esMio = mensaje.remitenteId == widget.miUsuarioId;
    final esImagen = mensaje.tipoMensaje == 'IMAGEN' || 
                     (mensaje.mediaUrl != null && mensaje.mediaUrl!.isNotEmpty) ||
                     (mensaje.contenido.startsWith('http') && mensaje.contenido.contains('supabase.co/storage'));

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 310),
        decoration: BoxDecoration(
          color: esMio ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (esImagen)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  mensaje.mediaUrl ?? mensaje.contenido,
                  width: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Text('Error al cargar imagen', style: TextStyle(color: Colors.red)),
                ),
              )
            else
              Text(
                mensaje.contenido,
                style: TextStyle(
                  color: esMio ? Colors.white : Colors.black,
                  fontSize: 15,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Usuario ${mensaje.remitenteId}',
              style: TextStyle(
                color: esMio ? Colors.white70 : Colors.black54,
                fontSize: 11,
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
    if (_usuarioBloqueado) {
      return SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          color: Colors.red[50],
          child: const Text(
            'Chat bloqueado. Ya no se pueden enviar mensajes en esta sala.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 4,
              ),
            ),
            IconButton(
              onPressed: _isSending ? null : _subirImagen,
              icon: const Icon(Icons.camera_alt, color: Colors.grey),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              onPressed: _isSending ? null : _enviarMensaje,
              icon: _isSending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerEstado() {
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
    if (_usuarioBloqueado) {
      return const Padding(
        padding: EdgeInsets.only(right: 12),
        child: Icon(Icons.block, color: Colors.red),
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
        title: Text('Usuario $otroUsuarioId · Sala ${widget.sala.id}'),
        actions: [
          IconButton(
            onPressed: () async {
              await _verificarBloqueoExistente();
              await _cargarMensajes();
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