import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';

class ApiService {
  // Cambiar a '168.129.178.109' para la nube, o '127.0.0.1' / '10.0.2.2' para local
  static const String _serverIp = '168.129.178.109';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static String get usuarioBaseUrl {
    return 'http://$_serverIp:8001';
  }

  static String get matchBaseUrl {
    return 'http://$_serverIp:8081';
  }

  static String get comunicacionBaseUrl {
    return 'http://$_serverIp:8082';
  }

  // Nota: Ya no se usa WebSocket directo debido a la migración a Supabase Realtime,
  // pero lo dejamos por compatibilidad.
  static String get comunicacionWsBaseUrl {
    return 'ws://$_serverIp:8082';
  }

  static String get seguridadBaseUrl {
    return 'http://$_serverIp:8004';
  }

  static String get notificacionBaseUrl {
    return 'http://$_serverIp:8083';
  }

  Future<Map<String, String>> _squadAuthHeaders() async {
    final token = await _secureStorage.read(key: 'jwt_token');

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> registrarUsuario(Map<String, dynamic> userData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$usuarioBaseUrl/api/users'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }

      debugPrint('Error registro: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error cliente registro: $e');
      return false;
    }
  }

  Future<LoginResponse?> loginUsuario(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$usuarioBaseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LoginResponse.fromJson(data);
      }

      debugPrint('Error login: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error cliente login: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> obtenerUsuarioActual(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$usuarioBaseUrl/api/users/me'),
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      debugPrint('Error usuario actual: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error cliente usuario actual: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> obtenerUsuarioPorId({
    required int usuarioId,
    required String token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$usuarioBaseUrl/api/users/$usuarioId'),
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      debugPrint('Error obtener usuario por id: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error cliente obtener usuario por id: $e');
      return null;
    }
  }

  Future<List<dynamic>> descubrirUsuarios({
    required int excludeId,
    required String token,
    double distanciaMinKm = 0,
    double distanciaMaxKm = 500,
    int edadMin = 18,
    int edadMax = 80,
    String sexo = 'Todos',
  }) async {
    final uri = Uri.parse('$usuarioBaseUrl/api/users/discover').replace(
      queryParameters: {
        'excludeId': excludeId.toString(),
        'distanciaMinKm': distanciaMinKm.toStringAsFixed(0),
        'distanciaMaxKm': distanciaMaxKm.toStringAsFixed(0),
        'edadMin': edadMin.toString(),
        'edadMax': edadMax.toString(),
        'sexo': sexo,
        'diasMaxUbicacion': '30',
      },
    );

    final response = await http
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception('Error al descubrir usuarios: ${response.statusCode} ${response.body}');
  }

  Future<List<int>> obtenerUsuariosInteractuados({
    required int usuarioId,
  }) async {
    final response = await http
        .get(
          Uri.parse('$matchBaseUrl/api/v1/interacciones/usuarios-interactuados/$usuarioId'),
          headers: {
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data
            .map((item) => int.tryParse(item.toString()))
            .whereType<int>()
            .toList();
      }

      return [];
    }

    throw Exception('Error al obtener usuarios interactuados: ${response.statusCode}');
  }

  Future<bool> enviarInteraccion({
    required int usuarioOrigenId,
    required int usuarioDestinoId,
    required String tipo,
  }) async {
    final response = await http
        .post(
          Uri.parse('$matchBaseUrl/api/v1/interacciones'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'usuarioOrigenId': usuarioOrigenId,
            'usuarioDestinoId': usuarioDestinoId,
            'tipo': tipo,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hayMatch'] == true;
    }

    String mensaje = 'No se pudo registrar la interacción.';

    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        mensaje = data['message'] ??
            data['mensaje'] ??
            data['error'] ??
            mensaje;
      }
    } catch (_) {
      mensaje = 'Error ${response.statusCode} al registrar interacción.';
    }

    throw Exception(mensaje);
  }

  Future<List<dynamic>> obtenerSalasUsuario({
    required int usuarioId,
    required String token,
  }) async {
    final response = await http
        .get(
          Uri.parse('$comunicacionBaseUrl/api/v1/chat/salas/user/$usuarioId'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception('Error salas: ${response.statusCode} ${response.body}');
  }

  Future<List<dynamic>> obtenerMensajes({
    required int salaId,
    required String token,
  }) async {
    final response = await http
        .get(
          Uri.parse('$comunicacionBaseUrl/api/v1/chat/salas/$salaId/mensajes?page=0&size=50'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      if (data is Map<String, dynamic> && data['content'] is List) {
        return data['content'] as List<dynamic>;
      }

      return [];
    }

    throw Exception('Error mensajes: ${response.statusCode} ${response.body}');
  }

  Future<bool> enviarMensaje({
    required int salaId,
    required int remitenteId,
    required String contenido,
    String? tipoMensaje,
    String? mediaUrl,
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$comunicacionBaseUrl/api/v1/chat/salas/$salaId/mensajes'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'remitenteId': remitenteId,
              'contenido': contenido,
              'tipoMensaje': tipoMensaje ?? 'TEXTO',
              'mediaUrl': mediaUrl,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }

      debugPrint('Error enviar mensaje: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error cliente enviar mensaje: $e');
      return false;
    }
  }

  Future<bool> bloquearUsuario({
    required int idUsuarioOrigen,
    required int idUsuarioBloqueado,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$seguridadBaseUrl/api/safety/bloquear'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idUsuarioOrigen': idUsuarioOrigen,
              'idUsuarioBloqueado': idUsuarioBloqueado,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }

      if (response.statusCode == 409 || response.statusCode == 500) {
        final body = response.body.toLowerCase();

        if (body.contains('ya se encuentra bloqueado') ||
            body.contains('already') ||
            body.contains('bloqueado')) {
          return true;
        }
      }

      debugPrint('Error bloquear usuario: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error cliente bloquear usuario: $e');
      return false;
    }
  }

  Future<bool> desbloquearUsuario({
    required int idUsuarioOrigen,
    required int idUsuarioBloqueado,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$seguridadBaseUrl/api/safety/desbloquear'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idUsuarioOrigen': idUsuarioOrigen,
              'idUsuarioBloqueado': idUsuarioBloqueado,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      debugPrint('Error desbloquear usuario: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error cliente desbloquear usuario: $e');
      return false;
    }
  }

  Future<bool> actualizarPerfilUsuario({
    required String token,
    required dynamic userId,
    required Map<String, dynamic> datosActualizacion,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$usuarioBaseUrl/api/users/$userId/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(datosActualizacion),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }

      debugPrint('Error actualizar perfil: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error cliente actualizar perfil: $e');
      return false;
    }
  }

  Future<bool> existeBloqueoEntreUsuarios({
    required int usuarioAId,
    required int usuarioBId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$seguridadBaseUrl/api/safety/bloqueos/existe-entre?usuarioAId=$usuarioAId&usuarioBId=$usuarioBId',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body.trim().toLowerCase();
        return body == 'true';
      }

      debugPrint('Error verificar bloqueo: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error cliente verificar bloqueo: $e');
      return false;
    }
  }

  Future<bool?> tokenSigueVigente(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$usuarioBaseUrl/api/users/me'),
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return true;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return false;
      }

      return null;
    } catch (e) {
      debugPrint('No se pudo validar token: $e');
      return null;
    }
  }

  Future<List<dynamic>> obtenerNotificacionesUsuario({
    required int usuarioId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$notificacionBaseUrl/api/notificaciones/user/$usuarioId'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }

        return [];
      }

      debugPrint('Error obtener notificaciones: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Error cliente obtener notificaciones: $e');
      return [];
    }
  }

  Future<bool> marcarNotificacionComoLeida({
    required int notificacionId,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$notificacionBaseUrl/api/notificaciones/$notificacionId/leida'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error cliente marcar notificación como leída: $e');
      return false;
    }
  }

  bool _valorLeidaComoBool(dynamic valor) {
    if (valor is bool) {
      return valor;
    }

    if (valor is String) {
      return valor.toLowerCase() == 'true';
    }

    if (valor is int) {
      return valor == 1;
    }

    return false;
  }

  Future<int> marcarNotificacionesMensajeComoLeidas({
    required int usuarioId,
  }) async {
    try {
      final data = await obtenerNotificacionesUsuario(
        usuarioId: usuarioId,
      );

      int totalMarcadas = 0;

      for (final item in data) {
        if (item is! Map) continue;

        final id = int.tryParse(item['id']?.toString() ?? '');
        final tipo = item['tipo']?.toString().toUpperCase().trim() ?? '';
        final leida = _valorLeidaComoBool(item['leida']);

        if (id == null) continue;

        if (tipo == 'MENSAJE' && !leida) {
          final ok = await marcarNotificacionComoLeida(
            notificacionId: id,
          );

          if (ok) {
            totalMarcadas++;
          }
        }
      }

      if (totalMarcadas > 0) {
        debugPrint(
          'Notificaciones de mensaje marcadas como leídas: $totalMarcadas',
        );
      }

      return totalMarcadas;
    } catch (e) {
      debugPrint('Error marcando notificaciones de mensaje como leídas: $e');
      return 0;
    }
  }

  Future<List<dynamic>> listarBloqueosPorUsuario({
    required int usuarioId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$seguridadBaseUrl/api/safety/bloqueos/user/$usuarioId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }

        return [];
      }

      debugPrint('Error listar bloqueos por usuario: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Error cliente listar bloqueos por usuario: $e');
      return [];
    }
  }

  Future<bool> usuarioBloqueoA({
    required int usuarioOrigenId,
    required int usuarioBloqueadoId,
  }) async {
    try {
      final bloqueos = await listarBloqueosPorUsuario(
        usuarioId: usuarioOrigenId,
      );

      for (final item in bloqueos) {
        if (item is! Map) continue;

        final idBloqueado = int.tryParse(
          item['idUsuarioBloqueado']?.toString() ?? '',
        );

        if (idBloqueado == usuarioBloqueadoId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error verificando dirección del bloqueo: $e');
      return false;
    }
  }

  Future<bool> reportarUsuario({
    required int idUsuarioDenunciante,
    required int idUsuarioDenunciado,
    required String motivo,
    required String descripcion,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$seguridadBaseUrl/api/safety/reportar'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idUsuarioDenunciante': idUsuarioDenunciante,
              'idUsuarioDenunciado': idUsuarioDenunciado,
              'motivo': motivo,
              'descripcion': descripcion,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }

      debugPrint('Error reportar usuario: ${response.statusCode}');
      debugPrint('Respuesta backend: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error cliente reportar usuario: $e');
      return false;
    }
  }

  Future<List<dynamic>> descubrirSquads({
    required int usuarioId,
    String deporte = 'Todos',
    double? latitud,
    double? longitud,
    double distanciaMaxKm = 500,
  }) async {
    try {
      final query = <String, String>{
        'usuarioId': usuarioId.toString(),
        'deporte': deporte,
        'distanciaMaxKm': distanciaMaxKm.toStringAsFixed(0),
      };

      if (latitud != null) {
        query['latitud'] = latitud.toString();
      }

      if (longitud != null) {
        query['longitud'] = longitud.toString();
      }

      final uri = Uri.parse('$comunicacionBaseUrl/api/v1/squads/discover')
          .replace(queryParameters: query);

      final response = await http
          .get(
            uri,
            headers: await _squadAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('DESCUBRIR SQUADS STATUS: ${response.statusCode}');
      debugPrint('DESCUBRIR SQUADS RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }

        return [];
      }

      return [];
    } catch (e) {
      debugPrint('Error cliente descubrir squads: $e');
      return [];
    }
  }

  Future<bool> crearSquad({
    required int creadorId,
    required String nombre,
    required String deporte,
    required String descripcion,
    required int maxIntegrantes,
    double? latitud,
    double? longitud,
  }) async {
    try {
      final body = {
        'creadorId': creadorId,
        'nombre': nombre.trim(),
        'deporte': deporte.trim().toUpperCase(),
        'descripcion': descripcion.trim(),
        'maxIntegrantes': maxIntegrantes,
        if (latitud != null) 'latitud': latitud,
        if (longitud != null) 'longitud': longitud,
      };

      debugPrint('CREAR SQUAD URL: $comunicacionBaseUrl/api/v1/squads');
      debugPrint('CREAR SQUAD BODY: ${jsonEncode(body)}');

      final response = await http
          .post(
            Uri.parse('$comunicacionBaseUrl/api/v1/squads'),
            headers: await _squadAuthHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('CREAR SQUAD STATUS: ${response.statusCode}');
      debugPrint('CREAR SQUAD RESPONSE: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('ERROR CLIENTE CREAR SQUAD: $e');
      return false;
    }
  }

  Future<List<dynamic>> obtenerMisSquads({
    required int usuarioId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$comunicacionBaseUrl/api/v1/squads/mis-squads/$usuarioId'),
            headers: await _squadAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('MIS SQUADS STATUS: ${response.statusCode}');
      debugPrint('MIS SQUADS RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }

        return [];
      }

      return [];
    } catch (e) {
      debugPrint('Error cliente obtener mis squads: $e');
      return [];
    }
  }

  Future<bool> solicitarEntradaSquad({
    required int squadId,
    required int usuarioId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$comunicacionBaseUrl/api/v1/squads/$squadId/solicitudes'),
            headers: await _squadAuthHeaders(),
            body: jsonEncode({
              'usuarioId': usuarioId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('SOLICITAR SQUAD STATUS: ${response.statusCode}');
      debugPrint('SOLICITAR SQUAD RESPONSE: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }

      final body = response.body.toLowerCase();

      if (body.contains('pendiente') || body.contains('ya existe')) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error cliente solicitar entrada squad: $e');
      return false;
    }
  }

  Future<List<dynamic>> obtenerMensajesSquad({
    required int squadId,
    required int usuarioId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$comunicacionBaseUrl/api/v1/squads/$squadId/mensajes?usuarioId=$usuarioId&page=0&size=50',
            ),
            headers: await _squadAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('MENSAJES SQUAD STATUS: ${response.statusCode}');
      debugPrint('MENSAJES SQUAD RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic> && data['content'] is List) {
          return data['content'] as List<dynamic>;
        }

        if (data is List) {
          return data;
        }

        return [];
      }

      return [];
    } catch (e) {
      debugPrint('Error cliente obtener mensajes squad: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> enviarMensajeSquad({
    required int squadId,
    required int remitenteId,
    required String contenido,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$comunicacionBaseUrl/api/v1/squads/$squadId/mensajes'),
            headers: await _squadAuthHeaders(),
            body: jsonEncode({
              'remitenteId': remitenteId,
              'contenido': contenido,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('ENVIAR MENSAJE SQUAD STATUS: ${response.statusCode}');
      debugPrint('ENVIAR MENSAJE SQUAD RESPONSE: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data;
        }

        return null;
      }

      return null;
    } catch (e) {
      debugPrint('Error cliente enviar mensaje squad: $e');
      return null;
    }
  }

  Future<List<dynamic>> listarSolicitudesSquad({
    required int squadId,
    required int adminId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$comunicacionBaseUrl/api/v1/squads/$squadId/solicitudes?adminId=$adminId',
            ),
            headers: await _squadAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('SOLICITUDES SQUAD STATUS: ${response.statusCode}');
      debugPrint('SOLICITUDES SQUAD RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }

        return [];
      }

      return [];
    } catch (e) {
      debugPrint('Error cliente listar solicitudes squad: $e');
      return [];
    }
  }

  Future<bool> aceptarSolicitudSquad({
    required int solicitudId,
    required int adminId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$comunicacionBaseUrl/api/v1/squads/solicitudes/$solicitudId/aceptar?adminId=$adminId',
            ),
            headers: await _squadAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('ACEPTAR SOLICITUD SQUAD STATUS: ${response.statusCode}');
      debugPrint('ACEPTAR SOLICITUD SQUAD RESPONSE: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error cliente aceptar solicitud squad: $e');
      return false;
    }
  }

  Future<bool> rechazarSolicitudSquad({
    required int solicitudId,
    required int adminId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '$comunicacionBaseUrl/api/v1/squads/solicitudes/$solicitudId/rechazar?adminId=$adminId',
            ),
            headers: await _squadAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('RECHAZAR SOLICITUD SQUAD STATUS: ${response.statusCode}');
      debugPrint('RECHAZAR SOLICITUD SQUAD RESPONSE: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error cliente rechazar solicitud squad: $e');
      return false;
    }
  }

    Future<List<dynamic>> listarMiembrosSquad({
    required int squadId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$comunicacionBaseUrl/api/v1/squads/$squadId/miembros'),
            headers: await _squadAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('MIEMBROS SQUAD STATUS: ${response.statusCode}');
      debugPrint('MIEMBROS SQUAD RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }

        return [];
      }

      return [];
    } catch (e) {
      debugPrint('Error cliente listar miembros squad: $e');
      return [];
    }
  }

  Future<bool> expulsarMiembroSquad({
    required int squadId,
    required int adminId,
    required int usuarioId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
              '$comunicacionBaseUrl/api/v1/squads/$squadId/miembros/$usuarioId?adminId=$adminId',
            ),
            headers: await _squadAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('EXPULSAR MIEMBRO SQUAD STATUS: ${response.statusCode}');
      debugPrint('EXPULSAR MIEMBRO SQUAD RESPONSE: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error cliente expulsar miembro squad: $e');
      return false;
    }
  }
}