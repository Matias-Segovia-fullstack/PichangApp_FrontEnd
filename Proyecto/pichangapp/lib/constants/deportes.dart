class AppDeporte {
  final String codigo;
  final String nombre;
  final bool usaPeso;
  final int valorDefectoNumero;
  final List<String> posiciones;

  const AppDeporte({
    required this.codigo,
    required this.nombre,
    required this.usaPeso,
    required this.valorDefectoNumero,
    required this.posiciones,
  });
}

class AppDeportes {
  static const String todos = 'Todos';
  static const String deportePredeterminado = 'BASKET';

  static const List<AppDeporte> deportes = [
    AppDeporte(
      codigo: 'BASKET',
      nombre: 'Basket',
      usaPeso: false,
      valorDefectoNumero: 180,
      posiciones: ['Base', 'Escolta', 'Alero', 'Ala Pívot', 'Pívot'],
    ),
    AppDeporte(
      codigo: 'BOXEO',
      nombre: 'Boxeo',
      usaPeso: true,
      valorDefectoNumero: 75,
      posiciones: ['Ortodoxa', 'Zurda'],
    ),
    AppDeporte(
      codigo: 'FUTBOL',
      nombre: 'Fútbol',
      usaPeso: false,
      valorDefectoNumero: 175,
      posiciones: ['Arquero', 'Defensa', 'Mediocampista', 'Delantero'],
    ),
    AppDeporte(
      codigo: 'FUTSAL',
      nombre: 'Futsal',
      usaPeso: false,
      valorDefectoNumero: 175,
      posiciones: ['Arquero', 'Cierre', 'Ala', 'Pívot'],
    ),
    AppDeporte(
      codigo: 'TENIS',
      nombre: 'Tenis',
      usaPeso: false,
      valorDefectoNumero: 175,
      posiciones: ['Singles', 'Dobles', 'Mixto', 'Recreativo'],
    ),
    AppDeporte(
      codigo: 'PADEL',
      nombre: 'Pádel',
      usaPeso: false,
      valorDefectoNumero: 175,
      posiciones: ['Drive', 'Revés', 'Ambos lados', 'Recreativo'],
    ),
    AppDeporte(
      codigo: 'VOLEIBOL',
      nombre: 'Voleibol',
      usaPeso: false,
      valorDefectoNumero: 175,
      posiciones: ['Armador', 'Punta', 'Central', 'Opuesto', 'Líbero'],
    ),
    AppDeporte(
      codigo: 'RUNNING',
      nombre: 'Running',
      usaPeso: false,
      valorDefectoNumero: 170,
      posiciones: ['5K', '10K', 'Media maratón', 'Maratón', 'Trail'],
    ),
    AppDeporte(
      codigo: 'CICLISMO',
      nombre: 'Ciclismo',
      usaPeso: false,
      valorDefectoNumero: 170,
      posiciones: ['Ruta', 'MTB', 'Urbano', 'Gravel', 'Recreativo'],
    ),
    AppDeporte(
      codigo: 'CALISTENIA',
      nombre: 'Calistenia',
      usaPeso: false,
      valorDefectoNumero: 170,
      posiciones: ['Principiante', 'Intermedio', 'Avanzado', 'Street workout'],
    ),
    AppDeporte(
      codigo: 'TREKKING',
      nombre: 'Trekking',
      usaPeso: false,
      valorDefectoNumero: 170,
      posiciones: ['Principiante', 'Intermedio', 'Avanzado', 'Alta montaña'],
    ),
    AppDeporte(
      codigo: 'NATACION',
      nombre: 'Natación',
      usaPeso: false,
      valorDefectoNumero: 170,
      posiciones: ['Libre', 'Espalda', 'Pecho', 'Mariposa', 'Recreativo'],
    ),
  ];

  static List<String> get codigos {
    return deportes.map((deporte) => deporte.codigo).toList();
  }

  static bool existe(String? codigo) {
    if (codigo == null) return false;
    final normalizado = codigo.trim().toUpperCase();
    return deportes.any((deporte) => deporte.codigo == normalizado);
  }

  static String normalizarCodigo(String? codigo) {
    if (codigo == null || codigo.trim().isEmpty) {
      return deportePredeterminado;
    }

    final normalizado = codigo.trim().toUpperCase();

    if (existe(normalizado)) {
      return normalizado;
    }

    return deportePredeterminado;
  }

  static AppDeporte config(String? codigo) {
    final normalizado = normalizarCodigo(codigo);

    return deportes.firstWhere(
      (deporte) => deporte.codigo == normalizado,
      orElse: () => deportes.first,
    );
  }

  static String nombre(String? codigo) {
    if (codigo == null || codigo.trim().isEmpty) {
      return 'No definido';
    }

    final normalizado = codigo.trim().toUpperCase();

    if (normalizado == todos.toUpperCase()) {
      return todos;
    }

    return config(normalizado).nombre;
  }

  static bool usaPeso(String? codigo) {
    return config(codigo).usaPeso;
  }

  static int valorDefectoNumero(String? codigo) {
    return config(codigo).valorDefectoNumero;
  }

  static List<String> posiciones(String? codigo) {
    return config(codigo).posiciones;
  }

  static String primeraPosicion(String? codigo) {
    final opciones = posiciones(codigo);
    return opciones.isEmpty ? '' : opciones.first;
  }

  static String etiquetaNumero(String? codigo) {
    return usaPeso(codigo) ? 'Peso' : 'Altura';
  }

  static String etiquetaNumeroRegistro(String? codigo) {
    return usaPeso(codigo) ? 'Peso en kg' : 'Altura en cm';
  }

  static String hintNumero(String? codigo) {
    return usaPeso(codigo) ? 'Ingresa tu peso' : 'Ingresa tu altura';
  }

  static String unidadNumero(String? codigo) {
    return usaPeso(codigo) ? 'kg' : 'cm';
  }

  static String etiquetaPosicion(String? codigo) {
    return usaPeso(codigo) ? 'Guardia' : 'Posición / especialidad';
  }

  static String mensajeNumeroInvalido(String? codigo) {
    return usaPeso(codigo)
        ? 'Ingresa un peso válido.'
        : 'Ingresa una altura válida.';
  }

  static String mensajePosicionInvalida(String? codigo) {
    return usaPeso(codigo)
        ? 'Por favor selecciona una guardia'
        : 'Por favor selecciona una posición o especialidad';
  }
}
