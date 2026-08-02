import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Genera y recuerda un ID único por dispositivo, sin necesidad de login.
///
/// La primera vez que se abre la app, se genera un UUID y se guarda en el
/// almacenamiento local del teléfono (SharedPreferences). Las siguientes
/// veces que se abra la app en ese mismo dispositivo, se reutiliza el
/// mismo ID en vez de generar uno nuevo.
///
/// Este ID se usa para:
/// 1. Marcar cada reporte con "quién lo creó" (campo 'creado_por')
/// 2. Filtrar el Historial de Reportes para mostrar solo los reportes
///    hechos desde este dispositivo, sin exponer los de otros usuarios.
class DispositivoService {
  static const String _clave = 'id_dispositivo';

  /// Devuelve el ID de este dispositivo. Si es la primera vez que se
  /// llama, lo genera y lo guarda; si ya existía, devuelve el mismo
  /// de siempre.
  static Future<String> obtenerIdDispositivo() async {
    final prefs = await SharedPreferences.getInstance();

    String? idExistente = prefs.getString(_clave);
    if (idExistente != null) {
      return idExistente;
    }

    final nuevoId = const Uuid().v4();
    await prefs.setString(_clave, nuevoId);
    return nuevoId;
  }
}