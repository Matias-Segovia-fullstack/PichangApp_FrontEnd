import 'package:flutter/material.dart';

class CreateGroupView extends StatefulWidget {
  const CreateGroupView({super.key});

  @override
  State<CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<CreateGroupView> {
  final _nombreController = TextEditingController();
  String _deporte = 'Fútbol 7';
  String _comuna = 'La Florida';
  double _cupos = 10;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  void _crearGrupo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mockup: grupo creado correctamente.'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Squad'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Esta pantalla simula la creación de un chat grupal deportivo. Luego debería usar un endpoint backend para crear grupo/sala.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre del grupo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _deporte,
            decoration: const InputDecoration(
              labelText: 'Deporte',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Fútbol 7', child: Text('Fútbol 7')),
              DropdownMenuItem(value: 'Básquetbol', child: Text('Básquetbol')),
              DropdownMenuItem(value: 'Tenis', child: Text('Tenis')),
              DropdownMenuItem(value: 'Running', child: Text('Running')),
            ],
            onChanged: (value) {
              setState(() {
                _deporte = value ?? _deporte;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _comuna,
            decoration: const InputDecoration(
              labelText: 'Comuna',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'La Florida', child: Text('La Florida')),
              DropdownMenuItem(value: 'Providencia', child: Text('Providencia')),
              DropdownMenuItem(value: 'Ñuñoa', child: Text('Ñuñoa')),
              DropdownMenuItem(value: 'Macul', child: Text('Macul')),
            ],
            onChanged: (value) {
              setState(() {
                _comuna = value ?? _comuna;
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Cupos: ${_cupos.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _cupos,
            min: 2,
            max: 22,
            divisions: 20,
            label: _cupos.toInt().toString(),
            onChanged: (value) {
              setState(() {
                _cupos = value;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _crearGrupo,
            icon: const Icon(Icons.groups),
            label: const Text('Crear Squad'),
          ),
        ],
      ),
    );
  }
}