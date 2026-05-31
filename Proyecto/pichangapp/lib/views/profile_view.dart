import 'package:flutter/material.dart';
import 'blocked_users_view.dart';
import 'notifications_view.dart';
import 'safety_center_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Widget _stat(String label, int value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Widget destino,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destino),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Athlete Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsView()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/200x200.png?text=Tom',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tom, 25',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Basket · Base · Nivel Amateur',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _stat('Estamina', 82, Icons.favorite),
                      _stat('Velocidad', 76, Icons.speed),
                      _stat('Fuerza', 69, Icons.fitness_center),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Busco gente para jugar basket después de clases y armar partidos recreativos los fines de semana.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _menuTile(
            context,
            Icons.shield,
            'Safety Center',
            'Reportes, bloqueos y reglas de uso deportivo',
            const SafetyCenterView(),
          ),
          _menuTile(
            context,
            Icons.block,
            'Usuarios bloqueados',
            'Mockup de personas bloqueadas por el usuario',
            const BlockedUsersView(),
          ),
          _menuTile(
            context,
            Icons.notifications_active,
            'Notificaciones',
            'Matches, mensajes y alertas pendientes',
            const NotificationsView(),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión'),
              subtitle: const Text('Mockup: luego eliminará el JWT local'),
              onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ),
        ],
      ),
    );
  }
}