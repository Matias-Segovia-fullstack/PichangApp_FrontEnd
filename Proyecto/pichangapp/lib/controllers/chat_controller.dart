import '../services/api_service.dart';

// 1. Modelo que mapea la respuesta de tu base de datos para la lista de chats
class MatchChat {
  final String chatId;
  final int otherUserId; 
  final String athleteName;
  final String imageUrl;
  final String lastMessage;
  final String timestamp;
  final bool isUnread;

  MatchChat({
    required this.chatId,
    required this.otherUserId,
    required this.athleteName,
    required this.imageUrl,
    required this.lastMessage,
    required this.timestamp,
    required this.isUnread,
  });
}

// 2. Modelo para un mensaje individual dentro de una conversación
class ChatMessage {
  final String messageId;
  final int senderId; 
  final String text;
  final String timestamp;

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });
}

// 3. Controlador unificado que gestiona toda la lógica
class ChatController {
  final ApiService _apiService = ApiService();
  final int miPropioId = 1; // Usando 1 para la demo

  Future<List<MatchChat>> obtenerChatsDelBackend() async {
    final salas = await _apiService.getUserRooms(miPropioId);
    List<MatchChat> chats = [];

    for (var sala in salas) {
      String chatId = sala['id'].toString();
      int uA = sala['usuarioAId'] ?? 0;
      int uB = sala['usuarioBId'] ?? 0;
      int otherUserId = (uA == miPropioId) ? uB : uA;

      // Obtener datos del otro usuario
      var otherUser = await _apiService.getUsuario(otherUserId);
      String name = otherUser?['nombre'] ?? 'Usuario $otherUserId';

      chats.add(MatchChat(
        chatId: chatId,
        otherUserId: otherUserId,
        athleteName: name,
        imageUrl: "https://via.placeholder.com/150?text=$name",
        lastMessage: "Haz tap para chatear", // En el futuro se puede sacar del ultimo mensaje
        timestamp: "Ahora",
        isUnread: false,
      ));
    }
    return chats;
  }
  
  Future<List<ChatMessage>> obtenerMensajesPorChat(String chatId) async {
    // Si chatId fuera entero en el backend, en MongoDB suele ser String.
    // Usamos temporalmente 1 como dummy para el backend local si no es mongo,
    // o castear. Pero en tu API parece que salas/{salaId} salaId es Long en Java, o String en MongoDB.
    // Veamos cómo lo declaraste: en SalaChatController es Long salaId!
    // Entonces chatId debería ser int.
    // Vamos a parchearlo convirtiendo a entero o parseando.
    int salaIdInt = int.tryParse(chatId) ?? 0;
    
    final mensajes = await _apiService.getMensajes(salaIdInt);
    return mensajes.map((m) {
      return ChatMessage(
        messageId: (m['id'] ?? 0).toString(),
        senderId: m['remitenteId'] ?? 0,
        text: m['contenido'] ?? '',
        timestamp: m['fechaEnvio'] ?? '',
      );
    }).toList();
  }

  Future<bool> enviarMensaje(String chatId, String texto) async {
    int salaIdInt = int.tryParse(chatId) ?? 0;
    return await _apiService.enviarMensaje(salaIdInt, miPropioId, texto);
  }

}