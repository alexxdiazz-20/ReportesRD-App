import 'package:uuid/uuid.dart';

/// Tipos de incidente que el usuario puede reportar
enum TipoIncidente { accidente, problemaVial, otro }

/// Nivel de urgencia del reporte
enum NivelUrgencia { baja, media, alta }

class ReporteModel {
  final String id;
  final TipoIncidente tipo;
  final String descripcion;
  final double latitud;
  final double longitud;

  // Lista de rutas de fotos: puede venir vacía (sin fotos),
  // con una, o con varias.
  final List<String> rutasFotos;

  final NivelUrgencia urgencia;
  final DateTime fechaCreacion;

  ReporteModel({
    String? id,
    required this.tipo,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    List<String>? rutasFotos,
    required this.urgencia,
    DateTime? fechaCreacion,
  })  : id = id ?? const Uuid().v4(), // genera el ID único automáticamente, sin login
        rutasFotos = rutasFotos ?? const [], // si no se pasa nada, queda como lista vacía
        fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Esto es lo que el compañero de base de datos va a mandar a Supabase.
  /// Ejemplo de uso futuro:
  /// await Supabase.instance.client.from('reportes').insert(reporte.toMap());
  ///
  /// Nota para el compañero de BD: 'rutas_fotos' es un arreglo de texto.
  /// En Supabase/Postgres el tipo de columna correspondiente es text[].
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo.name,
      'descripcion': descripcion,
      'latitud': latitud,
      'longitud': longitud,
      'rutas_fotos': rutasFotos,
      'urgencia': urgencia.name,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }
}