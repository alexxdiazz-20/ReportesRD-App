import 'package:flutter/material.dart';
import '../models/reporte_model.dart';
import '../theme/app_theme.dart';

/// ⚠️ PANTALLA CON DATOS DE PRUEBA (MOCK) ⚠️
///
/// Dos pestañas:
/// - "Mis Reportes": lo que este dispositivo ha reportado. Cuando exista
///   la conexión a Supabase, se debe filtrar con:
///     .eq('creado_por', await DispositivoService.obtenerIdDispositivo())
/// - "Reportes Recientes": todos los reportes de todos los usuarios,
///   sin filtrar, ordenados del más reciente al más viejo.
///   TODO(Supabase): además de traerlos todos, se recomienda que el
///   backend descarte (o deje de mostrar) reportes con más de 24-48h
///   de creados, para que la lista no crezca indefinidamente.
///
/// Todo lo que se ve aquí abajo (_reportesDePrueba) es inventado
/// únicamente para revisar el diseño. No existe en ninguna base de datos.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Por defecto, "Reportes Recientes" solo muestra lo de las últimas 48h.
  // Si el usuario toca "Ver reportes anteriores", se quita ese límite y
  // se muestra el historial completo de la comunidad.
  bool _mostrarTodoElHistorial = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Reportes de ejemplo para la pestaña "Reportes Recientes" (de todos).
  List<_ReporteConZona> _reportesRecientesDePrueba() {
    final ahora = DateTime.now();
    return [
      _ReporteConZona(
        zona: 'Av. Winston Churchill, Santo Domingo',
        reporte: ReporteModel(
          tipo: TipoIncidente.accidente,
          descripcion: 'Choque entre dos vehículos en la intersección, tránsito '
              'parcialmente bloqueado. Hay una grúa en camino, precaución al pasar.',
          latitud: 18.4861,
          longitud: -69.9312,
          urgencia: NivelUrgencia.alta,
          creadoPor: 'dispositivo_prueba_1',
          fechaCreacion: ahora.subtract(const Duration(minutes: 20)),
        ),
      ),
      _ReporteConZona(
        zona: 'Autopista Duarte, km 12',
        reporte: ReporteModel(
          tipo: TipoIncidente.problemaVial,
          descripcion: 'Bache grande en el carril derecho.',
          latitud: 18.4700,
          longitud: -69.9400,
          urgencia: NivelUrgencia.media,
          creadoPor: 'dispositivo_prueba_2',
          fechaCreacion: ahora.subtract(const Duration(hours: 3)),
        ),
      ),
      _ReporteConZona(
        zona: 'Calle El Conde',
        reporte: ReporteModel(
          tipo: TipoIncidente.otro,
          descripcion: 'Semáforo intermitente desde ayer en la tarde.',
          latitud: 18.4920,
          longitud: -69.9200,
          urgencia: NivelUrgencia.baja,
          creadoPor: 'dispositivo_prueba_3',
          fechaCreacion: ahora.subtract(const Duration(hours: 18)),
        ),
      ),
    ];
  }

  /// Reportes de ejemplo para la pestaña "Mis Reportes" (solo este dispositivo).
  List<_ReporteConZona> _misReportesDePrueba() {
    final ahora = DateTime.now();
    return [
      _ReporteConZona(
        zona: 'Av. 27 de Febrero',
        reporte: ReporteModel(
          tipo: TipoIncidente.problemaVial,
          descripcion: 'Alcantarilla sin tapa, peligro para motociclistas.',
          latitud: 18.4750,
          longitud: -69.9350,
          urgencia: NivelUrgencia.alta,
          creadoPor: 'este_dispositivo',
          fechaCreacion: ahora.subtract(const Duration(days: 1, hours: 4)),
        ),
      ),
    ];
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListaConAvisos(
            reportes: _misReportesDePrueba(),
            mensajeVacioReal: 'Aún no has creado reportes reales.',
          ),
          _buildListaConAvisos(
            // Si el usuario no pidió ver todo, se filtra a las últimas
            // 48h. Los reportes viejos no se borran de la base de datos,
            // solo se ocultan por defecto para mantener la lista relevante.
            reportes: _mostrarTodoElHistorial
                ? _reportesRecientesDePrueba()
                : _reportesRecientesDePrueba()
                    .where((item) => DateTime.now()
                        .difference(item.reporte.fechaCreacion)
                        .inHours < 48)
                    .toList(),
            mensajeVacioReal:
                'Aún no hay reportes reales de la comunidad. Se muestran '
                'los de las últimas 48 horas una vez haya datos.',
            mostrarBotonVerTodo: true,
          ),
        ],
      ),
    );
  }

  Widget _buildListaConAvisos({
    required List<_ReporteConZona> reportes,
    required String mensajeVacioReal,
    bool mostrarBotonVerTodo = false,
  }) {
    return Column(
      children: [
        _buildBannerDatosDePrueba(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: reportes.length + (mostrarBotonVerTodo ? 1 : 0),
            itemBuilder: (context, index) {
              if (mostrarBotonVerTodo && index == reportes.length) {
                // Último elemento de la lista: el botón para alternar
                // entre "solo lo reciente" y "todo el historial".
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _mostrarTodoElHistorial = !_mostrarTodoElHistorial;
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
              return _BannerReporte(item: reportes[index]);
            },
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
            mensajeVacioReal,
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

  Widget _buildBannerDatosDePrueba() {
    return Container(
      width: double.infinity,
      color: AppColors.urgenciaMedia.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.urgenciaMedia),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Datos de ejemplo para revisar el diseño. No están guardados '
              'en ningún lado.',
              style: TextStyle(fontSize: 12, color: AppColors.textoPrincipal),
            ),
          ),
        ],
      ),
    );
  }
}

/// Combina un reporte con el nombre de zona/dirección aproximada, solo
/// para mostrarlo en pantalla. El modelo real (ReporteModel) no incluye
/// este campo — se calcularía a futuro con geocodificación inversa a
/// partir de lat/lng (TODO: evaluar el paquete 'geocoding' cuando haya
/// datos reales).
class _ReporteConZona {
  final ReporteModel reporte;
  final String zona;

  _ReporteConZona({required this.reporte, required this.zona});
}

/// Tarjeta tipo "banner de notificación": ícono según tipo/urgencia,
/// zona, descripción truncada con opción de "ver más", y un botón de
/// mapa que lleva a ver el punto exacto donde ocurrió.
class _BannerReporte extends StatefulWidget {
  final _ReporteConZona item;

  const _BannerReporte({required this.item});

  @override
  State<_BannerReporte> createState() => _BannerReporteState();
}

class _BannerReporteState extends State<_BannerReporte> {
  bool _expandido = false;

  String _nombreTipo(TipoIncidente tipo) {
    switch (tipo) {
      case TipoIncidente.accidente:
        return 'Accidente de tránsito';
      case TipoIncidente.problemaVial:
        return 'Problema vial';
      case TipoIncidente.otro:
        return 'Otro incidente';
    }
  }

  IconData _iconoTipo(TipoIncidente tipo) {
    switch (tipo) {
      case TipoIncidente.accidente:
        return Icons.car_crash;
      case TipoIncidente.problemaVial:
        return Icons.warning_amber_rounded;
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
        'latitud': widget.item.reporte.latitud,
        'longitud': widget.item.reporte.longitud,
        'titulo': _nombreTipo(widget.item.reporte.tipo),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reporte = widget.item.reporte;
    final colorUrgencia = AppTheme.colorPorUrgencia(reporte.urgencia.name);
    final descripcion = reporte.descripcion;

    // Se considera "largo" a partir de ~80 caracteres para decidir si
    // mostrar el botón de "ver más" (aprox. lo que no cabe en 2 líneas).
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
                        _nombreTipo(reporte.tipo),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Text(
                      _tiempoTranscurrido(reporte.fechaCreacion),
                      style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.item.zona,
                  style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 6),
                Text(
                  descripcionMostrada,
                  style: const TextStyle(fontSize: 13, color: AppColors.textoPrincipal),
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