class SalaChat {
  final int id;
  final int matchSocialId;
  final int usuarioAId;
  final int usuarioBId;
  final String estado;
  final String fechaCreacion;

  SalaChat({
    required this.id,
    required this.matchSocialId,
    required this.usuarioAId,
    required this.usuarioBId,
    required this.estado,
    required this.fechaCreacion,
  });

  factory SalaChat.fromJson(Map<String, dynamic> json) {
    return SalaChat(
      id: json['id'] ?? 0,
      matchSocialId: json['matchSocialId'] ?? 0,
      usuarioAId: json['usuarioAId'] ?? 0,
      usuarioBId: json['usuarioBId'] ?? 0,
      estado: json['estado']?.toString() ?? 'ACTIVA',
      fechaCreacion: json['fechaCreacion']?.toString() ?? '',
    );
  }

  int obtenerOtroUsuarioId(int miUsuarioId) {
    if (usuarioAId == miUsuarioId) {
      return usuarioBId;
    }

    if (usuarioBId == miUsuarioId) {
      return usuarioAId;
    }

    return 0;
  }
}