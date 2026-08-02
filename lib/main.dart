import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/nuevo_reporte_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/ver_reporte_mapa_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReportesRD',
      theme: AppTheme.temaClaro,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      // Rutas nombradas: así cada pantalla se navega por su nombre en vez
      // de tener que importar el widget de destino en cada lugar donde se
      // navega. También facilita que el compañero agregue sus propias
      // rutas (ej. '/historial') sin tocar este archivo más de lo necesario.
      routes: {
        '/': (context) => const HomeScreen(),
        '/nuevo-reporte': (context) => const NuevoReporteScreen(),
        '/historial': (context) => const HistorialScreen(),
        '/ver-reporte-mapa': (context) => const VerReporteMapaScreen(),
      },
    );
  }
}