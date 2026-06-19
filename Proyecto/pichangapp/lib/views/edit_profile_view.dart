import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class EditProfileView extends StatefulWidget {
  final Map<String, dynamic> usuarioActual;

  const EditProfileView({
    super.key,
    required this.usuarioActual,
  });

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late TextEditingController _edadController;
  late TextEditingController _alturaController;
  late TextEditingController _descripcionController;

  String? _deporteSeleccionado;
  String? _posicionSeleccionada;
  bool _isLoading = false;
  String? _error;

  // Opciones de deportes
  final List<String> _deportes = ['BASKET', 'BOXEO'];

  // Posiciones por deporte
  final Map<String, List<String>> _posicionesPorDeporte = {
    'BASKET': ['Base', 'Escolta', 'Alero', 'Ala-Pívot', 'Pívot'],
    'BOXEO': ['Peso Ligero', 'Peso Medio', 'Peso Pesado'],
  };

  @override
  void initState() {
    super.initState();
    _inicializarFormulario();
  }

  void _inicializarFormulario() {
    final profile = widget.usuarioActual['profile'];
    final atributos = profile is Map<String, dynamic>
        ? profile['atributosDeportivos']
        : null;

    _edadController = TextEditingController(
      text: profile is Map<String, dynamic> ? (profile['edad']?.toString() ?? '') : '',
    );

    _alturaController = TextEditingController(
      text: atributos is Map<String, dynamic> ? (atributos['altura']?.toString() ?? '') : '',
    );

    _descripcionController = TextEditingController(
      text: profile is Map<String, dynamic> ? (profile['descripcion'] ?? '') : '',
    );

    _deporteSeleccionado = profile is Map<String, dynamic> ? profile['deportePrincipal'] : null;
    _posicionSeleccionada = atributos is Map<String, dynamic> ? atributos['posicion'] : null;
  }

  @override
  void dispose() {
    _edadController.dispose();
    _alturaController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (_edadController.text.isEmpty) {
      _mostrarError('Por favor ingresa la edad');
      return;
    }

    if (_alturaController.text.isEmpty) {
      _mostrarError('Por favor ingresa la altura');
      return;
    }

    if (_deporteSeleccionado == null) {
      _mostrarError('Por favor selecciona un deporte');
      return;
    }

    if (_posicionSeleccionada == null) {
      _mostrarError('Por favor selecciona una posición');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final userId = widget.usuarioActual['id'];

      if (token == null || token.isEmpty) {
        throw Exception('No existe sesión activa.');
      }

      // Preparar datos según el deporte seleccionado
      Map<String, dynamic> atributosDeportivos = {};

      if (_deporteSeleccionado == 'BASKET') {
        atributosDeportivos = {
          'altura': int.parse(_alturaController.text),
          'posicion': _posicionSeleccionada,
        };
      } else if (_deporteSeleccionado == 'BOXEO') {
        atributosDeportivos = {
          'peso': int.parse(_alturaController.text), // En este caso puede ser peso
          'guardia': _posicionSeleccionada,
        };
      }

      final datosActualizacion = {
        'edad': int.parse(_edadController.text),
        'deportePrincipal': _deporteSeleccionado,
        'descripcion': _descripcionController.text,
        'atributosDeportivos': atributosDeportivos,
      };

      final success = await _apiService.actualizarPerfilUsuario(
        token: token,
        userId: userId,
        datosActualizacion: datosActualizacion,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
        Navigator.pop(context, true); // Retorna true para indicar que se guardaron cambios
      } else {
        _mostrarError('No se pudo actualizar el perfil');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    setState(() {
      _error = mensaje;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo Descripción
                  const Text(
                    'Descripción deportiva',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descripcionController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'Cuéntanos sobre ti',
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Campo Edad
                  const Text(
                    'Edad',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _edadController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'Ingresa tu edad',
                      prefixIcon: const Icon(Icons.cake),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Selector Deporte
                  const Text(
                    'Deporte principal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _deporteSeleccionado,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.sports),
                    ),
                    items: _deportes.map((deporte) {
                      return DropdownMenuItem(
                        value: deporte,
                        child: Text(deporte),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      setState(() {
                        _deporteSeleccionado = valor;
                        _posicionSeleccionada = null; // Resetear posición
                      });
                    },
                    hint: const Text('Selecciona un deporte'),
                  ),
                  const SizedBox(height: 24),

                  // Campo Altura/Peso (dinámico según deporte)
                  Text(
                    _deporteSeleccionado == 'BOXEO' ? 'Peso (kg)' : 'Altura (cm)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _alturaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: _deporteSeleccionado == 'BOXEO' ? 'Ingresa tu peso' : 'Ingresa tu altura',
                      prefixIcon: Icon(
                        _deporteSeleccionado == 'BOXEO' ? Icons.monitor_weight : Icons.height,
                      ),
                      suffixText: _deporteSeleccionado == 'BOXEO' ? 'kg' : 'cm',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Selector Posición (condicional al deporte)
                  if (_deporteSeleccionado != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _deporteSeleccionado == 'BOXEO' ? 'Guardia' : 'Posición',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _posicionSeleccionada,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.sports_soccer),
                          ),
                          items: (_posicionesPorDeporte[_deporteSeleccionado] ?? [])
                              .map((posicion) {
                            return DropdownMenuItem(
                              value: posicion,
                              child: Text(posicion),
                            );
                          }).toList(),
                          onChanged: (valor) {
                            setState(() {
                              _posicionSeleccionada = valor;
                            });
                          },
                          hint: const Text('Selecciona una posición'),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _guardarCambios,
                          child: const Text('Guardar cambios'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}