import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/supabase_config.dart';
import '../models/reporte_model.dart';

/// Capa de acceso a Supabase: guardar reportes, subir fotos y consultarlos.
///
/// No hay login: el rol anon (público) puede insertar y leer gracias a las
/// políticas RLS. "Mis Reportes" se resuelve filtrando por 'creado_por'
/// (el UUID anónimo del dispositivo), no por una cuenta de usuario.
class ReporteService {
  static const String _tabla = 'reportes';

  static SupabaseClient get _cliente => Supabase.instance.client;

  /// Guarda un reporte en la BD. Los bytes de las fotos se suben primero al
  /// bucket privado y en la fila se guardan los paths (text[]), porque las
  /// URLs firmadas expiran y no sirven para persistir.
  ///
  /// Los bytes llegan YA leídos desde la pantalla de creación: en web no se
  /// puede re-leer la URL blob: que devuelve image_picker pasado un rato
  /// (puede estar revocada), así que se capturan en el momento de elegir.
  static Future<void> guardarReporte(
    ReporteModel reporte,
    List<Uint8List> fotosBytes,
  ) async {
    final List<String> pathsFotos = [];
    for (final bytes in fotosBytes) {
      pathsFotos.add(await _subirFoto(bytes));
    }

    await _cliente.from(_tabla).insert({
      'id': reporte.id,
      'tipo': reporte.tipo.name,
      'descripcion': reporte.descripcion,
      'latitud': reporte.latitud,
      'longitud': reporte.longitud,
      'urgencia': reporte.urgencia.name,
      'fecha_creacion': reporte.fechaCreacion.toIso8601String(),
      'creado_por': reporte.creadoPor,
      'rutas_fotos': pathsFotos,
    });
  }

  /// Todos los reportes de la comunidad, del más reciente al más viejo.
  /// Es lo que pinta el mapa del Home.
  static Future<List<ReporteModel>> obtenerReportes() async {
    final data = await _cliente
        .from(_tabla)
        .select()
        .order('fecha_creacion', ascending: false);
    return data.map(ReporteModel.fromMap).toList();
  }

  /// Solo los reportes creados desde este dispositivo (Historial personal).
  static Future<List<ReporteModel>> obtenerMisReportes(
    String idDispositivo,
  ) async {
    final data = await _cliente
        .from(_tabla)
        .select()
        .eq('creado_por', idDispositivo)
        .order('fecha_creacion', ascending: false);
    return data.map(ReporteModel.fromMap).toList();
  }

  /// Firma una URL temporal para poder ver una foto del bucket privado.
  /// Devuelve null si falla (foto borrada, red, etc.).
  static Future<String?> urlFirmadaFoto(
    String path, {
    int segundosValidez = 3600,
  }) async {
    try {
      return await _cliente.storage.from(SupabaseConfig.bucketFotos)
          .createSignedUrl(path, segundosValidez);
    } catch (_) {
      return null;
    }
  }

  static Future<String> _subirFoto(Uint8List bytes) async {
    final nombre = 'foto_${DateTime.now().millisecondsSinceEpoch}_'
        '${const Uuid().v4().substring(0, 8)}.jpg';

    // uploadBinary recibe Uint8List y es el método que funciona en web
    // (upload() espera un File de dart:io, que en web no existe y revienta).
    await _cliente.storage
        .from(SupabaseConfig.bucketFotos)
        .uploadBinary(nombre, bytes);
    return nombre;
  }
}
