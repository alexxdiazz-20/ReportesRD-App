import 'package:flutter/material.dart';
// ignore_for_file: deprecated_member_use
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/nuevo_reporte_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/ver_reporte_mapa_screen.dart';
import 'screens/detalle_reporte_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
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
      // Precarga la fuente de emoji en la web (Flutter la descarga de forma
      // perezosa: si los markers se dibujan antes de que llegue, el emoji
      // sale como un cuadro con X / tofu).
      builder: (context, child) => Stack(
        children: [
          child!,
          const Positioned(
            left: -100,
            bottom: -100,
            child: _PrecargaEmojis(),
          ),
        ],
      ),
      // Rutas nombradas: así cada pantalla se navega por su nombre en vez
      // de tener que importar el widget de destino en cada lugar donde se
      // navega. También facilita que el compañero agregue sus propias
      // rutas (ej. '/historial') sin tocar este archivo más de lo necesario.
      routes: {
        '/': (context) => const HomeScreen(),
        '/nuevo-reporte': (context) => const NuevoReporteScreen(),
        '/historial': (context) => const HistorialScreen(),
        '/ver-reporte-mapa': (context) => const VerReporteMapaScreen(),
        '/detalle-reporte': (context) => const DetalleReporteScreen(),
      },
    );
  }
}

/// Fuerza la descarga de la fuente de emoji desde el primer frame renderizado.
/// En la web Flutter 3.44+ baja la fuente de emoji en WOFF2 divididas bajo
/// demanda; si un marker pinta antes de que esté disponible, el PNG del icono
/// queda con el emoji como "cuadro con X". Este widget (invisible y fuera de
/// la vista) obliga a que la fuente se baje apenas arranca la app.
class _PrecargaEmojis extends StatelessWidget {
  const _PrecargaEmojis();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0,
      child: Text(
        '🚗⚠️🌊📍',
        style: const TextStyle(fontSize: 1),
      ),
    );
  }
}