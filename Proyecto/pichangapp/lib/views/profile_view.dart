import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../controllers/auth_controller.dart';
import 'login_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ApiService _apiService = ApiService();
  final AuthController _authController = AuthController();
  
  // Usamos el mismo ID estático de la demo (1)
  final int miPropioId = 1;

  Future<Map<String, dynamic>?>? _perfilFuture;

  @override
  void initState() {
    super.initState();
    _perfilFuture = _apiService.getUsuario(miPropioId);
  }

  void _cerrarSesion() async {
    await _authController.logout();
    
    // Navegar de vuelta al login, eliminando todo el historial de pantallas
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar Sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _perfilFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error cargando perfil: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No se pudo cargar la información del perfil.'));
          }

          final user = snapshot.data!;
          final String nombre = user['nombre'] ?? 'Sin nombre';
          final String apellido = user['apellido'] ?? '';
          final String username = user['username'] ?? '@usuario';
          final String email = user['email'] ?? 'correo@ejemplo.com';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Foto de perfil
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: NetworkImage('https://via.placeholder.com/150?text=$nombre'),
                ),
                const SizedBox(height: 16),
                // Nombre completo
                Text(
                  '$nombre $apellido',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Username
                Text(
                  '@$username',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                
                // Tarjeta con información detallada
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.email, 'Correo Electrónico', email),
                        const Divider(height: 32),
                        _buildInfoRow(Icons.person, 'Nombre de Usuario', username),
                        const Divider(height: 32),
                        _buildInfoRow(Icons.sports_soccer, 'Deporte Favorito', 'Fútbol (Demo)'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Botón de cerrar sesión grande
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _cerrarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Cerrar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget auxiliar para las filas de información
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
