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
  });

  factory Deportista.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];

    Map<String, dynamic> atributos = {};

    if (profile is Map<String, dynamic> && profile['atributosDeportivos'] is Map) {
      atributos = Map<String, dynamic>.from(profile['atributosDeportivos']);
    }

    return Deportista(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      nombre: json['nombre'] ?? 'Usuario',
      apellido: json['apellido'] ?? '',
      email: json['email'] ?? '',
      descripcion: profile is Map<String, dynamic>
          ? profile['descripcion'] ?? 'Sin descripción deportiva'
          : 'Sin descripción deportiva',
      edad: profile is Map<String, dynamic>
          ? int.tryParse((profile['edad'] ?? '0').toString()) ?? 0
          : 0,
      sexo: profile is Map<String, dynamic>
          ? profile['sexo']?.toString() ?? 'Sin sexo'
          : 'Sin sexo',
      fotoUrl: profile is Map<String, dynamic>
          ? profile['fotoUrl'] ?? 'https://via.placeholder.com/400x500.png?text=PichangApp'
          : 'https://via.placeholder.com/400x500.png?text=PichangApp',
      deportePrincipal: profile is Map<String, dynamic>
          ? profile['deportePrincipal'] ?? 'DEPORTE'
          : 'DEPORTE',
      atributosDeportivos: atributos,
    );
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
}