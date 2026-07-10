class Squad {
  final int id;
  final int creadorId;
  final String nombre;
  final String deporte;
  final String descripcion;
  final int maxIntegrantes;
  final int integrantesActuales;
  final double? latitud;
  final double? longitud;
  final double? distanciaKm;
  final String estado;
  final String? fechaCreacion;
  final bool esMiembro;
  final bool solicitudPendiente;

  Squad({
    required this.id,
    required this.creadorId,
    required this.nombre,
    required this.deporte,
    required this.descripcion,
    required this.maxIntegrantes,
    required this.integrantesActuales,
    this.latitud,
    this.longitud,
    this.distanciaKm,
    required this.estado,
    this.fechaCreacion,
    required this.esMiembro,
    required this.solicitudPendiente,
  });

  factory Squad.fromJson(Map<String, dynamic> json) {
    return Squad(
      id: _toInt(json['id']),
      creadorId: _toInt(json['creadorId']),
      nombre: json['nombre']?.toString() ?? 'Squad sin nombre',
      deporte: json['deporte']?.toString() ?? 'BASKET',
      descripcion: json['descripcion']?.toString() ?? '',
      maxIntegrantes: _toInt(json['maxIntegrantes']),
      integrantesActuales: _toInt(json['integrantesActuales']),
      latitud: _toDouble(json['latitud']),
      longitud: _toDouble(json['longitud']),
      distanciaKm: _toDouble(json['distanciaKm']),
      estado: json['estado']?.toString() ?? 'ACTIVO',
      fechaCreacion: json['fechaCreacion']?.toString(),
      esMiembro: _toBool(json['esMiembro']),
      solicitudPendiente: _toBool(json['solicitudPendiente']),
    );
  }

  String get distanciaTexto {
    if (distanciaKm == null) {
      return 'Distancia no disponible';
    }

    if (distanciaKm! < 1) {
      return 'A menos de 1 km';
    }

    return '${distanciaKm!.round()} km de distancia';
  }

  String get integrantesTexto {
    return '$integrantesActuales/$maxIntegrantes integrantes';
  }

  bool get estaCompleto {
    return integrantesActuales >= maxIntegrantes;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value == 1;
    return false;
  }
}