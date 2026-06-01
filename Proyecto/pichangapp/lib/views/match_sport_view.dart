import 'package:flutter/material.dart';
import '../models/deportista.dart';
import '../services/api_service.dart';

class MatchSportView extends StatefulWidget {
  const MatchSportView({super.key});

  @override
  State<MatchSportView> createState() => _MatchSportViewState();
}

class _MatchSportViewState extends State<MatchSportView> {
  final ApiService _apiService = ApiService();
  List<Deportista> _deportistas = [];
  bool _isLoading = true;
  int _indiceActual = 0;
  
  // Usaremos un ID de origen fijo (1) para la demo, asumiendo que es el usuario logueado.
  final int _miPropioId = 1; 

  @override
  void initState() {
    super.initState();
    _cargarDeportistas();
  }

  Future<void> _cargarDeportistas() async {
    final List<dynamic> users = await _apiService.getPosiblesMatches();
    setState(() {
      _deportistas = users.where((u) => u['id'] != _miPropioId).map((u) {
        return Deportista(
          id: u['id'] ?? 0,
          nombre: u['nombre'] ?? 'Sin nombre',
          edad: 25, // Datos de relleno hasta tener perfil completo
          deporte: "Deporte", 
          altura: 1.75,
          nivel: "Amateur",
          fotoUrl: "https://via.placeholder.com/400x500.png?text=${u['nombre'] ?? 'User'}",
        );
      }).toList();
      _isLoading = false;
    });
  }

  // 2. Lógica de transición
  void _siguientePerfil(String accion) {
    if (_indiceActual < _deportistas.length) {
      Deportista actual = _deportistas[_indiceActual];
      String tipoInteraccion = accion == "Like" ? "ME_GUSTA" : "NO_ME_GUSTA";
      
      // Enviar interacción al backend
      _apiService.enviarInteraccion(_miPropioId, actual.id, tipoInteraccion);
      
      setState(() {
        _indiceActual++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('PichangApp', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      // Si ya no hay más perfiles, mostramos un mensaje final
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _indiceActual >= _deportistas.length
              ? const Center(child: Text("No hay más deportistas en tu zona", style: TextStyle(fontSize: 18)))
              : _construirTarjeta(_deportistas[_indiceActual]),
    );
  }

  // 3. Extracción del Widget de la Tarjeta para mantener el código limpio
  Widget _construirTarjeta(Deportista deportista) {
    return Column(
      children: [
        // Contenedor principal de la tarjeta
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(20),
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagen
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      deportista.fotoUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Datos del deportista
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${deportista.nombre}, ${deportista.edad}', 
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${deportista.deporte} - Nivel: ${deportista.nivel}', 
                        style: TextStyle(fontSize: 18, color: Colors.grey[700])
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Altura: ${deportista.altura}m', 
                        style: TextStyle(fontSize: 16, color: Colors.grey[600])
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        // Fila de Botones (Row)
        Padding(
          padding: const EdgeInsets.only(bottom: 40.0, top: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón Dislike
              FloatingActionButton(
                heroTag: "btn_dislike",
                onPressed: () => _siguientePerfil("Dislike"),
                backgroundColor: Colors.white,
                child: const Icon(Icons.close, size: 35, color: Colors.red),
              ),
              // Botón Like
              FloatingActionButton(
                heroTag: "btn_like",
                onPressed: () => _siguientePerfil("Like"),
                backgroundColor: Colors.white,
                child: const Icon(Icons.favorite, size: 35, color: Colors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }
}