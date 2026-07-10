import 'package:flutter/material.dart';
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

  String? _sexoSeleccionado;
  String _deporteSeleccionado = 'BASKET';
  String _posicionSeleccionada = 'Base';

  final List<String> _sexos = [
    'Masculino',
    'Femenino',
  ];

  final Map<String, List<String>> _posicionesPorDeporte = {
    'BASKET': ['Base', 'Escolta', 'Alero', 'Ala Pívot', 'Pívot'],
    'BOXEO': ['Ortodoxa', 'Zurda'],
  };

  @override
  void dispose() {
    _authController.dispose();
    _edadController.dispose();
    _numeroDeportivoController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final int? edad = int.tryParse(_edadController.text.trim());
    final int? numeroDeportivo = int.tryParse(_numeroDeportivoController.text.trim());

    if (edad == null || edad < 18) {
      _mostrarMensaje('Debes ser mayor de edad para usar PichangApp.', Colors.red);
      return;
    }

    if (_sexoSeleccionado == null || _sexoSeleccionado!.trim().isEmpty) {
      _mostrarMensaje('Debes seleccionar tu sexo.', Colors.red);
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
      final bool success = await _authController.registrar(
        edad: edad,
        sexo: _sexoSeleccionado!,
        deportePrincipal: _deporteSeleccionado,
        numeroDeportivo: numeroDeportivo,
        posicionOGuardia: _posicionSeleccionada,
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
    required String? value,
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
                  label: 'Descripción deportiva',
                  icon: Icons.description_outlined,
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registrar,
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