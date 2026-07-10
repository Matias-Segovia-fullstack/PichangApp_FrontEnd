import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';

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

  String? _sexoSeleccionado;
  String? _deporteSeleccionado;
  String? _posicionSeleccionada;

  bool _isLoading = false;

  final List<String> _deportes = ['BASKET', 'BOXEO'];

  final List<String> _sexos = [
    'MASCULINO',
    'FEMENINO',
    'OTRO',
    'PREFIERO_NO_DECIR',
  ];

  final Map<String, List<String>> _posicionesPorDeporte = {
    'BASKET': ['Base', 'Escolta', 'Alero', 'Ala Pívot', 'Pívot'],
    'BOXEO': ['Ortodoxa', 'Zurda'],
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

    _descripcionController = TextEditingController(
      text: profile is Map<String, dynamic> ? (profile['descripcion']?.toString() ?? '') : '',
    );

    _sexoSeleccionado = profile is Map<String, dynamic>
        ? profile['sexo']?.toString()
        : null;

    if (!_sexos.contains(_sexoSeleccionado)) {
      _sexoSeleccionado = 'MASCULINO';
    }

    _deporteSeleccionado = profile is Map<String, dynamic>
        ? profile['deportePrincipal']?.toString()
        : null;

    if (!_deportes.contains(_deporteSeleccionado)) {
      _deporteSeleccionado = 'BASKET';
    }

    if (_deporteSeleccionado == 'BOXEO') {
      _alturaController = TextEditingController(
        text: atributos is Map<String, dynamic> ? (atributos['peso']?.toString() ?? '') : '',
      );

      _posicionSeleccionada = atributos is Map<String, dynamic>
          ? atributos['guardia']?.toString()
          : null;
    } else {
      _alturaController = TextEditingController(
        text: atributos is Map<String, dynamic> ? (atributos['altura']?.toString() ?? '') : '',
      );

      _posicionSeleccionada = atributos is Map<String, dynamic>
          ? atributos['posicion']?.toString()
          : null;
    }

    final posiciones = _posicionesPorDeporte[_deporteSeleccionado] ?? [];

    if (!posiciones.contains(_posicionSeleccionada)) {
      _posicionSeleccionada = posiciones.isNotEmpty ? posiciones.first : null;
    }
  }

  @override
  void dispose() {
    _edadController.dispose();
    _alturaController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<Position?> _obtenerUbicacion() async {
    final bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();

    if (!servicioHabilitado) {
      return null;
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _guardarCambios() async {
    final edad = int.tryParse(_edadController.text.trim());
    final numeroDeportivo = int.tryParse(_alturaController.text.trim());

    if (edad == null || edad <= 0) {
      _mostrarError('Por favor ingresa una edad válida');
      return;
    }

    if (_sexoSeleccionado == null || !_sexos.contains(_sexoSeleccionado)) {
      _mostrarError('Por favor selecciona un sexo');
      return;
    }

    if (_deporteSeleccionado == null || !_deportes.contains(_deporteSeleccionado)) {
      _mostrarError('Por favor selecciona un deporte');
      return;
    }

    if (numeroDeportivo == null || numeroDeportivo <= 0) {
      _mostrarError(
        _deporteSeleccionado == 'BOXEO'
            ? 'Por favor ingresa un peso válido'
            : 'Por favor ingresa una altura válida',
      );
      return;
    }

    if (_posicionSeleccionada == null) {
      _mostrarError(
        _deporteSeleccionado == 'BOXEO'
            ? 'Por favor selecciona una guardia'
            : 'Por favor selecciona una posición',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final userId = widget.usuarioActual['id'];
      final Position? posicion = await _obtenerUbicacion();

      if (token == null || token.isEmpty) {
        throw Exception('No existe sesión activa.');
      }

      Map<String, dynamic> atributosDeportivos;

      if (_deporteSeleccionado == 'BOXEO') {
        atributosDeportivos = {
          'peso': numeroDeportivo,
          'guardia': _posicionSeleccionada,
        };
      } else {
        atributosDeportivos = {
          'altura': numeroDeportivo,
          'posicion': _posicionSeleccionada,
        };
      }

      final datosActualizacion = {
        'edad': edad,
        'sexo': _sexoSeleccionado,
        'deportePrincipal': _deporteSeleccionado,
        'descripcion': _descripcionController.text.trim(),
        'atributosDeportivos': atributosDeportivos,
        'latitud': posicion?.latitude,
        'longitud': posicion?.longitude,
      };

      final success = await _apiService.actualizarPerfilUsuario(
        token: token,
        userId: userId,
        datosActualizacion: datosActualizacion,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context, true);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? suffix,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.blue),
            suffixText: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    final String? safeValue = items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: safeValue,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          hint: const Text('Selecciona una opción'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool esBoxeo = _deporteSeleccionado == 'BOXEO';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _descripcionController,
                    label: 'Descripción Deportiva',
                    hint: 'Cuéntanos sobre ti y tu experiencia',
                    icon: Icons.description_outlined,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _edadController,
                    label: 'Edad',
                    hint: 'Ingresa tu edad',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                    suffix: 'años',
                  ),
                  const SizedBox(height: 24),
                  _buildDropdown(
                    label: 'Sexo',
                    value: _sexoSeleccionado,
                    items: _sexos,
                    onChanged: (valor) {
                      setState(() {
                        _sexoSeleccionado = valor;
                      });
                    },
                    icon: Icons.person_search,
                  ),
                  const SizedBox(height: 24),
                  _buildDropdown(
                    label: 'Deporte Principal',
                    value: _deporteSeleccionado,
                    items: _deportes,
                    onChanged: (valor) {
                      if (valor == null) return;

                      setState(() {
                        _deporteSeleccionado = valor;
                        _posicionSeleccionada = _posicionesPorDeporte[valor]?.first;
                        _alturaController.text = valor == 'BOXEO' ? '75' : '180';
                      });
                    },
                    icon: Icons.sports_basketball_outlined,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _alturaController,
                    label: esBoxeo ? 'Peso' : 'Altura',
                    hint: esBoxeo ? 'Ingresa tu peso' : 'Ingresa tu altura',
                    icon: esBoxeo ? Icons.monitor_weight : Icons.height,
                    keyboardType: TextInputType.number,
                    suffix: esBoxeo ? 'kg' : 'cm',
                  ),
                  const SizedBox(height: 24),
                  if (_deporteSeleccionado != null)
                    _buildDropdown(
                      label: esBoxeo ? 'Guardia' : 'Posición',
                      value: _posicionSeleccionada,
                      items: _posicionesPorDeporte[_deporteSeleccionado] ?? [],
                      onChanged: (valor) {
                        setState(() {
                          _posicionSeleccionada = valor;
                        });
                      },
                      icon: esBoxeo
                          ? Icons.sports_martial_arts_outlined
                          : Icons.sports_soccer_outlined,
                    ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _guardarCambios,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text('Guardar Cambios'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}