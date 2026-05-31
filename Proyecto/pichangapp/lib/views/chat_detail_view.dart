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
  late List<ChatMessage> _mensajes;

  @override
  void initState() {
    super.initState();
    // Cargamos los mensajes ESPECÍFICOS de esta sala de chat
    _mensajes = _chatController.obtenerMensajesPorChat(widget.chat.chatId);
  }

  void _enviarMensajeSimulado() {
    if (_messageInputController.text.trim().isEmpty) return;

    setState(() {
      // Simulamos agregar el mensaje a la lista (luego esto será un POST al backend o un evento emitido)
      _mensajes.add(
        ChatMessage(
          messageId: DateTime.now().toString(),
          senderId: _chatController.miPropioId, // Lo marco como mío
          text: _messageInputController.text.trim(),
          timestamp: "Ahora",
        ),
      );
      _messageInputController.clear();
    });
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mensajes.length,
              itemBuilder: (context, index) {
                final mensaje = _mensajes[index];
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
                      onPressed: _enviarMensajeSimulado,
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