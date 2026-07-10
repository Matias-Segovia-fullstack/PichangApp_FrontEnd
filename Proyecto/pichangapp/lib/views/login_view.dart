import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/login_response.dart';
import '../theme/app_theme.dart';
import 'home_tabs.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController _authController = AuthController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final LoginResponse? response = await _authController.login();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeTabs(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario o contraseña incorrecta'),
        ),
      );
    }
  }

  Future<void> _mostrarRecuperarPassword() async {
    final controller = TextEditingController();
    String? errorTexto;

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: const Text(
                'Recuperar contraseña',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingresa tu correo o username. Por ahora el reseteo debe hacerlo el administrador del proyecto.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Correo o username',
                      prefixIcon: const Icon(Icons.account_circle_outlined),
                      errorText: errorTexto,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final valor = controller.text.trim();

                    if (valor.isEmpty) {
                      setDialogState(() {
                        errorTexto = 'Ingresa un correo o username';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, valor);
                  },
                  child: const Text('Solicitar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (!mounted || resultado == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Solicitud registrada para $resultado. Debe resetearse desde administración.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = 24.0;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF020617),
                Color(0xFF0F172A),
                Color(0xFF1D4ED8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Card(
                color: AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                  side: const BorderSide(color: AppTheme.border),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppTheme.primary,
                          child: const Icon(
                            Icons.sports_soccer,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'PichangApp',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Encuentra compañeros deportivos reales',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 26),
                        TextFormField(
                          controller: _authController.usernameController,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingresa tu usuario';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _authController.passwordController,
                          obscureText: _obscureText,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _mostrarRecuperarPassword,
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(color: AppTheme.primarySoft),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Text(
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterView(),
                                    ),
                                  );
                                },
                          child: const Text(
                            '¿No tienes cuenta? Regístrate aquí',
                            style: TextStyle(color: AppTheme.primarySoft),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Al continuar aceptas los términos y condiciones.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}