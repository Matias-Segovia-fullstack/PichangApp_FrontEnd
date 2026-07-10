class SquadMiembro {
  final int id;
  final int squadId;
  final int usuarioId;
  final String rol;
  final String? fechaUnion;

  SquadMiembro({
    required this.id,
    required this.squadId,
    required this.usuarioId,
    required this.rol,
    this.fechaUnion,
  });

  factory SquadMiembro.fromJson(Map<String, dynamic> json) {
    return SquadMiembro(
      id: _toInt(json['id']),
      squadId: _toInt(json['squadId']),
      usuarioId: _toInt(json['usuarioId']),
      rol: json['rol']?.toString() ?? 'MIEMBRO',
      fechaUnion: json['fechaUnion']?.toString(),
    );
  }

  bool get esAdmin {
    return rol.toUpperCase().trim() == 'ADMIN';
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}