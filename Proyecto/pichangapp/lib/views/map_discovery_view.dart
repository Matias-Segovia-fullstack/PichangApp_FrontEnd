import 'package:flutter/material.dart';
import '../controllers/mock_data_controller.dart';

class MapDiscoveryView extends StatelessWidget {
  const MapDiscoveryView({super.key});

  @override
  Widget build(BuildContext context) {
    final deportistas = MockDataController.deportistas();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa deportivo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Text(
                    'Mockup de mapa\nAquí irá geolocalización real',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const Positioned(
                  top: 40,
                  left: 60,
                  child: Icon(Icons.location_on, color: Colors.red, size: 36),
                ),
                const Positioned(
                  top: 130,
                  right: 80,
                  child: Icon(Icons.location_on, color: Colors.blue, size: 36),
                ),
                const Positioned(
                  bottom: 50,
                  left: 160,
                  child: Icon(Icons.location_on, color: Colors.orange, size: 36),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Deportistas cercanos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...deportistas.map(
            (d) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(d.fotoUrl),
                ),
                title: Text('${d.nombre} · ${d.deporte}'),
                subtitle: Text('${d.comuna} · ${d.distanciaKm} km · ${d.nivel}'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ),
    );
  }
}