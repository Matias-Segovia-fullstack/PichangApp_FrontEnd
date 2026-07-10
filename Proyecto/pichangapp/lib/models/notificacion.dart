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

  String get tipoNormalizado => tipo.toUpperCase().trim();

  bool get esMatch => tipoNormalizado == 'MATCH';
  bool get esMensaje => tipoNormalizado == 'MENSAJE';
  bool get esSquadSolicitud => tipoNormalizado == 'SQUAD_SOLICITUD';
  bool get esSquadAceptada => tipoNormalizado == 'SQUAD_ACEPTADA';
  bool get esSquad => esSquadSolicitud || esSquadAceptada;
}
