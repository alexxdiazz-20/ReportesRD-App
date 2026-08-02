import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Pantalla simple que muestra un mapa centrado en el punto exacto donde
/// ocurrió un reporte, con un pin marcándolo. Se llega aquí tocando el
/// ícono de mapa dentro de una tarjeta de reporte en el Historial.
class VerReporteMapaScreen extends StatelessWidget {
  const VerReporteMapaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final argumentos = ModalRoute.of(context)!.settings.arguments as Map;
    final double latitud = argumentos['latitud'];
    final double longitud = argumentos['longitud'];
    final String titulo = argumentos['titulo'] ?? 'Ubicación del reporte';

    final posicion = LatLng(latitud, longitud);

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: posicion, zoom: 17),
        markers: {
          Marker(
            markerId: const MarkerId('reporte'),
            position: posicion,
            infoWindow: InfoWindow(title: titulo),
          ),
        },
        zoomControlsEnabled: true,
        myLocationButtonEnabled: false,
      ),
    );
  }
}