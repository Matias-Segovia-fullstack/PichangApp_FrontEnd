import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/mensaje_chat.dart';
import '../models/sala_chat.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'chat_detail_view.dart';

class ChatsView extends StatefulWidget {
  const ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String? _error;
  String? _token;
  int? _miUsuarioId;

  List<SalaChat> _salas = [];
  Map<int, bool> _salasBloqueadas = {};
  Map<int, String> _nombresUsuarios = {};
  Map<int, String?> _fotosUsuarios = {};
  Map<int, MensajeChat?> _ultimoMensajePorSala = {};
  Map<int, DateTime?> _ultimaActividadPorSala = {};

  @override
  void initState() {
    super.initState();
    _cargarSalas();
  }

  DateTime _parseFecha(String? valor) {
    final fecha = DateTime.tryParse(valor ?? '');
    return fecha?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _dosDigitos(int numero) {
    return numero.toString().padLeft(2, '0');
  }

  String _formatearFechaCorta(DateTime? fecha) {
    if (fecha == null || fecha.millisecondsSinceEpoch == 0) {
      return '';
    }

    final ahora = DateTime.now();

    final esMismoDia = fecha.year == ahora.year &&
        fecha.month == ahora.month &&
        fecha.day == ahora.day;

    if (esMismoDia) {
      return '${_dosDigitos(fecha.hour)}:${_dosDigitos(fecha.minute)}';
    }

    final esMismoAnio = fecha.year == ahora.year;

    if (esMismoAnio) {
      return '${_dosDigitos(fecha.day)}/${_dosDigitos(fecha.month)}';
    }

    return '${_dosDigitos(fecha.day)}/${_dosDigitos(fecha.month)}/${fecha.year.toString().substring(2)}';
  }

  String _textoUltimoMensaje(MensajeChat? mensaje, int miUsuarioId) {
    if (mensaje == null) {
      return 'Aún no hay mensajes';
    }

    final esMio = mensaje.remitenteId == miUsuarioId;
    final esImagen =
        (mensaje.tipoMensaje?.toUpperCase() == 'IMAGEN') ||
        ((mensaje.mediaUrl ?? '').isNotEmpty);

    if (esImagen) {
      return esMio ? 'Tú enviaste una imagen' : 'Te envió una imagen';
    }

    final contenido = mensaje.contenido.trim();

    if (contenido.isEmpty) {
      return esMio ? 'Tú enviaste un mensaje' : 'Nuevo mensaje';
    }

    return esMio ? 'Tú: $contenido' : contenido;
  }

  Future<void> _cargarSalas() async {
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

      final data = await _apiService.obtenerSalasUsuario(
        usuarioId: userId,
        token: token,
      );

      final salas = data
          .whereType<Map<String, dynamic>>()
          .map(SalaChat.fromJson)
          .where((sala) => sala.id != 0)
          .toList();

      final Map<int, bool> bloqueos = {};
      final Map<int, String> nombres = {};
      final Map<int, String?> fotos = {};
      final Map<int, MensajeChat?> ultimosMensajes = {};
      final Map<int, DateTime?> ultimasFechas = {};

      for (final sala in salas) {
        final otroUsuarioId = sala.obtenerOtroUsuarioId(userId);

        if (otroUsuarioId != 0) {
          final existeBloqueo = await _apiService.existeBloqueoEntreUsuarios(
            usuarioAId: userId,
            usuarioBId: otroUsuarioId,
          );
          bloqueos[sala.id] = existeBloqueo;

          final otroUsuario = await _apiService.obtenerUsuarioPorId(
            usuarioId: otroUsuarioId,
            token: token,
          );

          if (otroUsuario != null && otroUsuario['nombre'] != null) {
            String nombreMostrado = otroUsuario['nombre'].toString();

            if (otroUsuario['apellido'] != null) {
              nombreMostrado += ' ${otroUsuario['apellido']}';
            }

            nombres[otroUsuarioId] = nombreMostrado;
          } else if (otroUsuario != null && otroUsuario['username'] != null) {
            nombres[otroUsuarioId] = otroUsuario['username'].toString();
          } else {
            nombres[otroUsuarioId] = 'Usuario $otroUsuarioId';
          }

          if (otroUsuario != null && otroUsuario['profile'] != null) {
            fotos[otroUsuarioId] = otroUsuario['profile']['fotoUrl'];
          } else {
            fotos[otroUsuarioId] = null;
          }
        } else {
          bloqueos[sala.id] = false;
          nombres[0] = 'Usuario desconocido';
          fotos[0] = null;
        }

        final mensajesData = await _apiService.obtenerMensajes(
          salaId: sala.id,
          token: token,
        );

        final mensajes = mensajesData
            .whereType<Map<String, dynamic>>()
            .map(MensajeChat.fromJson)
            .where((m) => m.id != 0)
            .toList();

        mensajes.sort(
          (a, b) => _parseFecha(b.fechaEnvio).compareTo(_parseFecha(a.fechaEnvio)),
        );

        final ultimoMensaje = mensajes.isNotEmpty ? mensajes.first : null;
        ultimosMensajes[sala.id] = ultimoMensaje;

        ultimasFechas[sala.id] = ultimoMensaje != null
            ? _parseFecha(ultimoMensaje.fechaEnvio)
            : _parseFecha(sala.fechaCreacion);
      }

      salas.sort((a, b) {
        final fechaA =
            ultimasFechas[a.id] ?? _parseFecha(a.fechaCreacion);
        final fechaB =
            ultimasFechas[b.id] ?? _parseFecha(b.fechaCreacion);

        return fechaB.compareTo(fechaA);
      });

      if (!mounted) return;

      setState(() {
        _token = token;
        _miUsuarioId = userId;
        _salas = salas;
        _salasBloqueadas = bloqueos;
        _nombresUsuarios = nombres;
        _fotosUsuarios = fotos;
        _ultimoMensajePorSala = ultimosMensajes;
        _ultimaActividadPorSala = ultimasFechas;
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

  Widget _estadoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppTheme.primarySoft,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes chats',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando tengas un match, se creará una sala automáticamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarSalas,
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar chats'),
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
            const SizedBox(height: 16),
            const Text(
              'No se pudieron cargar los chats',
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
              onPressed: _cargarSalas,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaSalas() {
    final miUsuarioId = _miUsuarioId!;
    final token = _token!;

    return RefreshIndicator(
      onRefresh: _cargarSalas,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        itemCount: _salas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final sala = _salas[index];
          final otroUsuarioId = sala.obtenerOtroUsuarioId(miUsuarioId);
          final esBloqueada = _salasBloqueadas[sala.id] ?? false;
          final nombreUsuario =
              _nombresUsuarios[otroUsuarioId] ?? 'Usuario $otroUsuarioId';
          final fotoUrl = _fotosUsuarios[otroUsuarioId];
          final ultimoMensaje = _ultimoMensajePorSala[sala.id];
          final ultimaFecha = _ultimaActividadPorSala[sala.id];

          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailView(
                    sala: sala,
                    miUsuarioId: miUsuarioId,
                    token: token,
                    otroUsuarioNombre: nombreUsuario,
                    otroUsuarioFoto: fotoUrl,
                  ),
                ),
              );

              await _cargarSalas();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: esBloqueada ? Colors.red.shade400 : AppTheme.border,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: esBloqueada
                            ? AppTheme.danger
                            : AppTheme.primarySoft,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.surfaceAlt,
                      backgroundImage: (!esBloqueada &&
                              fotoUrl != null &&
                              fotoUrl.isNotEmpty)
                          ? NetworkImage(fotoUrl)
                          : null,
                      child: (!esBloqueada &&
                              fotoUrl != null &&
                              fotoUrl.isNotEmpty)
                          ? null
                          : Icon(
                              esBloqueada ? Icons.block : Icons.person,
                              color: esBloqueada
                                  ? AppTheme.danger
                                  : AppTheme.primarySoft,
                            ),
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
                                nombreUsuario,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatearFechaCorta(ultimaFecha),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _textoUltimoMensaje(ultimoMensaje, miUsuarioId),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        if (esBloqueada) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Chat bloqueado',
                            style: TextStyle(
                              color: AppTheme.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
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
    } else if (_salas.isEmpty) {
      body = _estadoVacio();
    } else {
      body = _listaSalas();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Chats Deportivos',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _cargarSalas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}