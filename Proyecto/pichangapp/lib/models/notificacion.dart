class Notificacion {
  final int id;
  final int usuarioId;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool leida;
  final String fechaCreacion;

  Notificacion({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.fechaCreacion,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      usuarioId: int.tryParse(json['usuarioId']?.toString() ?? '') ?? 0,
      titulo: json['titulo']?.toString() ?? 'Notificación',
      mensaje: json['mensaje']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? 'SISTEMA',
      leida: json['leida'] == true,
      fechaCreacion: json['fechaCreacion']?.toString() ?? '',
    );
  }

  bool get esMatch => tipo.toUpperCase() == 'MATCH';
  bool get esMensaje => tipo.toUpperCase() == 'MENSAJE';
  bool get esSistema => tipo.toUpperCase() == 'SISTEMA';
}