import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class LocationSyncService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> sincronizarSiPermisoPrevio() async {
    try {
      final bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();

      if (!servicioHabilitado) {
        return false;
      }

      final LocationPermission permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever ||
          permiso == LocationPermission.unableToDetermine) {
        return false;
      }

      return _sincronizarUbicacionActual();
    } catch (e) {
      debugPrint('No se pudo sincronizar ubicación previa: $e');
      return false;
    }
  }

  Future<bool> sincronizarSolicitandoPermiso() async {
    try {
      final bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();

      if (!servicioHabilitado) {
        throw Exception('Activa la ubicación del dispositivo o navegador para usar Discover.');
      }

      LocationPermission permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied) {
        throw Exception('Permiso de ubicación rechazado.');
      }

      if (permiso == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación bloqueado. Habilítalo desde el navegador o sistema.');
      }

      if (permiso == LocationPermission.unableToDetermine) {
        throw Exception('No se pudo determinar el permiso de ubicación.');
      }

      return _sincronizarUbicacionActual();
    } catch (e) {
      debugPrint('No se pudo sincronizar ubicación solicitando permiso: $e');
      rethrow;
    }
  }

  Future<bool> _sincronizarUbicacionActual() async {
    final token = await _storage.read(key: 'jwt_token');
    final userIdString = await _storage.read(key: 'user_id');

    if (token == null || token.isEmpty || userIdString == null || userIdString.isEmpty) {
      return false;
    }

    final userId = int.tryParse(userIdString);

    if (userId == null) {
      return false;
    }

    final Position posicion = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return _apiService.actualizarPerfilUsuario(
      token: token,
      userId: userId,
      datosActualizacion: {
        'latitud': posicion.latitude,
        'longitud': posicion.longitude,
      },
    );
  }
}