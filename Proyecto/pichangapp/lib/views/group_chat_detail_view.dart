import 'package:flutter/material.dart';
import '../models/group_chat_mock.dart';

class GroupChatDetailView extends StatefulWidget {
  final GroupChatMock grupo;

  const GroupChatDetailView({
    super.key,
    required this.grupo,
  });

  @override
  State<GroupChatDetailView> createState() => _GroupChatDetailViewState();
}

class _GroupChatDetailViewState extends State<GroupChatDetailView> {
  final _controller = TextEditingController();

  final List<String> _mensajes = [
    '¿Quién confirma asistencia?',
    'Yo voy, llevo agua.',
    'Faltan jugadores para cerrar cancha.',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enviar() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _mensajes.add(_controller.text.trim());
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.grupo.nombre),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Text(
              '${widget.grupo.deporte} · ${widget.grupo.comuna} · ${widget.grupo.participantes}/${widget.grupo.cupos} jugadores\n${widget.grupo.horario}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mensajes.length,
              itemBuilder: (context, index) {
                final isMe = index == _mensajes.length - 1 && index > 2;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _mensajes[index],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Mensaje grupal mockup',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _enviar,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}