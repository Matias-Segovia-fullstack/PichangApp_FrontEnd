import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/deportes.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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
  bool _isChangingPassword = false;

  final List<String> _sexos = [
    'Masculino',
    'Femenino',
  ];

  @override
  void initState() {
    super.initState();
    _inicializarFormulario();
  }

  String? _normalizarSexoVista(dynamic sexo) {
    final texto = sexo?.toString().trim().toUpperCase();

    if (texto == 'MASCULINO' || texto == 'MASCULINO'.toLowerCase().toUpperCase()) {
      return 'Masculino';
    }

    if (texto == 'FEMENINO' || texto == 'FEMENINO'.toLowerCase().toUpperCase()) {
      return 'Femenino';
    }

    if (sexo?.toString() == 'Masculino') {
      return 'Masculino';
    }

    if (sexo?.toString() == 'Femenino') {
      return 'Femenino';
    }

    return null;
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
        ? _normalizarSexoVista(profile['sexo'])
        : null;

    _deporteSeleccionado = profile is Map<String, dynamic>
        ? profile['deportePrincipal']?.toString().toUpperCase()
        : null;

    if (!AppDeportes.existe(_deporteSeleccionado)) {
      _deporteSeleccionado = AppDeportes.deportePredeterminado;
    } else {
      _deporteSeleccionado = AppDeportes.normalizarCodigo(_deporteSeleccionado);
    }

    if (AppDeportes.usaPeso(_deporteSeleccionado)) {
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

    final posiciones = AppDeportes.posiciones(_deporteSeleccionado);

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

  Future<void> _guardarCambios() async {
    final edad = int.tryParse(_edadController.text.trim());
    final numeroDeportivo = int.tryParse(_alturaController.text.trim());

    if (edad == null || edad < 18) {
      _mostrarError('Debes ser mayor de edad para usar PichangApp');
      return;
    }

    if (_sexoSeleccionado == null || !_sexos.contains(_sexoSeleccionado)) {
      _mostrarError('Por favor selecciona tu sexo');
      return;
    }

    if (_deporteSeleccionado == null || !AppDeportes.existe(_deporteSeleccionado)) {
      _mostrarError('Por favor selecciona un deporte');
      return;
    }

    if (numeroDeportivo == null || numeroDeportivo <= 0) {
      _mostrarError(
        AppDeportes.usaPeso(_deporteSeleccionado)
            ? 'Por favor ingresa un peso válido'
            : 'Por favor ingresa una altura válida',
      );
      return;
    }

    if (_posicionSeleccionada == null) {
      _mostrarError(
        AppDeportes.mensajePosicionInvalida(_deporteSeleccionado),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final userId = widget.usuarioActual['id'];

      if (token == null || token.isEmpty) {
        throw Exception('No existe sesión activa.');
      }

      Map<String, dynamic> atributosDeportivos;

      if (AppDeportes.usaPeso(_deporteSeleccionado)) {
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
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: AppTheme.success,
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
        backgroundColor: AppTheme.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }


  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _mostrarCambiarPasswordDialog() async {
    if (_isLoading || _isChangingPassword) return;

    final passwordActualController = TextEditingController();
    final nuevaPasswordController = TextEditingController();
    final confirmarNuevaPasswordController = TextEditingController();

    bool mostrarActual = false;
    bool mostrarNueva = false;
    bool mostrarConfirmacion = false;
    bool guardando = false;
    bool dialogCerrado = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !guardando,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> guardarPassword() async {
              final passwordActual = passwordActualController.text.trim();
              final nuevaPassword = nuevaPasswordController.text.trim();
              final confirmarNuevaPassword =
                  confirmarNuevaPasswordController.text.trim();

              if (passwordActual.isEmpty ||
                  nuevaPassword.isEmpty ||
                  confirmarNuevaPassword.isEmpty) {
                _mostrarError('Completa todos los campos de contraseña.');
                return;
              }

              if (nuevaPassword.length < 6) {
                _mostrarError('La nueva contraseña debe tener al menos 6 caracteres.');
                return;
              }

              if (nuevaPassword != confirmarNuevaPassword) {
                _mostrarError('La nueva contraseña y su confirmación no coinciden.');
                return;
              }

              setDialogState(() {
                guardando = true;
              });

              if (mounted) {
                setState(() {
                  _isChangingPassword = true;
                });
              }

              try {
                final token = await _storage.read(key: 'jwt_token');
                final userId = widget.usuarioActual['id'];

                if (token == null || token.isEmpty) {
                  throw Exception('No existe sesión activa.');
                }

                final resultado = await _apiService.cambiarPasswordUsuario(
                  token: token,
                  userId: userId,
                  passwordActual: passwordActual,
                  nuevaPassword: nuevaPassword,
                  confirmarNuevaPassword: confirmarNuevaPassword,
                );

                if (!mounted) return;

                if (resultado['ok'] == true) {
                  dialogCerrado = true;
                  Navigator.pop(dialogContext);
                  _mostrarMensaje(
                    resultado['mensaje']?.toString() ??
                        'Contraseña actualizada correctamente.',
                  );
                } else {
                  _mostrarError(
                    resultado['mensaje']?.toString() ??
                        'No se pudo cambiar la contraseña.',
                  );
                }
              } catch (e) {
                if (!mounted) return;
                _mostrarError('Error: ${e.toString()}');
              } finally {
                if (mounted) {
                  setState(() {
                    _isChangingPassword = false;
                  });
                }

                if (!dialogCerrado) {
                  setDialogState(() {
                    guardando = false;
                  });
                }
              }
            }

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: const Text(
                'Cambiar contraseña',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: passwordActualController,
                      obscureText: !mostrarActual,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Contraseña actual',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: guardando
                              ? null
                              : () {
                                  setDialogState(() {
                                    mostrarActual = !mostrarActual;
                                  });
                                },
                          icon: Icon(
                            mostrarActual
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nuevaPasswordController,
                      obscureText: !mostrarNueva,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        helperText: 'Mínimo 6 caracteres',
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          onPressed: guardando
                              ? null
                              : () {
                                  setDialogState(() {
                                    mostrarNueva = !mostrarNueva;
                                  });
                                },
                          icon: Icon(
                            mostrarNueva
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: confirmarNuevaPasswordController,
                      obscureText: !mostrarConfirmacion,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Confirmar nueva contraseña',
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                        suffixIcon: IconButton(
                          onPressed: guardando
                              ? null
                              : () {
                                  setDialogState(() {
                                    mostrarConfirmacion = !mostrarConfirmacion;
                                  });
                                },
                          icon: Icon(
                            mostrarConfirmacion
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: guardando ? null : guardarPassword,
                  child: guardando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordActualController.dispose();
    nuevaPasswordController.dispose();
    confirmarNuevaPasswordController.dispose();
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seguridad de la cuenta',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Puedes cambiar tu contraseña validando primero la contraseña actual.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_isLoading || _isChangingPassword)
                  ? null
                  : _mostrarCambiarPasswordDialog,
              icon: _isChangingPassword
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.password),
              label: const Text('Cambiar contraseña'),
            ),
          ),
        ],
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
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixText: suffix,
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
    bool itemsSonDeportes = false,
  }) {
    final String? safeValue = items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: safeValue,
          dropdownColor: AppTheme.surfaceAlt,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(itemsSonDeportes ? AppDeportes.nombre(item) : item),
            );
          }).toList(),
          onChanged: onChanged,
          hint: const Text('Selecciona una opción'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool esBoxeo = AppDeportes.usaPeso(_deporteSeleccionado);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _descripcionController,
                    label: 'Descripción Deportiva',
                    hint: 'Cuéntanos sobre ti y tu experiencia',
                    icon: Icons.description_outlined,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 22),
                  _buildTextField(
                    controller: _edadController,
                    label: 'Edad',
                    hint: 'Ingresa tu edad',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                    suffix: 'años',
                  ),
                  const SizedBox(height: 22),
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
                  const SizedBox(height: 22),
                  _buildDropdown(
                    label: 'Deporte Principal',
                    value: _deporteSeleccionado,
                    items: AppDeportes.codigos,
                    onChanged: (valor) {
                      if (valor == null) return;

                      setState(() {
                        _deporteSeleccionado = AppDeportes.normalizarCodigo(valor);
                        _posicionSeleccionada = AppDeportes.primeraPosicion(valor);
                        _alturaController.text = AppDeportes
                            .valorDefectoNumero(valor)
                            .toString();
                      });
                    },
                    icon: Icons.sports_basketball_outlined,
                    itemsSonDeportes: true,
                  ),
                  const SizedBox(height: 22),
                  _buildTextField(
                    controller: _alturaController,
                    label: esBoxeo ? 'Peso' : 'Altura',
                    hint: esBoxeo ? 'Ingresa tu peso' : 'Ingresa tu altura',
                    icon: esBoxeo ? Icons.monitor_weight : Icons.height,
                    keyboardType: TextInputType.number,
                    suffix: esBoxeo ? 'kg' : 'cm',
                  ),
                  const SizedBox(height: 22),
                  if (_deporteSeleccionado != null)
                    _buildDropdown(
                      label: AppDeportes.etiquetaPosicion(_deporteSeleccionado),
                      value: _posicionSeleccionada,
                      items: AppDeportes.posiciones(_deporteSeleccionado),
                      onChanged: (valor) {
                        setState(() {
                          _posicionSeleccionada = valor;
                        });
                      },
                      icon: esBoxeo
                          ? Icons.sports_martial_arts_outlined
                          : Icons.sports_soccer_outlined,
                    ),
                  const SizedBox(height: 24),
                  _buildSecuritySection(),
                  const SizedBox(height: 36),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _guardarCambios,
                          child: const Text('Guardar Cambios'),
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