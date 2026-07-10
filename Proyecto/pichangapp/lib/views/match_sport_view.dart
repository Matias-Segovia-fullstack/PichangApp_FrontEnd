import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../models/deportista.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MatchSportView extends StatefulWidget {
  const MatchSportView({super.key});

  @override
  State<MatchSportView> createState() => _MatchSportViewState();
}

class _MatchSportViewState extends State<MatchSportView> {
  static const String tipoLike = 'ME_GUSTA';
  static const String tipoDislike = 'DISME_GUSTA';

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<Deportista> _deportistas = [];
  int _indiceActual = 0;
  int? _miUsuarioId;

  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  double _distanciaMaxKm = 1;

  int _edadMin = 18;
  int _edadMax = 80;
  String _sexoFiltro = 'Todos';

  double? _miLatitudActual;
  double? _miLongitudActual;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _cargarConfiguracionFiltros();
    await _cargarDeportistas();
  }

  Future<void> _cargarConfiguracionFiltros() async {
    final maxTexto = await _storage.read(key: 'discover_distancia_max_km');
    final edadMinTexto = await _storage.read(key: 'discover_edad_min');
    final edadMaxTexto = await _storage.read(key: 'discover_edad_max');
    final sexoTexto = await _storage.read(key: 'discover_sexo');

    final max = double.tryParse(maxTexto ?? '');

    _distanciaMaxKm = _limitarDistancia(max ?? 1);

    _edadMin = int.tryParse(edadMinTexto ?? '') ?? 18;
    _edadMax = int.tryParse(edadMaxTexto ?? '') ?? 80;
    _sexoFiltro = sexoTexto ?? 'Todos';

    if (_edadMin < 18) _edadMin = 18;
    if (_edadMax > 100) _edadMax = 100;

    if (_edadMin > _edadMax) {
      final temporal = _edadMin;
      _edadMin = _edadMax;
      _edadMax = temporal;
    }

    if (!['Todos', 'Masculino', 'Femenino'].contains(_sexoFiltro)) {
      _sexoFiltro = 'Todos';
    }
  }

  double _limitarDistancia(double valor) {
    if (valor < 1) return 1;
    if (valor > 500) return 500;
    return valor;
  }

  Future<void> _guardarConfiguracionFiltros() async {
    await _storage.write(
      key: 'discover_distancia_max_km',
      value: _distanciaMaxKm.toStringAsFixed(0),
    );

    await _storage.write(
      key: 'discover_edad_min',
      value: _edadMin.toString(),
    );

    await _storage.write(
      key: 'discover_edad_max',
      value: _edadMax.toString(),
    );

    await _storage.write(
      key: 'discover_sexo',
      value: _sexoFiltro,
    );
  }

  Future<Position> _obtenerUbicacionActual() async {
    final bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();

    if (!servicioHabilitado) {
      throw Exception('Activa la ubicación del dispositivo o navegador para usar Discover.');
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied) {
      throw Exception('Permiso de ubicación rechazado.');
    }

    if (permiso == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación bloqueado. Habilítalo desde el navegador o sistema.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _sincronizarUbicacionParaDiscover({
    required String token,
    required int userId,
  }) async {
    final Position posicion = await _obtenerUbicacionActual();

    _miLatitudActual = posicion.latitude;
    _miLongitudActual = posicion.longitude;

    final bool actualizado = await _apiService.actualizarPerfilUsuario(
      token: token,
      userId: userId,
      datosActualizacion: {
        'latitud': posicion.latitude,
        'longitud': posicion.longitude,
      },
    );

    if (!actualizado) {
      throw Exception('No se pudo actualizar tu ubicación antes de cargar Discover.');
    }
  }

  Future<Set<int>> _obtenerUsuariosBloqueados(int usuarioId) async {
    try {
      final data = await _apiService.listarBloqueosPorUsuario(
        usuarioId: usuarioId,
      );

      final bloqueados = <int>{};

      for (final item in data) {
        if (item is! Map) continue;

        final idBloqueado = int.tryParse(
          item['idUsuarioBloqueado']?.toString() ?? '',
        );

        if (idBloqueado != null) {
          bloqueados.add(idBloqueado);
        }
      }

      return bloqueados;
    } catch (_) {
      return {};
    }
  }

  Future<void> _cargarDeportistas() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _indiceActual = 0;
      _isSending = false;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final userIdString = await _storage.read(key: 'user_id');

      if (token == null || token.isEmpty || userIdString == null) {
        throw Exception('No existe sesión activa. Vuelve a iniciar sesión.');
      }

      final userId = int.tryParse(userIdString);

      if (userId == null) {
        throw Exception('El ID del usuario no es válido.');
      }

      await _sincronizarUbicacionParaDiscover(
        token: token,
        userId: userId,
      );

      final usuariosRaw = await _apiService.descubrirUsuarios(
        excludeId: userId,
        token: token,
        distanciaMinKm: 0,
        distanciaMaxKm: _distanciaMaxKm,
        edadMin: _edadMin,
        edadMax: _edadMax,
        sexo: _sexoFiltro,
      );

      final usuariosInteractuados = await _apiService.obtenerUsuariosInteractuados(
        usuarioId: userId,
      );

      final usuariosBloqueados = await _obtenerUsuariosBloqueados(userId);

      final usuariosInteractuadosSet = usuariosInteractuados.toSet();

      final deportistas = usuariosRaw
          .whereType<Map<String, dynamic>>()
          .map(
            (json) => Deportista.fromJson(
              json,
              miLatitud: _miLatitudActual,
              miLongitud: _miLongitudActual,
            ),
          )
          .where((d) => d.id != 0)
          .where((d) => !usuariosInteractuadosSet.contains(d.id))
          .where((d) => !usuariosBloqueados.contains(d.id))
          .toList();

      if (!mounted) return;

      setState(() {
        _miUsuarioId = userId;
        _deportistas = deportistas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _limpiarError(e);
        _isLoading = false;
        _isSending = false;
      });
    }
  }

  Future<void> _abrirConfiguracionFiltros() async {
    double distanciaTemporal = _distanciaMaxKm;

    RangeValues edadTemporal = RangeValues(
      _edadMin.toDouble(),
      _edadMax.toDouble(),
    );

    String sexoTemporal = _sexoFiltro;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: const Text(
                'Filtros de búsqueda',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distancia máxima',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hasta ${distanciaTemporal.round()} km',
                      style: const TextStyle(
                        color: AppTheme.primarySoft,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Slider(
                      value: distanciaTemporal,
                      min: 1,
                      max: 500,
                      divisions: 499,
                      label: '${distanciaTemporal.round()} km',
                      onChanged: (nuevoValor) {
                        setDialogState(() {
                          distanciaTemporal = nuevoValor.roundToDouble();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Base: hasta 1 km. Puedes ampliar la búsqueda hasta 500 km.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Edad',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${edadTemporal.start.round()} a ${edadTemporal.end.round()} años',
                      style: const TextStyle(
                        color: AppTheme.primarySoft,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    RangeSlider(
                      values: edadTemporal,
                      min: 18,
                      max: 100,
                      divisions: 82,
                      labels: RangeLabels(
                        '${edadTemporal.start.round()}',
                        '${edadTemporal.end.round()}',
                      ),
                      onChanged: (nuevoValor) {
                        setDialogState(() {
                          edadTemporal = RangeValues(
                            nuevoValor.start.roundToDouble(),
                            nuevoValor.end.roundToDouble(),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Sexo',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: sexoTemporal,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Todos',
                          child: Text('Todos'),
                        ),
                        DropdownMenuItem(
                          value: 'Masculino',
                          child: Text('Masculino'),
                        ),
                        DropdownMenuItem(
                          value: 'Femenino',
                          child: Text('Femenino'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor == null) return;

                        setDialogState(() {
                          sexoTemporal = valor;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'El deporte se filtra automáticamente según tu perfil.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _distanciaMaxKm = distanciaTemporal;
                      _edadMin = edadTemporal.start.round();
                      _edadMax = edadTemporal.end.round();
                      _sexoFiltro = sexoTemporal;
                    });

                    await _guardarConfiguracionFiltros();

                    if (!mounted) return;

                    Navigator.pop(dialogContext);

                    await _cargarDeportistas();
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _bloquearUsuarioActual(Deportista deportista) async {
    if (_miUsuarioId == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text(
            'Bloquear usuario',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'No volverás a ver a ${deportista.nombreCompleto} en Discover.',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Bloquear'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final ok = await _apiService.bloquearUsuario(
      idUsuarioOrigen: _miUsuarioId!,
      idUsuarioBloqueado: deportista.id,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${deportista.nombreCompleto} fue bloqueado.'),
        ),
      );

      _pasarAlSiguienteUsuario();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo bloquear el usuario.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _reportarUsuarioActual(
    Deportista deportista, {
    required bool bloquearTambien,
  }) async {
    if (_miUsuarioId == null) return;

    final descripcionController = TextEditingController();

    final descripcion = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text(
            'Reportar usuario',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'El reporte será enviado a administración para revisión.',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descripcionController,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Motivo del reporte',
                  hintText: 'Describe brevemente qué ocurrió',
                  prefixIcon: Icon(Icons.report_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final texto = descripcionController.text.trim();

                if (texto.isEmpty) {
                  Navigator.pop(dialogContext, 'Reporte desde Discovery');
                  return;
                }

                Navigator.pop(dialogContext, texto);
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    descripcionController.dispose();

    if (descripcion == null) return;

    final reporteOk = await _apiService.reportarUsuario(
      idUsuarioDenunciante: _miUsuarioId!,
      idUsuarioDenunciado: deportista.id,
      motivo: 'Reporte desde Discovery',
      descripcion: descripcion,
    );

    bool bloqueoOk = true;

    if (bloquearTambien) {
      bloqueoOk = await _apiService.bloquearUsuario(
        idUsuarioOrigen: _miUsuarioId!,
        idUsuarioBloqueado: deportista.id,
      );
    }

    if (!mounted) return;

    if (reporteOk && bloqueoOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bloquearTambien
                ? 'Reporte enviado y usuario bloqueado.'
                : 'Reporte enviado a administración.',
          ),
        ),
      );

      _pasarAlSiguienteUsuario();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo completar la acción.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _pasarAlSiguienteUsuario() {
    if (!mounted) return;

    setState(() {
      _indiceActual++;
      _isSending = false;
    });
  }

  Future<void> _abrirMenuUsuario(Deportista deportista) async {
    final accion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (bottomContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.block, color: AppTheme.danger),
                  title: const Text(
                    'Bloquear',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  onTap: () => Navigator.pop(bottomContext, 'bloquear'),
                ),
                ListTile(
                  leading: const Icon(Icons.report_outlined, color: AppTheme.primarySoft),
                  title: const Text(
                    'Reportar',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  onTap: () => Navigator.pop(bottomContext, 'reportar'),
                ),
                ListTile(
                  leading: const Icon(Icons.gpp_bad_outlined, color: AppTheme.danger),
                  title: const Text(
                    'Reportar y bloquear',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  onTap: () => Navigator.pop(bottomContext, 'reportar_bloquear'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (accion == 'bloquear') {
      await _bloquearUsuarioActual(deportista);
    }

    if (accion == 'reportar') {
      await _reportarUsuarioActual(
        deportista,
        bloquearTambien: false,
      );
    }

    if (accion == 'reportar_bloquear') {
      await _reportarUsuarioActual(
        deportista,
        bloquearTambien: true,
      );
    }
  }

  Future<void> _enviarInteraccion(String tipo) async {
    if (_miUsuarioId == null) return;
    if (_isSending) return;
    if (_indiceActual >= _deportistas.length) return;

    final deportista = _deportistas[_indiceActual];

    setState(() {
      _isSending = true;
    });

    try {
      final hayMatch = await _apiService.enviarInteraccion(
        usuarioOrigenId: _miUsuarioId!,
        usuarioDestinoId: deportista.id,
        tipo: tipo,
      );

      if (!mounted) return;

      if (hayMatch) {
        await _mostrarMatch(deportista);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tipo == tipoLike
                  ? 'Like enviado a ${deportista.nombreCompleto}'
                  : 'Dislike enviado a ${deportista.nombreCompleto}',
            ),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _indiceActual++;
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;

      final mensaje = _limpiarError(e).toLowerCase();

      if (mensaje.contains('ya ha interactuado') ||
          mensaje.contains('conflict') ||
          mensaje.contains('409')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya habías interactuado con este usuario.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $mensaje')),
        );
      }

      setState(() {
        _isSending = false;
      });

      await _cargarDeportistas();
    }
  }

  String _limpiarError(Object e) {
    final texto = e.toString();
    return texto.length <= 180 ? texto : '${texto.substring(0, 180)}...';
  }

  Future<void> _mostrarMatch(Deportista d) async {
    await showGeneralDialog(
      context: context,
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(anim1),
          child: AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(color: AppTheme.border),
            ),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        '¡HAY MATCH DEPORTIVO!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primarySoft,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        '${d.nombreCompleto} quiere jugar contigo.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'RabbitMQ debería crear una sala de chat automáticamente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '¡Vamos a jugar!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(String texto, IconData icono) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppTheme.primarySoft.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: AppTheme.primarySoft),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjeta(Deportista deportista) {
    return Column(
      children: [
        Expanded(
          child: Dismissible(
            key: ValueKey(deportista.id),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              final tipo = direction == DismissDirection.startToEnd
                  ? tipoLike
                  : tipoDislike;

              _enviarInteraccion(tipo);
            },
            background: Container(),
            secondaryBackground: Container(),
            child: Stack(
              children: [
                Card(
                  color: AppTheme.surface,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(
                      color: AppTheme.border,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                          child: Image.network(
                            deportista.fotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.surfaceAlt,
                              child: const Icon(
                                Icons.person,
                                size: 80,
                                color: AppTheme.primarySoft,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deportista.edad > 0
                                    ? '${deportista.nombreCompleto}, ${deportista.edad}'
                                    : deportista.nombreCompleto,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@${deportista.username}',
                                style: const TextStyle(
                                  color: AppTheme.primarySoft,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                deportista.distanciaTexto,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                deportista.descripcion,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _infoChip(
                                    deportista.deportePrincipal,
                                    Icons.sports_soccer,
                                  ),
                                  _infoChip(
                                    deportista.sexo,
                                    Icons.person_search,
                                  ),
                                  _infoChip(
                                    deportista.posicion,
                                    Icons.place,
                                  ),
                                  _infoChip(
                                    deportista.altura,
                                    Icons.height,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 30,
                  right: 30,
                  child: IconButton(
                    onPressed: () => _abrirMenuUsuario(deportista),
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppTheme.textPrimary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.background.withOpacity(0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btnAccion(
            Icons.close,
            AppTheme.danger,
            () => _enviarInteraccion(tipoDislike),
          ),
          _btnAccion(
            Icons.sports_soccer,
            AppTheme.success,
            () => _enviarInteraccion(tipoLike),
          ),
        ],
      ),
    );
  }

  Widget _btnAccion(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: AppTheme.surface,
        onPressed: _isSending ? null : onPressed,
        child: _isSending
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Icon(icon, size: 32, color: color),
      ),
    );
  }

  Widget _estadoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports,
              size: 80,
              color: AppTheme.primarySoft,
            ),
            const SizedBox(height: 14),
            const Text(
              'No hay más deportistas cerca',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Filtros actuales: hasta ${_distanciaMaxKm.round()} km · Edad $_edadMin a $_edadMax · Sexo $_sexoFiltro.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _cargarDeportistas,
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 70,
              color: AppTheme.danger,
            ),
            const SizedBox(height: 14),
            const Text(
              'Error al cargar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _cargarDeportistas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget contenido;

    if (_isLoading) {
      contenido = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      contenido = _estadoError();
    } else if (_deportistas.isEmpty || _indiceActual >= _deportistas.length) {
      contenido = _estadoVacio();
    } else {
      contenido = _construirTarjeta(_deportistas[_indiceActual]);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Descubrir',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(
            onPressed: _abrirConfiguracionFiltros,
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            onPressed: _cargarDeportistas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: contenido,
    );
  }
}