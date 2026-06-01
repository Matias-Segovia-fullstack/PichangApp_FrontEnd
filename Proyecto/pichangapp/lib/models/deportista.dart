class Deportista {
  final int id;
  final String nombre;
  final int edad;
  final String deporte;
  final double altura; // en metros, ej: 1.75
  final String nivel;
  final String fotoUrl;

  Deportista({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.deporte,
    required this.altura,
    required this.nivel,
    required this.fotoUrl,
  });
}