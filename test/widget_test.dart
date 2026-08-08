import 'package:flutter_test/flutter_test.dart';

import 'package:reportes_rd/models/reporte_model.dart';

void main() {
  test('toMap y fromMap hacen un round-trip sin perder datos', () {
    final reporte = ReporteModel(
      id: 'abc-123',
      tipo: TipoIncidente.accidente,
      descripcion: 'Choque en la intersección',
      latitud: 18.4861,
      longitud: -69.9312,
      rutasFotos: const ['foto1.jpg', 'foto2.jpg'],
      urgencia: NivelUrgencia.alta,
      fechaCreacion: DateTime(2026, 1, 15, 10, 30),
      creadoPor: 'dispositivo_1',
    );

    final restaurado = ReporteModel.fromMap(reporte.toMap());

    expect(restaurado.id, reporte.id);
    expect(restaurado.tipo, TipoIncidente.accidente);
    expect(restaurado.descripcion, reporte.descripcion);
    expect(restaurado.latitud, reporte.latitud);
    expect(restaurado.longitud, reporte.longitud);
    expect(restaurado.rutasFotos, reporte.rutasFotos);
    expect(restaurado.urgencia, NivelUrgencia.alta);
    expect(restaurado.fechaCreacion, reporte.fechaCreacion);
    expect(restaurado.creadoPor, reporte.creadoPor);
  });

  test('fromTexto tolera valores desconocidos con un valor por defecto', () {
    expect(TipoIncidente.fromTexto('no_existe'), TipoIncidente.otro);
    expect(NivelUrgencia.fromTexto(null), NivelUrgencia.media);
  });

  test('cada tipo de incidente tiene etiqueta y emoji', () {
    expect(TipoIncidente.accidente.emoji, '🚗');
    expect(TipoIncidente.problemaVial.emoji, '⚠️');
    expect(TipoIncidente.otro.emoji, '📍');
  });
}
