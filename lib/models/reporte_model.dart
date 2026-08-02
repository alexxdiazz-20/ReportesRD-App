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
  final List<String> rutasFotos;
  final NivelUrgencia urgencia;
  final DateTime fechaCreacion;

  // ID del dispositivo que creó este reporte (ver DispositivoService).
  // Se usa para que cada usuario pueda ver "sus" reportes en el
  // Historial, sin necesidad de login. No identifica a una persona,
  // solo a un dispositivo/instalación de la app.
  final String creadoPor;

  ReporteModel({
    String? id,
    required this.tipo,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    List<String>? rutasFotos,
    required this.urgencia,
    DateTime? fechaCreacion,
    required this.creadoPor,
  })  : id = id ?? const Uuid().v4(), // genera el ID único automáticamente, sin login
        rutasFotos = rutasFotos ?? const [],
        fechaCreacion = fechaCreacion ?? DateTime.now();

  /// Esto es lo que el compañero de base de datos va a mandar a Supabase.
  /// Ejemplo de uso futuro:
  /// await Supabase.instance.client.from('reportes').insert(reporte.toMap());
  ///
  /// Nota para el compañero de BD:
  /// - 'rutas_fotos' es un arreglo de texto (text[] en Postgres)
  /// - 'creado_por' es el ID del dispositivo. La consulta del Historial
  ///   personal debe filtrar por esta columna:
  ///     .eq('creado_por', idDeEsteDispositivo)
  ///   mientras que el mapa público del Home debe traer TODOS los
  ///   reportes sin filtrar por esta columna.
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
      'creado_por': creadoPor,
    };
  }
}