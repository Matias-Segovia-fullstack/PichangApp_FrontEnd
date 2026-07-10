class MensajeSquad {
  final int id;
  final int squadId;
  final int remitenteId;
  final String contenido;
  final String fechaEnvio;

  MensajeSquad({
    required this.id,
    required this.squadId,
    required this.remitenteId,
    required this.contenido,
    required this.fechaEnvio,
  });

  factory MensajeSquad.fromJson(Map<String, dynamic> json) {
    return MensajeSquad(
      id: _toInt(json['id']),
      squadId: _toInt(json['squadId']),
      remitenteId: _toInt(json['remitenteId']),
      contenido: json['contenido']?.toString() ?? '',
      fechaEnvio: json['fechaEnvio']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}