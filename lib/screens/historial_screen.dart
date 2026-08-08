import 'package:flutter/material.dart';
import '../models/reporte_model.dart';
import '../services/dispositivo_service.dart';
import '../services/reporte_service.dart';
import '../theme/app_theme.dart';

/// Historial con dos pestañas:
/// - "Mis Reportes": lo que este dispositivo ha reportado, filtrado por
///   'creado_por' (el UUID anónimo del dispositivo, sin login).
/// - "Reportes Recientes": todos los reportes de la comunidad, ordenados
///   del más reciente al más viejo. Por defecto solo muestra los últimos
///   48h; el botón "Ver reportes anteriores" quita ese límite.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<ReporteModel> _misReportes = [];
  List<ReporteModel> _recientes = [];
  bool _cargando = true;

  // Por defecto, "Reportes Recientes" solo muestra lo de las últimas 48h.
  // Al tocar "Ver reportes anteriores" se quita ese límite.
  bool _mostrarTodoElHistorial = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarReportes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Carga "Mis Reportes" (filtrado por el ID del dispositivo) y todos los
  /// recientes de la comunidad desde Supabase.
  Future<void> _cargarReportes() async {
    try {
      final idDispositivo = await DispositivoService.obtenerIdDispositivo();
      final misReportes = await ReporteService.obtenerMisReportes(idDispositivo);
      final recientes = await ReporteService.obtenerReportes();
      if (!mounted) return;
      setState(() {
        _misReportes = misReportes;
        _recientes = recientes;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  /// Recarga los reportes sin la pantalla de carga completa (se usa en el
  /// gesto de tirar hacia abajo para refrescar).
  Future<void> _refrescar() async {
    try {
      final idDispositivo = await DispositivoService.obtenerIdDispositivo();
      final misReportes =
          await ReporteService.obtenerMisReportes(idDispositivo);
      final recientes = await ReporteService.obtenerReportes();
      if (!mounted) return;
      setState(() {
        _misReportes = misReportes;
        _recientes = recientes;
      });
    } catch (_) {
      // Si la recarga falla, se deja lo que ya había en pantalla.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Reportes'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Mis Reportes'),
            Tab(text: 'Reportes Recientes'),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLista(
                  reportes: _misReportes,
                  mensajeVacio:
                      'Aún no has creado reportes desde este dispositivo o '
                      'navegador.\n\nLos reportes que hayas creado desde otra '
                      'computadora, teléfono u otro navegador aparecen en '
                      '"Reportes Recientes", pero no aquí.',
                  notaPie:
                      'Solo se muestran los reportes creados desde este dispositivo.',
                ),
                _buildLista(
                  reportes: _mostrarTodoElHistorial
                      ? _recientes
                      : _recientes
                          .where((reporte) => DateTime.now()
                              .difference(reporte.fechaCreacion)
                              .inHours < 48)
                          .toList(),
                  mensajeVacio:
                      'Aún no hay reportes de la comunidad. Se muestran los '
                      'de las últimas 48 horas una vez haya datos.',
                  mostrarBotonVerTodo: true,
                ),
              ],
            ),
    );
  }

  Widget _buildLista({
    required List<ReporteModel> reportes,
    required String mensajeVacio,
    String? notaPie,
    bool mostrarBotonVerTodo = false,
  }) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refrescar,
            child: reportes.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 360,
                        child: _buildVacio(mensajeVacio),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: reportes.length + (mostrarBotonVerTodo ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (mostrarBotonVerTodo && index == reportes.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _mostrarTodoElHistorial =
                                      !_mostrarTodoElHistorial;
                                });
                              },
                              icon: Icon(
                                _mostrarTodoElHistorial
                                    ? Icons.visibility_off_outlined
                                    : Icons.history,
                              ),
                              label: Text(
                                _mostrarTodoElHistorial
                                    ? 'Ver solo lo reciente (48h)'
                                    : 'Ver reportes anteriores',
                              ),
                            ),
                          ),
                        );
                      }
                      return _BannerReporte(reporte: reportes[index]);
                    },
                  ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.fondo,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Text(
            notaPie ?? mensajeVacio,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textoSecundario,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVacio(String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 48, color: AppColors.textoSecundario),
            const SizedBox(height: 12),
            const Text(
              'Nada que mostrar todavía',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta tipo "banner de notificación": icono según tipo/urgencia,
/// zona aproximada, descripción truncada con opción de "ver más", y un
/// botón de mapa que lleva a ver el punto exacto donde ocurrió.
class _BannerReporte extends StatefulWidget {
  final ReporteModel reporte;

  const _BannerReporte({required this.reporte});

  @override
  State<_BannerReporte> createState() => _BannerReporteState();
}

class _BannerReporteState extends State<_BannerReporte> {
  bool _expandido = false;

  /// Mientras no exista geocodificación inversa, mostramos las coordenadas
  /// como referencia del lugar.
  String get _zona {
    return '${widget.reporte.latitud.toStringAsFixed(4)}, '
        '${widget.reporte.longitud.toStringAsFixed(4)}';
  }

  IconData _iconoTipo(TipoIncidente tipo) {
    switch (tipo) {
      case TipoIncidente.accidente:
        return Icons.car_crash;
      case TipoIncidente.problemaVial:
        return Icons.warning_amber_rounded;
      case TipoIncidente.inundacion:
        return Icons.waves;
      case TipoIncidente.otro:
        return Icons.report_problem_outlined;
    }
  }

  /// Convierte la fecha a un texto corto tipo "hace 20 min", "hace 3 h".
  String _tiempoTranscurrido(DateTime fecha) {
    final diferencia = DateTime.now().difference(fecha);
    if (diferencia.inMinutes < 60) return 'hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'hace ${diferencia.inHours} h';
    return 'hace ${diferencia.inDays} d';
  }

  void _verEnMapa(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/ver-reporte-mapa',
      arguments: {
        'latitud': widget.reporte.latitud,
        'longitud': widget.reporte.longitud,
        'titulo': widget.reporte.tipo.etiqueta,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reporte = widget.reporte;
    final colorUrgencia = AppTheme.colorPorUrgencia(reporte.urgencia.name);
    final descripcion = reporte.descripcion;

    // Se considera "largo" a partir de ~80 caracteres para decidir si
    // mostrar el botón de "ver más".
    final esLargo = descripcion.length > 80;
    final descripcionMostrada =
        (!_expandido && esLargo) ? '${descripcion.substring(0, 80)}...' : descripcion;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: colorUrgencia, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorUrgencia.withValues(alpha: 0.15),
            child: Icon(_iconoTipo(reporte.tipo), color: colorUrgencia, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reporte.tipo.etiqueta,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Text(
                      _tiempoTranscurrido(reporte.fechaCreacion),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textoSecundario),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _zona,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 6),
                Text(
                  descripcionMostrada,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textoPrincipal),
                ),
                if (esLargo)
                  GestureDetector(
                    onTap: () => setState(() => _expandido = !_expandido),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _expandido ? 'Ver menos' : 'Ver más',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primario,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _verEnMapa(context),
            icon: const Icon(Icons.map_outlined),
            color: AppColors.primario,
            tooltip: 'Ver en el mapa',
          ),
        ],
      ),
    );
  }
}