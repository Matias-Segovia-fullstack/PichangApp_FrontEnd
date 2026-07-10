import 'dart:math';

class Deportista {
  final int id;
  final String username;
  final String nombre;
  final String apellido;
  final String email;
  final String descripcion;
  final int edad;
  final String sexo;
  final String fotoUrl;
  final String deportePrincipal;
  final Map<String, dynamic> atributosDeportivos;
  final double? latitud;
  final double? longitud;
  final double? distanciaKm;

  Deportista({
    required this.id,
    required this.username,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.descripcion,
    required this.edad,
    required this.sexo,
    required this.fotoUrl,
    required this.deportePrincipal,
    required this.atributosDeportivos,
    required this.latitud,
    required this.longitud,
    required this.distanciaKm,
  });

  factory Deportista.fromJson(
    Map<String, dynamic> json, {
    double? miLatitud,
    double? miLongitud,
  }) {
    final profile = json['profile'];

    Map<String, dynamic> atributos = {};

    if (profile is Map<String, dynamic> && profile['atributosDeportivos'] is Map) {
      atributos = Map<String, dynamic>.from(profile['atributosDeportivos']);
    }

    final latitud = profile is Map<String, dynamic>
        ? double.tryParse(profile['latitud']?.toString() ?? '')
        : null;

    final longitud = profile is Map<String, dynamic>
        ? double.tryParse(profile['longitud']?.toString() ?? '')
        : null;

    final distanciaKm = _calcularDistanciaKm(
      miLatitud,
      miLongitud,
      latitud,
      longitud,
    );

    final descripcion = profile is Map<String, dynamic>
        ? profile['descripcion']?.toString().trim()
        : null;

    return Deportista(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      username: json['username']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? 'Usuario',
      apellido: json['apellido']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      descripcion: descripcion == null || descripcion.isEmpty
          ? 'Sin descripción deportiva'
          : descripcion,
      edad: profile is Map<String, dynamic>
          ? int.tryParse(profile['edad']?.toString() ?? '') ?? 0
          : 0,
      sexo: profile is Map<String, dynamic>
          ? profile['sexo']?.toString() ?? 'Sin sexo'
          : 'Sin sexo',
      fotoUrl: profile is Map<String, dynamic>
          ? profile['fotoUrl']?.toString() ?? 'https://via.placeholder.com/400x500.png?text=PichangApp'
          : 'https://via.placeholder.com/400x500.png?text=PichangApp',
      deportePrincipal: profile is Map<String, dynamic>
          ? profile['deportePrincipal']?.toString() ?? 'DEPORTE'
          : 'DEPORTE',
      atributosDeportivos: atributos,
      latitud: latitud,
      longitud: longitud,
      distanciaKm: distanciaKm,
    );
  }

  static double? _calcularDistanciaKm(
    double? lat1,
    double? lon1,
    double? lat2,
    double? lon2,
  ) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
      return null;
    }

    const radioTierraKm = 6371.0;

    final dLat = _gradosARadianes(lat2 - lat1);
    final dLon = _gradosARadianes(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_gradosARadianes(lat1)) *
            cos(_gradosARadianes(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radioTierraKm * c;
  }

  static double _gradosARadianes(double grados) {
    return grados * pi / 180.0;
  }

  String get nombreCompleto {
    return '$nombre $apellido'.trim();
  }

  String get posicion {
    final value = atributosDeportivos['posicion'] ?? atributosDeportivos['guardia'];
    if (value == null) return 'Sin posición';
    return value.toString();
  }

  String get altura {
    final altura = atributosDeportivos['altura'];
    final peso = atributosDeportivos['peso'];

    if (altura != null) {
      return '$altura cm';
    }

    if (peso != null) {
      return '$peso kg';
    }

    return 'Sin dato físico';
  }

  String get distanciaTexto {
    if (distanciaKm == null) {
      return 'Distancia no disponible';
    }

    if (distanciaKm! < 1) {
      return '${(distanciaKm! * 1000).round()} m de distancia';
    }

    if (distanciaKm! < 10) {
      return '${distanciaKm!.toStringAsFixed(1)} km de distancia';
    }

    return '${distanciaKm!.round()} km de distancia';
  }
}