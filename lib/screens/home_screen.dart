import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/reporte_model.dart';
import '../services/reporte_service.dart';
import '../theme/app_theme.dart';
import '../utils/icono_marker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  Position? _posicionActual;
  bool _cargandoUbicacion = true;

  // Reportes de la comunidad y sus markers en el mapa.
  Set<Marker> _marcadores = {};
  bool _cargandoReportes = true;

  // Santo Domingo como posición por defecto, mientras carga el GPS real
  // o si el usuario nunca da permiso de ubicación.
  static const CameraPosition _posicionInicial = CameraPosition(
    target: LatLng(18.4861, -69.9312),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
    _cargarReportes();
  }

  /// Trae todos los reportes guardados y construye un marker por cada uno,
  /// con el icono (emoji + color de urgencia) según el tipo de reporte.
  Future<void> _cargarReportes() async {
    try {
      final reportes = await ReporteService.obtenerReportes();
      // En la web la fuente de emoji se descarga bajo demanda al pintar el
      // primer emoji (ver _PrecargaEmojis en main.dart). Se espera un momento
      // para que la fuente quede lista y los PNG de los markers se dibujen
      // con el emoji real y no con el cuadro con X (tofu).
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final marcadores = <Marker>{
        for (final reporte in reportes)
          Marker(
            markerId: MarkerId(reporte.id),
            position: LatLng(reporte.latitud, reporte.longitud),
            icon: await IconoMarcador.paraReporte(reporte),
            onTap: () => _verDetalleReporte(reporte),
          ),
      };
      if (!mounted) return;
      setState(() {
        _marcadores = marcadores;
        _cargandoReportes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoReportes = false);
    }
  }

  /// Pide permiso de ubicación y obtiene la posición GPS actual del usuario.
  /// Si algo falla (GPS apagado, permiso negado), se queda con la posición
  /// por defecto en vez de romper la pantalla.
  Future<void> _obtenerUbicacion() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      setState(() => _cargandoUbicacion = false);
      return;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        setState(() => _cargandoUbicacion = false);
        return;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      setState(() => _cargandoUbicacion = false);
      return;
    }

    final posicion = await Geolocator.getCurrentPosition();
    setState(() {
      _posicionActual = posicion;
      _cargandoUbicacion = false;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(posicion.latitude, posicion.longitude)),
    );
  }

  /// Navega a la pantalla de creación de reporte (la construye el compañero),
  /// pasándole la ubicación que el Home ya capturó por GPS. Así esa pantalla
  /// no tiene que volver a pedir permisos ni leer el GPS por su cuenta.
  void _irACrearReporte() {
    final lat = _posicionActual?.latitude ?? _posicionInicial.target.latitude;
    final lng = _posicionActual?.longitude ?? _posicionInicial.target.longitude;

    Navigator.pushNamed(
      context,
      '/nuevo-reporte',
      arguments: {
        'latitud': lat,
        'longitud': lng,
      },
    );
  }

  /// Abre la pantalla de detalle con la información completa del reporte.
  void _verDetalleReporte(ReporteModel reporte) {
    Navigator.pushNamed(context, '/detalle-reporte', arguments: reporte);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildBienvenida(),
            // El mapa ocupa proporcionalmente menos espacio que la sección
            // de abajo, para que no se sienta como "pantalla de mapa" sino
            // como "pantalla de inicio con mapa de apoyo".
            Expanded(
              flex: 5,
              child: _buildMapaEnRecuadro(),
            ),
            Expanded(
              flex: 4,
              child: _buildSeccionCrearReporte(),
            ),
          ],
        ),
      ),
    );
  }

  /// Banner superior de bienvenida: nombre de la app + descripción corta
  /// de qué hace, para que el usuario entienda el propósito al entrar.
  Widget _buildBienvenida() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primario,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.report, color: Colors.white, size: 26),
                  SizedBox(width: 8),
                  Text(
                    'ReportesRD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Acceso al historial de reportes, ubicado en la esquina
              // superior derecha por ser una acción secundaria (la
              // principal es crear un reporte, abajo en la pantalla).
              // Se usa TextButton.icon (no solo un ícono) para que el
              // usuario entienda de inmediato qué hace, sin adivinar.
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/historial'),
                icon: const Icon(Icons.history, color: Colors.white, size: 20),
                label: const Text(
                  'Historial',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Reporta accidentes de tránsito y problemas viales en tu zona. '
            'Tu reporte ayuda a mantener las vías más seguras para todos.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
          ),
        ],
      ),
    );
  }

  /// El mapa ya no ocupa toda la pantalla: va dentro de una tarjeta con
  /// esquinas redondeadas y sombra, con margen alrededor, para que se
  /// sienta como un "widget dentro del Home" y no como la pantalla entera.
  Widget _buildMapaEnRecuadro() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _cargandoUbicacion || _cargandoReportes
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: _posicionActual != null
                      ? CameraPosition(
                          target: LatLng(
                            _posicionActual!.latitude,
                            _posicionActual!.longitude,
                          ),
                          zoom: 16,
                        )
                      : _posicionInicial,
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  // Bloquea el gesto de rotar/inclinar para que el usuario
                  // no pierda la orientación norte-arriba por accidente.
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  markers: _marcadores,
                ),
        ),
      ),
    );
  }

  /// Sección inferior: reemplaza al botón flotante suelto por una tarjeta
  /// más vistosa, con ícono, mensaje corto y el botón de acción principal.
  Widget _buildSeccionCrearReporte() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.acento.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_alert_rounded,
              color: AppColors.acento,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '¿Viste algo que reportar?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cuéntanos qué está pasando en tu vía. Solo toma un momento.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _irACrearReporte,
              icon: const Icon(Icons.add),
              label: const Text('Crear Nuevo Reporte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.acento,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}