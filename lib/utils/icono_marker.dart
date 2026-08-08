import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/reporte_model.dart';

/// Dibuja el icono de cada marker: un círculo blanco con anillo del color
/// de la urgencia y el emoji del tipo de reporte en el centro.
///
/// Google Maps no renderiza texto/emoji directamente en los markers, así
/// que se dibuja el emoji en un Canvas y se convierte a BitmapDescriptor.
class IconoMarcador {
  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> paraReporte(ReporteModel reporte) {
    return paraTipo(reporte.tipo, reporte.urgencia);
  }

  static Future<BitmapDescriptor> paraTipo(
    TipoIncidente tipo,
    NivelUrgencia urgencia,
  ) {
    final colorUrgencia = _colorUrgencia(urgencia);
    final clave = '${tipo.name}_${colorUrgencia.toARGB32()}';

    final existente = _cache[clave];
    if (existente != null) {
      return Future.value(existente);
    }

    return _dibujar(tipo.emoji, colorUrgencia).then((descriptor) {
      _cache[clave] = descriptor;
      return descriptor;
    });
  }

  static Future<BitmapDescriptor> _dibujar(
    String emoji,
    Color colorAnillo,
  ) async {
    const tamano = 84.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Círculo blanco con sombra suave (el fondo del marker).
    final circulo = Paint()..color = Colors.white;
    canvas.drawCircle(
      const Offset(tamano / 2, tamano / 2),
      tamano / 2 - 4,
      circulo,
    );

    // Anillo con el color de la urgencia.
    final anillo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = colorAnillo;
    canvas.drawCircle(
      const Offset(tamano / 2, tamano / 2),
      tamano / 2 - 7,
      anillo,
    );

    // El emoji centrado.
    // Se usa fontFamilyFallback con las fuentes de emoji de cada plataforma:
    // sin esto, el TextPainter puede no encontrar el glifo del emoji y lo
    // dibuja como un cuadro con X (tofu).
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(
          fontSize: 38,
          fontFamilyFallback: [
            'Noto Color Emoji',
            'Apple Color Emoji',
            'Segoe UI Emoji',
            'Noto Sans Emoji',
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (tamano - textPainter.width) / 2,
        (tamano - textPainter.height) / 2,
      ),
    );

    final imagen = await recorder
        .endRecording()
        .toImage(tamano.toInt(), tamano.toInt());
    final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  static Color _colorUrgencia(NivelUrgencia urgencia) {
    switch (urgencia) {
      case NivelUrgencia.baja:
        return const Color(0xFF4CAF50);
      case NivelUrgencia.media:
        return const Color(0xFFF5A623);
      case NivelUrgencia.alta:
        return const Color(0xFFD64545);
    }
  }
}
