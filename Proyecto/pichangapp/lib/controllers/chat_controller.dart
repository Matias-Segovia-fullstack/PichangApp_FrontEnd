// 1. Modelo que mapea la futura respuesta de tu base de datos para la lista de chats
class MatchChat {
  final String chatId;
  final String userId; 
  final String athleteName;
  final String imageUrl;
  final String lastMessage;
  final String timestamp;
  final bool isUnread;

  MatchChat({
    required this.chatId,
    required this.userId,
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
  final String senderId; 
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
  
  // Mi propio ID simulado (clave para alinear los mensajes a la derecha o izquierda)
  final String miPropioId = "mi_usuario_123";

  // Retorna la lista general de conversaciones
  List<MatchChat> obtenerChatsSimulados() {
    return [
      MatchChat(
        chatId: "chat_001",
        userId: "user_88",
        athleteName: "Carlos, 28",
        imageUrl: "https://i.pravatar.cc/150?img=11", 
        lastMessage: "¡Genial! ¿Nos vemos el sábado en la cancha entonces?",
        timestamp: "10:30 AM",
        isUnread: true,
      ),
      MatchChat(
        chatId: "chat_002",
        userId: "user_45",
        athleteName: "Andrea, 25",
        imageUrl: "https://i.pravatar.cc/150?img=5",
        lastMessage: "Yo llevo las pelotas de tenis.",
        timestamp: "Ayer",
        isUnread: false,
      ),
      MatchChat(
        chatId: "chat_003",
        userId: "user_12",
        athleteName: "Felipe, 31",
        imageUrl: "https://i.pravatar.cc/150?img=68",
        lastMessage: "Me parece perfecto, confirmo asistencia.",
        timestamp: "Lun",
        isUnread: false,
      ),
    ];
  }
  
  // Retorna los mensajes específicos de una sala
  List<ChatMessage> obtenerMensajesPorChat(String chatId) {
    if (chatId == "chat_001") {
      return [
        ChatMessage(messageId: "m1", senderId: "user_88", text: "Hola, vi que juegas tenis.", timestamp: "10:00 AM"),
        ChatMessage(messageId: "m2", senderId: miPropioId, text: "¡Hola Carlos! Sí, nivel intermedio.", timestamp: "10:15 AM"),
        ChatMessage(messageId: "m3", senderId: "user_88", text: "¡Genial! ¿Nos vemos el sábado en la cancha entonces?", timestamp: "10:30 AM"),
      ];
    } else if (chatId == "chat_002") {
      return [
        ChatMessage(messageId: "m4", senderId: miPropioId, text: "¿Tienes raqueta extra?", timestamp: "Ayer"),
        ChatMessage(messageId: "m5", senderId: "user_45", text: "Sí, tranquila. Yo llevo las pelotas de tenis.", timestamp: "Ayer"),
      ];
    } else if (chatId == "chat_003") {
      return [
        ChatMessage(messageId: "m6", senderId: miPropioId, text: "¿A qué hora el partido?", timestamp: "Lun"),
        ChatMessage(messageId: "m7", senderId: "user_12", text: "Me parece perfecto, confirmo asistencia.", timestamp: "Lun"),
      ];
    }
    return []; 
  }
}