import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/deportes.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CreateSquadView extends StatefulWidget {
  const CreateSquadView({super.key});

  @override
  State<CreateSquadView> createState() => _CreateSquadViewState();
}

class _CreateSquadViewState extends State<CreateSquadView> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  bool _isSaving = false;
  String _deporte = AppDeportes.deportePredeterminado;
  int _maxIntegrantes = 5;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<Position?> _obtenerUbicacion() async {
    try {
      final servicioHabilitado = await Geolocator.isLocationServiceEnabled();

      if (!servicioHabilitado) {
        return null;
      }

      LocationPermission permiso = await Geolocator.checkPermission();

      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever ||
          permiso == LocationPermission.unableToDetermine) {
        return null;
      }

      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _crearSquad() async {
    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim();

    if (nombre.isEmpty || descripcion.isEmpty || _isSaving) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa nombre y descripción del squad.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final userIdString = await _storage.read(key: 'user_id');
    final userId = int.tryParse(userIdString ?? '');

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar el usuario.'),
        ),
      );
      return;
    }

    final posicion = await _obtenerUbicacion();

    final ok = await _apiService.crearSquad(
      creadorId: userId,
      nombre: nombre,
      deporte: _deporte,
      descripcion: descripcion,
      maxIntegrantes: _maxIntegrantes,
      latitud: posicion?.latitude,
      longitud: posicion?.longitude,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo crear el squad.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        title: const Text(
          'Crear Squad',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Arma un grupo para buscar jugadores.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nombreController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Nombre del squad',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descripcionController,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Descripción',
              hintText: 'Ej: buscamos base y alero para jugar este viernes.',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _deporte,
            dropdownColor: AppTheme.surface,
            decoration: InputDecoration(
              labelText: 'Deporte',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: AppDeportes.deportes.map((deporte) {
              return DropdownMenuItem<String>(
                value: deporte.codigo,
                child: Text(deporte.nombre),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _deporte = value;
              });
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Máximo de integrantes: $_maxIntegrantes',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: _maxIntegrantes.toDouble(),
            min: 2,
            max: 20,
            divisions: 18,
            label: _maxIntegrantes.toString(),
            onChanged: (value) {
              setState(() {
                _maxIntegrantes = value.round();
              });
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isSaving ? null : _crearSquad,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.groups),
            label: const Text('Crear Squad'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}