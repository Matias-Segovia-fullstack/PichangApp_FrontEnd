import 'package:flutter/material.dart';
import '../controllers/mock_data_controller.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  IconData _icono(String tipo) {
    if (tipo == 'match') return Icons.favorite;
    if (tipo == 'mensaje') return Icons.chat;
    if (tipo == 'safety') return Icons.shield;
    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    final notificaciones = MockDataController.notificaciones();

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Mockup del microservicio msvc-notificacion. Luego mostrará eventos reales de match, mensajes, reportes y cambios de estado.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...notificaciones.map(
            (n) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: n.leida ? Colors.grey[300] : Colors.blue[100],
                  child: Icon(
                    _icono(n.tipo),
                    color: n.leida ? Colors.grey : Colors.blue,
                  ),
                ),
                title: Text(
                  n.titulo,
                  style: TextStyle(
                    fontWeight: n.leida ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(n.mensaje),
                trailing: Text(n.fecha, style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}