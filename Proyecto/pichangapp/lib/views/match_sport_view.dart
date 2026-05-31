import 'package:flutter/material.dart';
import '../models/deportista.dart';

class MatchSportView extends StatefulWidget {
  const MatchSportView({super.key});

  @override
  State<MatchSportView> createState() => _MatchSportViewState();
}

class _MatchSportViewState extends State<MatchSportView> {
  // 1. Datos simulados (Mock Data). En el futuro, esto se llenará mediante una petición HTTP GET.
  final List<Deportista> _deportistas = [
    Deportista(nombre: "Carlos", edad: 25, deporte: "Fútbol", altura: 1.78, nivel: "Amateur", fotoUrl: "https://via.placeholder.com/400x500.png?text=Carlos+Futbol"),
    Deportista(nombre: "Andrea", edad: 22, deporte: "Tenis", altura: 1.65, nivel: "Intermedio", fotoUrl: "https://via.placeholder.com/400x500.png?text=Andrea+Tenis"),
    Deportista(nombre: "Luis", edad: 28, deporte: "Básquetbol", altura: 1.90, nivel: "Avanzado", fotoUrl: "https://via.placeholder.com/400x500.png?text=Luis+Basquet"),
  ];

  int _indiceActual = 0;

  // 2. Lógica de transición
  void _siguientePerfil(String accion) {
    // Imprimimos en consola usando debugPrint (buena práctica en Flutter)
    debugPrint("$accion registrado para: ${_deportistas[_indiceActual].nombre}"); 
    
    setState(() {
      if (_indiceActual < _deportistas.length) {
        _indiceActual++;
      }
    });
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
      body: _indiceActual >= _deportistas.length
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