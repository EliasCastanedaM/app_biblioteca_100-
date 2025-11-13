import 'package:flutter/material.dart';
import '../widgets/sidebar_widget.dart';
import '../widgets/custom_appbar.dart';
import 'users_page.dart';
import 'books_page.dart';
import 'loans_page.dart';
import 'reports_page.dart';
import 'employees_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 2; // Página por defecto (Préstamos)

  final pages = const [
    UsersPage(),
    BooksPage(),
    LoansPage(),
    ReportsPage(),
    EmpleadosPage(),
  ];

  void onSelect(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Biblioteca XYZ',
        userName: 'Josue Castañeda (Admin)',
      ),

      body: Row(
        children: [
          // 🔹 Barra lateral
          SideBarWidget(
            selectedIndex: selectedIndex,
            onSelect: onSelect,
          ),

          // 🔹 Contenido principal SIN fondo gris ni Card
          Expanded(
            child: Container(
              color: Colors.white, // ✅ fondo limpio
              child: IndexedStack(
                index: selectedIndex,
                children: pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
