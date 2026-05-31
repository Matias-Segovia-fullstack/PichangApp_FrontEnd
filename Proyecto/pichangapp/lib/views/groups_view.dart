import 'package:flutter/material.dart';
import '../controllers/mock_data_controller.dart';
import 'create_group_view.dart';
import 'group_chat_detail_view.dart';

class GroupsView extends StatelessWidget {
  const GroupsView({super.key});

  @override
  Widget build(BuildContext context) {
    final grupos = MockDataController.grupos();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Squads y grupos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupView()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Mockup de chats grupales. Luego puede conectarse a RabbitMQ, WebSocket o Supabase Realtime para mensajes en vivo.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...grupos.map(
            (grupo) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.groups, color: Colors.blue),
                ),
                title: Text(
                  grupo.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${grupo.deporte} · ${grupo.comuna}\n${grupo.participantes}/${grupo.cupos} jugadores · ${grupo.horario}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupChatDetailView(grupo: grupo),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}