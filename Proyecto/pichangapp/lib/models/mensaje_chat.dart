class MensajeChat {
  final int id;
  final int salaChatId;
  final int remitenteId;
  final String contenido;
  final String fechaEnvio;

  MensajeChat({
    required this.id,
    required this.salaChatId,
    required this.remitenteId,
    required this.contenido,
    required this.fechaEnvio,
  });

  factory MensajeChat.fromJson(Map<String, dynamic> json) {
    return MensajeChat(
      id: json['id'] ?? 0,
      salaChatId: json['salaChatId'] ?? 0,
      remitenteId: json['remitenteId'] ?? 0,
      contenido: json['contenido']?.toString() ?? '',
      fechaEnvio: json['fechaEnvio']?.toString() ?? '',
    );
  }
}