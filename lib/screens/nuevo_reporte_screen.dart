import 'package:flutter/material.dart';

/// PLACEHOLDER — Esta pantalla la construye el compañero encargado de
/// "Creación de Reportes". Aquí solo se deja la conexión funcionando:
/// recibe la ubicación que el Home ya capturó por GPS, para que el
/// compañero no tenga que volver a pedir permisos ni leer el GPS.
///
/// El compañero debe reemplazar el body de este widget con su formulario
/// (tipo de incidente, descripción, urgencia, fotos), usando 'latitud' y
/// 'longitud' como el punto de partida del mapa/ubicación del reporte,
/// permitiendo que el usuario la ajuste si el GPS no acertó exacto.
class NuevoReporteScreen extends StatelessWidget {
  const NuevoReporteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Los argumentos vienen del Navigator.pushNamed() en HomeScreen,
    // como un Map con 'latitud' y 'longitud'.
    final argumentos = ModalRoute.of(context)!.settings.arguments as Map;
    final double latitud = argumentos['latitud'];
    final double longitud = argumentos['longitud'];

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Reporte')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Pantalla en construcción',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ubicación recibida del Home:\n'
                'Lat: ${latitud.toStringAsFixed(5)}, Lng: ${longitud.toStringAsFixed(5)}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}