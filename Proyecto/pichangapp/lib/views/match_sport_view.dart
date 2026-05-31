import 'package:flutter/material.dart';
import '../controllers/mock_data_controller.dart';
import '../models/deportista.dart';
import 'report_user_view.dart';

class MatchSportView extends StatefulWidget {
  const MatchSportView({super.key});

  @override
  State<MatchSportView> createState() => _MatchSportViewState();
}

class _MatchSportViewState extends State<MatchSportView> {
  final List<Deportista> _deportistas = MockDataController.deportistas();
  int _indiceActual = 0;

  void _siguientePerfil(String accion) {
    final deportista = _deportistas[_indiceActual];

    if (accion == 'Like' && deportista.nombre == 'Luis') {
      _mostrarMatch(deportista);
    }

    setState(() {
      _indiceActual++;
    });
  }

  void _mostrarMatch(Deportista deportista) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¡Nuevo MatchSocial!'),
        content: Text(
          '${deportista.nombre} también quiere coordinar deporte contigo. En backend esto debería crear SalaChat por RabbitMQ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Seguir descubriendo'),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'PichangApp',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _indiceActual >= _deportistas.length
          ? const Center(
              child: Text(
                'No hay más deportistas en tu zona',
                style: TextStyle(fontSize: 18),
              ),
            )
          : _construirTarjeta(_deportistas[_indiceActual]),
    );
  }

  Widget _construirTarjeta(Deportista deportista) {
    return Column(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(20),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.network(
                      deportista.fotoUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${deportista.nombre}, ${deportista.edad}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.report, color: Colors.orange),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportUserView(
                                  nombreReportado: deportista.nombre,
                                  usuarioReportadoId: deportista.id,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${deportista.deporte} · ${deportista.posicion} · ${deportista.nivel}',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${deportista.comuna} · ${deportista.distanciaKm} km · Altura ${deportista.altura}m',
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _stat('Estamina', deportista.estamina),
                          _stat('Velocidad', deportista.velocidad),
                          _stat('Fuerza', deportista.fuerza),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 40, top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'btn_dislike',
                onPressed: () => _siguientePerfil('Dislike'),
                backgroundColor: Colors.white,
                child: const Icon(Icons.close, size: 35, color: Colors.red),
              ),
              FloatingActionButton(
                heroTag: 'btn_like',
                onPressed: () => _siguientePerfil('Like'),
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