import 'package:flutter/material.dart';

/// Clase que contiene todos los temas de la aplicación
class AppTheme {
  /// Tema claro principal
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // 🎨 Colores principales de la app
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF9800), // naranja base
        primary: const Color(0xFFFF9800),
        secondary: const Color(0xFF2E7D32), // verde
        tertiary: const Color(0xFFE65100), // naranja oscuro
      ),

      // Fondo general de la app
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),

      // 🎴 Estilo de tarjetas (cards)
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // 🔘 Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),

      // 🧾 Inputs (TextField)
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}

