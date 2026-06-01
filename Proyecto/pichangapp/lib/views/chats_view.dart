import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';
import 'chat_detail_view.dart';

class ChatsView extends StatefulWidget {
  const ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  final _chatController = ChatController();
  late Future<List<MatchChat>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    _chatsFuture = _chatController.obtenerChatsDelBackend();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Matches y Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<List<MatchChat>>(
        future: _chatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error cargando chats: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aún no tienes matches.'));
          }

          final chats = snapshot.data!;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(chat.imageUrl), // Carga la imagen de internet
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      chat.athleteName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      chat.timestamp,
                      style: TextStyle(
                        fontSize: 12,
                        color: chat.isUnread ? Colors.blue : Colors.grey,
                        fontWeight: chat.isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: chat.isUnread ? Colors.black87 : Colors.grey,
                    fontWeight: chat.isUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Le inyectamos la data específica a la pantalla
                      builder: (context) => ChatDetailView(chat: chat), 
                    ),
                  ).then((_) {
                    // Recargar chats al volver por si hay mensajes nuevos
                    setState(() {
                      _chatsFuture = _chatController.obtenerChatsDelBackend();
                    });
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}