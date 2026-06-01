import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';

class ChatDetailView extends StatefulWidget {
  final MatchChat chat; // Recibe toda la info del usuario con el que hacemos match

  const ChatDetailView({super.key, required this.chat});

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final _chatController = ChatController();
  final _messageInputController = TextEditingController();
  late Future<List<ChatMessage>> _mensajesFuture;

  @override
  void initState() {
    super.initState();
    // Cargamos los mensajes ESPECÍFICOS de esta sala de chat
    _mensajesFuture = _chatController.obtenerMensajesPorChat(widget.chat.chatId);
  }

  void _enviarMensaje() async {
    if (_messageInputController.text.trim().isEmpty) return;

    String texto = _messageInputController.text.trim();
    _messageInputController.clear();
    
    // Enviar el POST al backend
    bool exito = await _chatController.enviarMensaje(widget.chat.chatId, texto);
    if (exito) {
      // Recargar mensajes
      setState(() {
        _mensajesFuture = _chatController.obtenerMensajesPorChat(widget.chat.chatId);
      });
    } else {
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar mensaje')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.chat.imageUrl),
            ),
            const SizedBox(width: 12),
            Text(widget.chat.athleteName, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Área de los mensajes
          Expanded(
            child: FutureBuilder<List<ChatMessage>>(
              future: _mensajesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay mensajes aún. ¡Rompe el hielo!'));
                }

                final mensajes = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    final mensaje = mensajes[index];
                    // Comprobamos si el mensaje lo envié yo o la otra persona
                    final isMe = mensaje.senderId == _chatController.miPropioId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              mensaje.text,
                              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mensaje.timestamp,
                              style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Barra inferior para escribir mensajes
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageInputController,
                      decoration: InputDecoration(
                        hintText: "Escribe un mensaje...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _enviarMensaje,
                    ),
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