import 'package:flutter/material.dart';

/// Centraliza todos los colores y estilos de la app.
/// Si en algún momento hay que ajustar la paleta, se cambia aquí
/// y se refleja en toda la app automáticamente.
class AppColors {
  // Color principal: azul acero. Transmite confianza/institucionalidad,
  // apropiado para una app relacionada con seguridad vial.
  static const Color primario = Color(0xFF3A5A78);
  static const Color primarioOscuro = Color(0xFF25394D);
  static const Color primarioClaro = Color(0xFF6E8CAB);

  // Fondo y superficies: neutros claros para que el mapa y las fotos
  // (que tienen sus propios colores) sean lo que más resalte.
  static const Color fondo = Color(0xFFF5F7FA);
  static const Color superficie = Color(0xFFFFFFFF);

  // Texto
  static const Color textoPrincipal = Color(0xFF1F2A33);
  static const Color textoSecundario = Color(0xFF5C6B77);

  // Colores de urgencia: mismo patrón de un semáforo, para que el usuario
  // los reconozca de inmediato sin tener que leer la etiqueta.
  static const Color urgenciaBaja = Color(0xFF4CAF50); // verde
  static const Color urgenciaMedia = Color(0xFFF5A623); // ámbar
  static const Color urgenciaAlta = Color(0xFFD64545); // rojo

  // Rojo reservado únicamente para alertas y el botón de "Nuevo Reporte",
  // así no se satura la interfaz de rojo y el usuario distingue qué es
  // realmente urgente.
  static const Color acento = Color(0xFFD64545);
}

/// Tema completo de Material Design para la app.
/// Se aplica una sola vez en el MaterialApp (ver main.dart).
class AppTheme {
  static ThemeData get temaClaro {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.fondo,

      // Paleta base de Material 3, generada a partir del color primario
      // para que botones, checkboxes, etc. hereden tonos coherentes.
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primario,
        primary: AppColors.primario,
        secondary: AppColors.acento,
        surface: AppColors.superficie,
        error: AppColors.urgenciaAlta,
      ),

      // Barra superior: mismo azul principal, texto blanco
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primario,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Tipografía: jerarquía clara entre títulos, cuerpo y texto secundario
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textoPrincipal,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textoSecundario,
          fontSize: 13,
        ),
      ),

      // Botones elevados (ej. "Enviar Reporte"): esquinas redondeadas,
      // padding cómodo para el dedo (accesibilidad táctil)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primario,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Botón flotante (FAB "Nuevo Reporte"): usa el color de acento,
      // no el primario, para que destaque como la acción principal
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.acento,
        foregroundColor: Colors.white,
      ),

      // Campos de formulario: bordes redondeados consistentes,
      // relleno sutil para que se vean "tocables"
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primario, width: 2),
        ),
      ),

      // Tarjetas (ej. contenedor de ubicación, preview de foto):
      // esquinas redondeadas y sombra suave, no plana
      cardTheme: CardThemeData(
        color: AppColors.superficie,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Devuelve el color correspondiente a cada nivel de urgencia.
  /// Se usa tanto en el formulario (selector) como en el historial
  /// (para pintar cada reporte según su urgencia).
  static Color colorPorUrgencia(String urgencia) {
    switch (urgencia) {
      case 'baja':
        return AppColors.urgenciaBaja;
      case 'media':
        return AppColors.urgenciaMedia;
      case 'alta':
        return AppColors.urgenciaAlta;
      default:
        return AppColors.textoSecundario;
    }
  }
}