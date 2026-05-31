import 'package:flutter/material.dart';

class ReportUserView extends StatefulWidget {
  final String nombreReportado;
  final int usuarioReportadoId;

  const ReportUserView({
    super.key,
    required this.nombreReportado,
    required this.usuarioReportadoId,
  });

  @override
  State<ReportUserView> createState() => _ReportUserViewState();
}

class _ReportUserViewState extends State<ReportUserView> {
  String _motivo = 'Uso romántico o sexual';
  final _descripcionController = TextEditingController();

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  void _enviarReporte() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mockup: reporte enviado contra ${widget.nombreReportado}.'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar usuario'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Estás reportando a ${widget.nombreReportado} (ID ${widget.usuarioReportadoId}). En la versión real esto enviará idUsuarioDenunciante, idUsuarioDenunciado, motivo y descripción a msvc-seguridad.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _motivo,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Uso romántico o sexual',
                child: Text('Uso romántico o sexual'),
              ),
              DropdownMenuItem(
                value: 'Acoso o insistencia',
                child: Text('Acoso o insistencia'),
              ),
              DropdownMenuItem(
                value: 'Perfil falso',
                child: Text('Perfil falso'),
              ),
              DropdownMenuItem(
                value: 'Lenguaje ofensivo',
                child: Text('Lenguaje ofensivo'),
              ),
              DropdownMenuItem(
                value: 'Otro',
                child: Text('Otro'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _motivo = value ?? _motivo;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descripcionController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              hintText: 'Explica brevemente qué ocurrió',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _enviarReporte,
            icon: const Icon(Icons.report),
            label: const Text('Enviar reporte'),
          ),
        ],
      ),
    );
  }
}