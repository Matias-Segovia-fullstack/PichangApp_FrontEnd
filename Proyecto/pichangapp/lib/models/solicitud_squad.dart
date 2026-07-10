class SolicitudSquad {
  final int id;
  final int squadId;
  final int usuarioId;
  final String estado;
  final String? fechaSolicitud;
  final String? fechaRespuesta;

  SolicitudSquad({
    required this.id,
    required this.squadId,
    required this.usuarioId,
    required this.estado,
    this.fechaSolicitud,
    this.fechaRespuesta,
  });

  factory SolicitudSquad.fromJson(Map<String, dynamic> json) {
    return SolicitudSquad(
      id: _toInt(json['id']),
      squadId: _toInt(json['squadId']),
      usuarioId: _toInt(json['usuarioId']),
      estado: json['estado']?.toString() ?? 'PENDIENTE',
      fechaSolicitud: json['fechaSolicitud']?.toString(),
      fechaRespuesta: json['fechaRespuesta']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}