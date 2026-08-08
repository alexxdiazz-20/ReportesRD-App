import 'package:uuid/uuid.dart';

/// Tipos de incidente que el usuario puede reportar.
/// Incluyen etiqueta en español y emoji para mostrarlos en el mapa/UI.
enum TipoIncidente {
  accidente('Accidente de tránsito', '🚗'),
  problemaVial('Problema vial', '⚠️'),
  inundacion('Inundación', '🌊'),
  otro('Otro incidente', '📍');

  final String etiqueta;
  final String emoji;

  const TipoIncidente(this.etiqueta, this.emoji);

  /// Parsea el valor guardado en la BD de vuelta al enum.
  static TipoIncidente fromTexto(String? texto) {
    return TipoIncidente.values.firstWhere(
      (tipo) => tipo.name == texto,
      orElse: () => TipoIncidente.otro,
    );
  }
}

/// Nivel de urgencia del reporte
enum NivelUrgencia {
  baja('Baja'),
  media('Media'),
  alta('Alta');

  final String etiqueta;

  const NivelUrgencia(this.etiqueta);

  /// Parsea el valor guardado en la BD de vuelta al enum.
  static NivelUrgencia fromTexto(String? texto) {
    return NivelUrgencia.values.firstWhere(
      (nivel) => nivel.name == texto,
      orElse: () => NivelUrgencia.media,
    );
  }
}

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

  /// Esto es lo que se manda a Supabase cuando el reporte se guarda.
  /// 'rutas_fotos' guarda los paths en Storage (no URLs) porque las URLs
  /// firmadas expiran; se generan al momento de verlas.
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

  /// Reconstruye un reporte desde una fila traída de Supabase.
  factory ReporteModel.fromMap(Map<String, dynamic> mapa) {
    return ReporteModel(
      id: mapa['id'] as String?,
      tipo: TipoIncidente.fromTexto(mapa['tipo'] as String?),
      descripcion: mapa['descripcion'] as String? ?? '',
      latitud: (mapa['latitud'] as num).toDouble(),
      longitud: (mapa['longitud'] as num).toDouble(),
      rutasFotos: (mapa['rutas_fotos'] as List?)?.cast<String>() ?? const [],
      urgencia: NivelUrgencia.fromTexto(mapa['urgencia'] as String?),
      fechaCreacion: DateTime.tryParse(mapa['fecha_creacion'] as String? ?? ''),
      creadoPor: mapa['creado_por'] as String? ?? '',
    );
  }
}