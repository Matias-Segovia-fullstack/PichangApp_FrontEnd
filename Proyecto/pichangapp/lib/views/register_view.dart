import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // Instanciamos el mismo controlador para manejar los inputs y la lógica del RUT
  final _authController = AuthController();

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta Deportiva'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Vuelve al Login
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Campo Nombre Completo
                TextField(
                  controller: _authController.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Correo
                TextField(
                  controller: _authController.emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Campo Contraseña
                TextField(
                  controller: _authController.passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 16),

                // CAMPO RUT (El que gatilla el cálculo de género)
                TextField(
                  controller: _authController.rutController,
                  decoration: const InputDecoration(
                    labelText: 'RUT (ej: 12345678-9)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  onChanged: (value) {
                    // Cada vez que el usuario escribe un carácter, ejecutamos la lógica
                    setState(() {
                      _authController.procesarRut(value);
                    });
                  },
                ),
                const SizedBox(height: 16),

                // CAMPO GÉNERO (Deshabilitado, se auto-rellena con el RUT)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200], // Fondo gris para denotar que está bloqueado
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wc, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        'Género: ${_authController.generoCalculado}',
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Finalizar Registro
                ElevatedButton(
                  onPressed: () {
                    // Aquí simulamos que el registro fue exitoso y volvemos al login
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cuenta creada con éxito. Ya puedes iniciar sesión.')),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Registrarme'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}