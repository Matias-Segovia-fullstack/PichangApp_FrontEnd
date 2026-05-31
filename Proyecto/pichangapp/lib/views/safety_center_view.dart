import 'package:flutter/material.dart';
import 'blocked_users_view.dart';
import 'report_user_view.dart';

class SafetyCenterView extends StatelessWidget {
  const SafetyCenterView({super.key});

  Widget _accion(
    BuildContext context,
    IconData icon,
    String titulo,
    String descripcion,
    Widget destino,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(descripcion),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destino),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Center'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.blue[50],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo seguro deportivo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'PichangApp busca evitar usos románticos o sexuales. Esta zona agrupa reportes, bloqueos y reglas de convivencia.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _accion(
            context,
            Icons.report,
            'Reportar usuario',
            'Mockup de formulario que luego enviará POST /api/safety/reportar',
            const ReportUserView(
              nombreReportado: 'Usuario de prueba',
              usuarioReportadoId: 19,
            ),
          ),
          _accion(
            context,
            Icons.block,
            'Ver bloqueados',
            'Lista mockup de usuarios bloqueados por el perfil actual',
            const BlockedUsersView(),
          ),
          Card(
            child: SwitchListTile(
              value: true,
              title: const Text('Filtrar perfiles reportados'),
              subtitle: const Text(
                'Mockup: luego ocultará perfiles con reportes activos',
              ),
              onChanged: (_) {},
            ),
          ),
          Card(
            child: SwitchListTile(
              value: true,
              title: const Text('Solo mensajes con MatchSocial'),
              subtitle: const Text('Regla de negocio principal del chat'),
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}