import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biblioteca XYZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(), // Centraliza estilos y colores
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}
