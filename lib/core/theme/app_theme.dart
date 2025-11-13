import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF0D57FF); // azul principal (ajústalo)
  static const Color sidebarDark = Color(0xFF111827); // boton inactivo
  static const Color background = Color(0xFFF5F6F8);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryBlue,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
