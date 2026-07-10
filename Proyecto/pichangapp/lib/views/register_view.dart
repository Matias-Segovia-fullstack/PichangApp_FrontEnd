import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final AuthController _authController = AuthController();

  final TextEditingController _edadController = TextEditingController(text: '25');
  final TextEditingController _numeroDeportivoController = TextEditingController(text: '180');

  bool _isLoading = false;
  bool _isLocationLoading = false;

  Position? _ubicacion;
  String _ubicacionMensaje = 'Debes permitir ubicación para crear tu cuenta deportiva.';

  String _sexoSeleccionado = 'MASCULINO';
  String _deporteSeleccionado = 'BASKET';
  String _posicionSeleccionada = 'Base';

  final Map<String, List<String>> _posicionesPorDeporte = {
    'BASKET': ['Base', 'Escolta', 'Alero', 'Ala Pívot', 'Pívot'],
    'BOXEO': ['Ortodoxa', 'Zurda'],
  };

  final List<String> _sexos = [
    'MASCULINO',
    'FEMENINO',
    'OTRO',
    'PREFIERO_NO_DECIR',
  ];

  @override
  void dispose() {
    _authController.dispose();
    _edadController.dispose();
    _numeroDeportivoController.dispose();
    super.dispose();
  }

  Future<Position?> _obtenerUbicacion() async {
    if (!mounted) return null;

    setState(() {
      _isLocationLoading = true;
      _ubicacionMensaje = 'Solicitando ubicación...';
    });

    try {
      final bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();

      if (!servicioHabilitado) {
        if (mounted) {
          setState(() {
            _ubicacionMensaje = 'Activa la ubicación del dispositivo o navegador.';
          });
        }
        return null;
      }

      LocationPermission permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _ubicacionMensaje = 'Permiso de ubicación rechazado.';
          });
        }
        return null;
      }

      if (permiso == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _ubicacionMensaje = 'Permiso de ubicación bloqueado. Habilítalo desde el navegador o sistema.';
          });
        }
        return null;
      }

      final Position posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _ubicacion = posicion;
          _ubicacionMensaje =
              'Ubicación lista: ${posicion.latitude.toStringAsFixed(5)}, ${posicion.longitude.toStringAsFixed(5)}';
        });
      }

      return posicion;
    } catch (e) {
      if (mounted) {
        setState(() {
          _ubicacionMensaje = 'No se pudo obtener la ubicación.';
        });
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  Future<void> _registrar() async {
    final int? edad = int.tryParse(_edadController.text.trim());
    final int? numeroDeportivo = int.tryParse(_numeroDeportivoController.text.trim());

    if (edad == null || edad <= 0) {
      _mostrarMensaje('Ingresa una edad válida.', Colors.red);
      return;
    }

    if (numeroDeportivo == null || numeroDeportivo <= 0) {
      _mostrarMensaje(
        _deporteSeleccionado == 'BOXEO'
            ? 'Ingresa un peso válido.'
            : 'Ingresa una altura válida.',
        Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Position? posicion = _ubicacion ?? await _obtenerUbicacion();

      if (posicion == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        _mostrarMensaje(
          'Para usar Discover debes permitir ubicación.',
          Colors.red,
        );
        return;
      }

      final bool success = await _authController.registrar(
        edad: edad,
        sexo: _sexoSeleccionado,
        deportePrincipal: _deporteSeleccionado,
        numeroDeportivo: numeroDeportivo,
        posicionOGuardia: _posicionSeleccionada,
        latitud: posicion.latitude,
        longitud: posicion.longitude,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _mostrarMensaje(
          'Cuenta creada con éxito. Ya puedes iniciar sesión.',
          Colors.green,
        );

        Navigator.pop(context);
      } else {
        _mostrarMensaje(
          'Error al crear la cuenta. Revisa los datos o usa otro username/email.',
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _mostrarMensaje('Error al crear cuenta: $e', Colors.red);
    }
  }

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _selector({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _tarjetaUbicacion() {
    final bool tieneUbicacion = _ubicacion != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              tieneUbicacion ? Icons.location_on : Icons.location_off_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_ubicacionMensaje),
            ),
            TextButton(
              onPressed: (_isLoading || _isLocationLoading) ? null : _obtenerUbicacion,
              child: _isLocationLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tomar ubicación'),
            ),
          ],
        ),
      ),
    );
  }

  void _cambiarDeporte(String? valor) {
    if (valor == null) return;

    setState(() {
      _deporteSeleccionado = valor;
      _posicionSeleccionada = _posicionesPorDeporte[valor]!.first;
      _numeroDeportivoController.text = valor == 'BOXEO' ? '75' : '180';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool esBoxeo = _deporteSeleccionado == 'BOXEO';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta deportiva'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _campo(
                  controller: _authController.nameController,
                  label: 'Nombre',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _authController.apellidoController,
                  label: 'Apellido',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _authController.usernameController,
                  label: 'Username',
                  icon: Icons.account_circle,
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _authController.emailController,
                  label: 'Correo electrónico',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _authController.passwordController,
                  label: 'Contraseña',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _authController.rutController,
                  label: 'RUT opcional',
                  icon: Icons.badge,
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _edadController,
                  label: 'Edad',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _selector(
                  label: 'Sexo',
                  value: _sexoSeleccionado,
                  items: _sexos,
                  onChanged: (valor) {
                    if (valor == null) return;

                    setState(() {
                      _sexoSeleccionado = valor;
                    });
                  },
                  icon: Icons.person_search,
                ),
                const SizedBox(height: 16),
                _selector(
                  label: 'Deporte principal',
                  value: _deporteSeleccionado,
                  items: const ['BASKET', 'BOXEO'],
                  onChanged: _cambiarDeporte,
                  icon: Icons.sports_basketball_outlined,
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _numeroDeportivoController,
                  label: esBoxeo ? 'Peso en kg' : 'Altura en cm',
                  icon: esBoxeo ? Icons.monitor_weight : Icons.height,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _selector(
                  label: esBoxeo ? 'Guardia' : 'Posición',
                  value: _posicionSeleccionada,
                  items: _posicionesPorDeporte[_deporteSeleccionado]!,
                  onChanged: (valor) {
                    if (valor == null) return;

                    setState(() {
                      _posicionSeleccionada = valor;
                    });
                  },
                  icon: esBoxeo
                      ? Icons.sports_martial_arts_outlined
                      : Icons.sports_soccer_outlined,
                ),
                const SizedBox(height: 16),
                _tarjetaUbicacion(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_isLoading || _isLocationLoading) ? null : _registrar,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Registrarme'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}