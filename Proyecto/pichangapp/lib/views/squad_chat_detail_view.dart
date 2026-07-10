import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/mensaje_squad.dart';
import '../models/squad.dart';
import '../models/squad_miembro.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'public_user_profile_view.dart';

class SquadChatDetailView extends StatefulWidget {
  final Squad squad;
  final int miUsuarioId;

  const SquadChatDetailView({
    super.key,
    required this.squad,
    required this.miUsuarioId,
  });

  @override
  State<SquadChatDetailView> createState() => _SquadChatDetailViewState();
}

class _SquadChatDetailViewState extends State<SquadChatDetailView> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  List<MensajeSquad> _mensajes = [];

  final Map<int, String> _nombresUsuarios = {};
  final Map<int, String?> _fotosUsuarios = {};

  Timer? _mensajesTimer;

  bool get _soyAdmin {
    return widget.squad.creadorId == widget.miUsuarioId;
  }

  @override
  void initState() {
    super.initState();
    _cargarMensajes();
    _iniciarFallbackMensajes();
  }

  @override
  void dispose() {
    _mensajesTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _iniciarFallbackMensajes() {
    _mensajesTimer?.cancel();

    _mensajesTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (!mounted) return;
        _sincronizarMensajesSilencioso();
      },
    );
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

  String _nombreVisibleUsuario(int usuarioId) {
    return _nombresUsuarios[usuarioId] ?? 'Usuario #$usuarioId';
  }

  String? _fotoVisibleUsuario(int usuarioId) {
    return _fotosUsuarios[usuarioId];
  }

  String _resolverNombreUsuario(Map<String, dynamic>? data, int usuarioId) {
    if (data == null) {
      return 'Usuario #$usuarioId';
    }

    final username = data['username']?.toString().trim() ??
        data['nombreUsuario']?.toString().trim() ??
        data['userName']?.toString().trim();

    if (username != null && username.isNotEmpty) {
      return username.startsWith('@') ? username : '@$username';
    }

    final nombre = data['nombre']?.toString().trim() ?? '';
    final apellido = data['apellido']?.toString().trim() ?? '';
    final nombreCompleto = '$nombre $apellido'.trim();

    if (nombreCompleto.isNotEmpty) {
      return nombreCompleto;
    }

    return 'Usuario #$usuarioId';
  }

  String? _resolverFotoUsuario(Map<String, dynamic>? data) {
    if (data == null) return null;

    dynamic value = data['fotoUrl'] ??
        data['foto_url'] ??
        data['profileImageUrl'] ??
        data['imagenPerfil'] ??
        data['avatarUrl'] ??
        data['foto'];

    final profile = data['profile'];

    if ((value == null || value.toString().trim().isEmpty) && profile is Map) {
      value = profile['fotoUrl'] ??
          profile['foto_url'] ??
          profile['profileImageUrl'] ??
          profile['imagenPerfil'] ??
          profile['avatarUrl'] ??
          profile['foto'];
    }

    if (value == null) return null;

    final texto = value.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return null;
    }

    return texto;
  }

  Future<void> _cargarNombreUsuario(int usuarioId) async {
    if (_nombresUsuarios.containsKey(usuarioId) &&
        _fotosUsuarios.containsKey(usuarioId)) {
      return;
    }

    try {
      final token = await _storage.read(key: 'jwt_token');

      if (token == null || token.isEmpty) {
        return;
      }

      final data = await _apiService.obtenerUsuarioPorId(
        usuarioId: usuarioId,
        token: token,
      );

      final nombre = _resolverNombreUsuario(data, usuarioId);
      final foto = _resolverFotoUsuario(data);

      if (!mounted) return;

      setState(() {
        _nombresUsuarios[usuarioId] = nombre;
        _fotosUsuarios[usuarioId] = foto;
      });
    } catch (e) {
      debugPrint('No se pudo cargar datos de usuario $usuarioId: $e');
    }
  }

  Future<void> _cargarNombresUsuarios(Iterable<int> usuariosIds) async {
    final idsUnicos = usuariosIds.toSet();

    for (final usuarioId in idsUnicos) {
      await _cargarNombreUsuario(usuarioId);
    }
  }

  bool _mensajesSonDistintos(List<MensajeSquad> nuevos) {
    if (_mensajes.length != nuevos.length) {
      return true;
    }

    for (int i = 0; i < nuevos.length; i++) {
      if (_mensajes[i].id != nuevos[i].id) {
        return true;
      }
    }

    return false;
  }

  Future<void> _cargarMensajes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.obtenerMensajesSquad(
        squadId: widget.squad.id,
        usuarioId: widget.miUsuarioId,
      );

      final mensajes = data
          .whereType<Map<String, dynamic>>()
          .map(MensajeSquad.fromJson)
          .where((mensaje) => mensaje.id != 0)
          .toList();

      await _cargarNombresUsuarios(
        mensajes.map((mensaje) => mensaje.remitenteId),
      );

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

  Future<void> _sincronizarMensajesSilencioso() async {
    if (!mounted || _isLoading) return;

    try {
      final data = await _apiService.obtenerMensajesSquad(
        squadId: widget.squad.id,
        usuarioId: widget.miUsuarioId,
      );

      final mensajes = data
          .whereType<Map<String, dynamic>>()
          .map(MensajeSquad.fromJson)
          .where((mensaje) => mensaje.id != 0)
          .toList();

      await _cargarNombresUsuarios(
        mensajes.map((mensaje) => mensaje.remitenteId),
      );

      if (!mounted) return;

      if (_mensajesSonDistintos(mensajes)) {
        setState(() {
          _mensajes = mensajes;
        });
      }
    } catch (e) {
      debugPrint('No se pudo sincronizar mensajes squad: $e');
    }
  }

  void _insertarMensajeSiNoExiste(MensajeSquad nuevoMensaje) {
    if (!mounted) return;

    setState(() {
      final existe = _mensajes.any((m) => m.id == nuevoMensaje.id);

      if (!existe) {
        _mensajes.insert(0, nuevoMensaje);
      }
    });
  }

  MensajeSquad _mensajeTemporal(String contenido) {
    return MensajeSquad(
      id: -DateTime.now().millisecondsSinceEpoch,
      squadId: widget.squad.id,
      remitenteId: widget.miUsuarioId,
      contenido: contenido,
      fechaEnvio: DateTime.now().toIso8601String(),
    );
  }

  Future<void> _enviarMensaje() async {
    final contenido = _messageController.text.trim();

    if (contenido.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final respuesta = await _apiService.enviarMensajeSquad(
      squadId: widget.squad.id,
      remitenteId: widget.miUsuarioId,
      contenido: contenido,
    );

    if (!mounted) return;

    if (respuesta != null) {
      _messageController.clear();

      final mensaje = MensajeSquad.fromJson(respuesta);

      await _cargarNombreUsuario(widget.miUsuarioId);

      _insertarMensajeSiNoExiste(
        mensaje.id == 0 ? _mensajeTemporal(contenido) : mensaje,
      );

      await _sincronizarMensajesSilencioso();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar el mensaje al squad.'),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });
  }

  Future<List<SquadMiembro>> _obtenerMiembros() async {
    final data = await _apiService.listarMiembrosSquad(
      squadId: widget.squad.id,
    );

    final miembros = data
        .whereType<Map<String, dynamic>>()
        .map(SquadMiembro.fromJson)
        .where((miembro) => miembro.usuarioId != 0)
        .toList();

    await _cargarNombresUsuarios(
      miembros.map((miembro) => miembro.usuarioId),
    );

    return miembros;
  }

  Future<bool> _confirmarExpulsion(SquadMiembro miembro) async {
    final nombre = _nombreVisibleUsuario(miembro.usuarioId);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Expulsar miembro',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          '¿Quieres expulsar a $nombre del squad?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            child: const Text('Expulsar'),
          ),
        ],
      ),
    );

    return confirmar == true;
  }

  Widget _avatarUsuario(int usuarioId) {
    final foto = _fotoVisibleUsuario(usuarioId);

    return CircleAvatar(
      backgroundColor: AppTheme.primary.withOpacity(0.18),
      backgroundImage: foto != null ? NetworkImage(foto) : null,
      child: foto == null
          ? const Icon(
              Icons.person,
              color: AppTheme.primarySoft,
            )
          : null,
    );
  }

  Future<void> _mostrarParticipantes() async {
    List<SquadMiembro> miembros = [];
    bool cargando = true;
    bool cargaIniciada = false;
    bool expulsando = false;
    String? error;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> cargar() async {
              try {
                final data = await _obtenerMiembros();

                if (!context.mounted) return;

                setSheetState(() {
                  miembros = data;
                  cargando = false;
                  error = null;
                });
              } catch (e) {
                if (!context.mounted) return;

                setSheetState(() {
                  cargando = false;
                  error = e.toString();
                });
              }
            }

            if (!cargaIniciada) {
              cargaIniciada = true;
              Future.microtask(cargar);
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.68,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Participantes · ${widget.squad.nombre}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${miembros.length} integrantes',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (cargando)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primarySoft,
                            ),
                          ),
                        )
                      else if (error != null)
                        Expanded(
                          child: Center(
                            child: Text(
                              'Error al cargar participantes:\n$error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: miembros.length,
                            separatorBuilder: (_, __) => const Divider(
                              color: AppTheme.border,
                            ),
                            itemBuilder: (context, index) {
                              final miembro = miembros[index];
                              final nombre = _nombreVisibleUsuario(
                                miembro.usuarioId,
                              );

                              final puedeExpulsar = _soyAdmin &&
                                  miembro.usuarioId != widget.miUsuarioId &&
                                  !miembro.esAdmin;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                onTap: () {
                                  Navigator.pop(context);
                                  _abrirPerfilUsuario(miembro.usuarioId);
                                },
                                leading: _avatarUsuario(miembro.usuarioId),
                                title: Text(
                                  nombre,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  miembro.esAdmin
                                      ? 'Administrador'
                                      : 'Miembro',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                trailing: puedeExpulsar
                                    ? IconButton(
                                        onPressed: expulsando
                                            ? null
                                            : () async {
                                                final confirmado =
                                                    await _confirmarExpulsion(
                                                  miembro,
                                                );

                                                if (!confirmado) return;

                                                setSheetState(() {
                                                  expulsando = true;
                                                });

                                                final ok = await _apiService
                                                    .expulsarMiembroSquad(
                                                  squadId: widget.squad.id,
                                                  adminId: widget.miUsuarioId,
                                                  usuarioId: miembro.usuarioId,
                                                );

                                                if (!context.mounted) return;

                                                setSheetState(() {
                                                  expulsando = false;

                                                  if (ok) {
                                                    miembros.removeWhere(
                                                      (item) =>
                                                          item.usuarioId ==
                                                          miembro.usuarioId,
                                                    );
                                                  }
                                                });

                                                if (!mounted) return;

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      ok
                                                          ? '$nombre fue expulsado del squad.'
                                                          : 'No se pudo expulsar a $nombre.',
                                                    ),
                                                  ),
                                                );
                                              },
                                        icon: const Icon(
                                          Icons.person_remove,
                                          color: AppTheme.danger,
                                        ),
                                        tooltip: 'Expulsar miembro',
                                      )
                                    : null,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _mensajeBubble(MensajeSquad mensaje) {
    final esMio = mensaje.remitenteId == widget.miUsuarioId;
    final nombre = _nombreVisibleUsuario(mensaje.remitenteId);

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: esMio
                    ? null
                    : () => _abrirPerfilUsuario(mensaje.remitenteId),
                child: Text(
                  esMio ? 'Tú' : nombre,
                  style: TextStyle(
                    color: esMio ? Colors.white70 : AppTheme.primarySoft,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    decoration: esMio ? null : TextDecoration.underline,
                  ),
                ),
              ),
            ),
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
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primarySoft,
          ),
        ),
      );
    }

    if (_error != null) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error al cargar chat grupal:\n$_error',
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
            'Aún no hay mensajes en este squad.\nEscribe el primero.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _cargarMensajes,
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
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Mensaje al squad...',
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

  Widget _bannerSquad() {
    return Container(
      width: double.infinity,
      color: AppTheme.primary.withOpacity(0.12),
      padding: const EdgeInsets.all(12),
      child: Text(
        '${widget.squad.deporteTexto} · ${widget.squad.integrantesTexto}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.primarySoft,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _iconoGrupo() {
    return InkWell(
      onTap: _mostrarParticipantes,
      borderRadius: BorderRadius.circular(999),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.primary.withOpacity(0.18),
        child: const Icon(
          Icons.groups,
          color: AppTheme.primarySoft,
          size: 20,
        ),
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
        title: Row(
          children: [
            _iconoGrupo(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.squad.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _mostrarParticipantes,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Ver participantes',
          ),
          IconButton(
            onPressed: _cargarMensajes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _bannerSquad(),
          _contenidoMensajes(),
          _inputMensaje(),
        ],
      ),
    );
  }
}