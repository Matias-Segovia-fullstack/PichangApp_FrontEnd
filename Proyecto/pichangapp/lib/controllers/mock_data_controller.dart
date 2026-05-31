import '../models/deportista.dart';
import '../models/group_chat_mock.dart';
import '../models/notification_mock.dart';

class MockDataController {
  static List<Deportista> deportistas() {
    return [
      Deportista(
        id: 18,
        nombre: 'Carlos',
        edad: 25,
        deporte: 'Fútbol',
        altura: 1.78,
        nivel: 'Amateur',
        fotoUrl: 'https://via.placeholder.com/400x500.png?text=Carlos+Futbol',
        comuna: 'La Florida',
        distanciaKm: 2.4,
        posicion: 'Delantero',
        estamina: 78,
        velocidad: 84,
        fuerza: 70,
      ),
      Deportista(
        id: 19,
        nombre: 'Andrea',
        edad: 22,
        deporte: 'Tenis',
        altura: 1.65,
        nivel: 'Intermedio',
        fotoUrl: 'https://via.placeholder.com/400x500.png?text=Andrea+Tenis',
        comuna: 'Ñuñoa',
        distanciaKm: 4.1,
        posicion: 'Singles',
        estamina: 82,
        velocidad: 76,
        fuerza: 65,
      ),
      Deportista(
        id: 20,
        nombre: 'Luis',
        edad: 28,
        deporte: 'Básquetbol',
        altura: 1.90,
        nivel: 'Avanzado',
        fotoUrl: 'https://via.placeholder.com/400x500.png?text=Luis+Basquet',
        comuna: 'Macul',
        distanciaKm: 3.2,
        posicion: 'Alero',
        estamina: 88,
        velocidad: 80,
        fuerza: 86,
      ),
    ];
  }

  static List<Deportista> bloqueados() {
    return [
      Deportista(
        id: 31,
        nombre: 'Marcos',
        edad: 30,
        deporte: 'Fútbol',
        altura: 1.74,
        nivel: 'Recreativo',
        fotoUrl: 'https://via.placeholder.com/400x500.png?text=Usuario+Bloqueado',
        comuna: 'Santiago Centro',
        distanciaKm: 5.8,
        posicion: 'Mediocampo',
        estamina: 60,
        velocidad: 62,
        fuerza: 64,
      ),
      Deportista(
        id: 32,
        nombre: 'Paula',
        edad: 27,
        deporte: 'Running',
        altura: 1.68,
        nivel: 'Intermedio',
        fotoUrl: 'https://via.placeholder.com/400x500.png?text=Bloqueada',
        comuna: 'Providencia',
        distanciaKm: 6.3,
        posicion: '5K',
        estamina: 72,
        velocidad: 70,
        fuerza: 58,
      ),
    ];
  }

  static List<NotificationMock> notificaciones() {
    return [
      NotificationMock(
        id: 'n1',
        titulo: 'Nuevo MatchSocial',
        mensaje: 'Luis también quiere jugar básquet contigo. Ya se creó una sala de chat.',
        fecha: 'Ahora',
        leida: false,
        tipo: 'match',
      ),
      NotificationMock(
        id: 'n2',
        titulo: 'Mensaje recibido',
        mensaje: 'Andrea respondió en el chat: Yo llevo las pelotas de tenis.',
        fecha: 'Ayer',
        leida: true,
        tipo: 'mensaje',
      ),
      NotificationMock(
        id: 'n3',
        titulo: 'Reporte en revisión',
        mensaje: 'Tu reporte fue recibido por Safety y quedó en estado PENDIENTE.',
        fecha: 'Lun',
        leida: true,
        tipo: 'safety',
      ),
    ];
  }

  static List<GroupChatMock> grupos() {
    return [
      GroupChatMock(
        id: 'g1',
        nombre: 'Pichanga Mixta Sábado',
        deporte: 'Fútbol 7',
        comuna: 'La Florida',
        cupos: 14,
        participantes: 9,
        horario: 'Sábado 18:00',
        ultimoMensaje: 'Faltan 5 jugadores para cerrar la cancha.',
      ),
      GroupChatMock(
        id: 'g2',
        nombre: 'Basket Parque Bustamante',
        deporte: 'Básquetbol',
        comuna: 'Providencia',
        cupos: 10,
        participantes: 6,
        horario: 'Miércoles 20:00',
        ultimoMensaje: 'Confirmen quién lleva balón.',
      ),
    ];
  }
}