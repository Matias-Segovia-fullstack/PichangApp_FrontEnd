import 'package:flutter/material.dart';
import '../constants/deportes.dart';
import '../controllers/auth_controller.dart';
import '../services/media_service.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final AuthController _authController = AuthController();
  final MediaService _mediaService = MediaService();

  final TextEditingController _edadController = TextEditingController(text: '25');
  final TextEditingController _numeroDeportivoController = TextEditingController(
    text: AppDeportes.valorDefectoNumero(AppDeportes.deportePredeterminado).toString(),
  );

  bool _isLoading = false;
  bool _isUploadingPhoto = false;

  String? _fotoPerfilUrl;
  String? _sexoSeleccionado;
  String _deporteSeleccionado = AppDeportes.deportePredeterminado;
  String _posicionSeleccionada = AppDeportes.primeraPosicion(
    AppDeportes.deportePredeterminado,
  );

  final List<String> _sexos = [
    'Masculino',
    'Femenino',
  ];

  @override
  void dispose() {
    _authController.dispose();
    _edadController.dispose();
    _numeroDeportivoController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFotoPerfil() async {
    if (_isLoading || _isUploadingPhoto) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final url = await _mediaService.pickCompressAndUploadImage(
        bucket: 'user-media',
        folder: 'registro_perfiles',
      );

      if (!mounted) return;

      if (url == null || url.isEmpty) {
        setState(() {
          _isUploadingPhoto = false;
        });
        return;
      }

      setState(() {
        _fotoPerfilUrl = url;
        _isUploadingPhoto = false;
      });

      _mostrarMensaje('Foto de perfil agregada.', Colors.green);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });

      _mostrarMensaje('Error al subir foto: $e', Colors.red);
    }
  }

  Future<void> _registrar() async {
    if (_isUploadingPhoto) {
      _mostrarMensaje('Espera a que termine de subir la foto.', Colors.orange);
      return;
    }

    final int? edad = int.tryParse(_edadController.text.trim());
    final int? numeroDeportivo = int.tryParse(_numeroDeportivoController.text.trim());

    if (edad == null || edad < 18) {
      _mostrarMensaje('Debes ser mayor de edad para usar MatchFit.', Colors.red);
      return;
    }

    if (_sexoSeleccionado == null || _sexoSeleccionado!.trim().isEmpty) {
      _mostrarMensaje('Debes seleccionar tu sexo.', Colors.red);
      return;
    }

    if (!AppDeportes.existe(_deporteSeleccionado)) {
      _mostrarMensaje('Debes seleccionar un deporte.', Colors.red);
      return;
    }

    if (numeroDeportivo == null || numeroDeportivo <= 0) {
      _mostrarMensaje(
        AppDeportes.mensajeNumeroInvalido(_deporteSeleccionado),
        Colors.red,
      );
      return;
    }

    if (_posicionSeleccionada.trim().isEmpty) {
      _mostrarMensaje(
        AppDeportes.mensajePosicionInvalida(_deporteSeleccionado),
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
        fotoUrl: _fotoPerfilUrl,
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
    bool itemsSonDeportes = false,
  }) {
    final safeValue = items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(itemsSonDeportes ? AppDeportes.nombre(item) : item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _selectorFotoPerfil() {
    return Column(
      children: [
        CircleAvatar(
          radius: 54,
          backgroundColor: Colors.blue.withOpacity(0.14),
          backgroundImage: _fotoPerfilUrl != null
              ? NetworkImage(_fotoPerfilUrl!)
              : null,
          child: _fotoPerfilUrl == null
              ? const Icon(
                  Icons.person,
                  size: 54,
                  color: Colors.blue,
                )
              : null,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: (_isLoading || _isUploadingPhoto) ? null : _seleccionarFotoPerfil,
          icon: _isUploadingPhoto
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.camera_alt),
          label: Text(
            _isUploadingPhoto
                ? 'Subiendo foto...'
                : _fotoPerfilUrl == null
                    ? 'Agregar foto de perfil'
                    : 'Cambiar foto de perfil',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _fotoPerfilUrl == null
              ? 'Puedes crear tu cuenta sin foto y agregarla después.'
              : 'La foto quedará guardada al crear tu cuenta.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _cambiarDeporte(String? valor) {
    if (valor == null) return;

    final deporte = AppDeportes.normalizarCodigo(valor);

    setState(() {
      _deporteSeleccionado = deporte;
      _posicionSeleccionada = AppDeportes.primeraPosicion(deporte);
      _numeroDeportivoController.text = AppDeportes
          .valorDefectoNumero(deporte)
          .toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool usaPeso = AppDeportes.usaPeso(_deporteSeleccionado);

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
                _selectorFotoPerfil(),
                const SizedBox(height: 24),
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
                  items: AppDeportes.codigos,
                  onChanged: _cambiarDeporte,
                  icon: Icons.sports_basketball,
                  itemsSonDeportes: true,
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _numeroDeportivoController,
                  label: AppDeportes.etiquetaNumeroRegistro(_deporteSeleccionado),
                  icon: usaPeso ? Icons.monitor_weight : Icons.height,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _selector(
                  label: AppDeportes.etiquetaPosicion(_deporteSeleccionado),
                  value: _posicionSeleccionada,
                  items: AppDeportes.posiciones(_deporteSeleccionado),
                  onChanged: (valor) {
                    if (valor == null) return;

                    setState(() {
                      _posicionSeleccionada = valor;
                    });
                  },
                  icon: usaPeso
                      ? Icons.sports_martial_arts_outlined
                      : Icons.sports_soccer_outlined,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_isLoading || _isUploadingPhoto) ? null : _registrar,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}