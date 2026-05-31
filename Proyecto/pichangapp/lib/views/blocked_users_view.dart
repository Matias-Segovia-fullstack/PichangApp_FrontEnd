import 'package:flutter/material.dart';
import '../controllers/mock_data_controller.dart';

class BlockedUsersView extends StatefulWidget {
  const BlockedUsersView({super.key});

  @override
  State<BlockedUsersView> createState() => _BlockedUsersViewState();
}

class _BlockedUsersViewState extends State<BlockedUsersView> {
  late final _bloqueados = MockDataController.bloqueados();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios bloqueados')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Esta pantalla es una maqueta del módulo Safety. En la versión real consumirá GET /api/safety/bloqueos/user/{idUsuario} y permitirá desbloquear usuarios.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._bloqueados.map(
            (usuario) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(usuario.fotoUrl),
                ),
                title: Text(
                  '${usuario.nombre}, ${usuario.edad}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${usuario.deporte} · ${usuario.comuna}'),
                trailing: TextButton(
                  child: const Text('Desbloquear'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Mockup: ${usuario.nombre} fue desbloqueado.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}