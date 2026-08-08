import 'package:flutter/material.dart';
import '../models/reporte_model.dart';
import '../services/reporte_service.dart';
import '../theme/app_theme.dart';

/// Muestra la información completa de un reporte: tipo (con emoji),
/// urgencia, descripción, fecha y las fotos que se subieron.
///
/// Se llega aquí tocando un marker en el mapa del Home. Recibe el
/// [ReporteModel] como argumento de navegación.
class DetalleReporteScreen extends StatelessWidget {
  const DetalleReporteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reporte =
        ModalRoute.of(context)!.settings.arguments as ReporteModel;
    final colorUrgencia = AppTheme.colorPorUrgencia(reporte.urgencia.name);

    return Scaffold(
      appBar: AppBar(title: Text(reporte.tipo.etiqueta)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEncabezado(reporte, colorUrgencia),
            const SizedBox(height: 20),
            _buildSeccion(context, 'Descripción'),
            _buildTarjetaDescripcion(reporte.descripcion),
            const SizedBox(height: 20),
            if (reporte.rutasFotos.isNotEmpty) ...[
              _buildSeccion(context, 'Fotos'),
              _buildGaleriaFotos(reporte.rutasFotos),
              const SizedBox(height: 20),
            ],
            _buildBotonVerMapa(context, reporte),
          ],
        ),
      ),
    );
  }

  /// Emoji del tipo + etiqueta, urgencia con su color, fecha y lugar.
  Widget _buildEncabezado(ReporteModel reporte, Color colorUrgencia) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(reporte.tipo.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(
            reporte.tipo.etiqueta,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: colorUrgencia.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Urgencia ${reporte.urgencia.etiqueta}',
              style: TextStyle(
                color: colorUrgencia,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _fechaFormateada(reporte.fechaCreacion),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${reporte.latitud.toStringAsFixed(4)}, '
            '${reporte.longitud.toStringAsFixed(4)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion(BuildContext context, String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildTarjetaDescripcion(String descripcion) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        descripcion,
        style: const TextStyle(fontSize: 14, color: AppColors.textoPrincipal),
      ),
    );
  }

  /// Galería horizontal de fotos. Cada una carga su URL firmada; si la
  /// firma falla o expiró, se muestra un placeholder.
  Widget _buildGaleriaFotos(List<String> paths) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, indice) {
          return FutureBuilder<String?>(
            future: ReporteService.urlFirmadaFoto(paths[indice]),
            builder: (context, snapshot) {
              final url = snapshot.data;
              if (url == null) {
                return const SizedBox(
                  width: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  width: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _FotoNoDisponible(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBotonVerMapa(BuildContext context, ReporteModel reporte) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/ver-reporte-mapa', arguments: {
            'latitud': reporte.latitud,
            'longitud': reporte.longitud,
            'titulo': reporte.tipo.etiqueta,
          });
        },
        icon: const Icon(Icons.map_outlined),
        label: const Text('Ver en el mapa'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primario,
          side: const BorderSide(color: AppColors.primario),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  String _fechaFormateada(DateTime fecha) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year} '
        '· ${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
  }
}

class _FotoNoDisponible extends StatelessWidget {
  const _FotoNoDisponible();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined,
              color: AppColors.textoSecundario, size: 32),
          SizedBox(height: 6),
          Text(
            'Foto no disponible',
            style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }
}
