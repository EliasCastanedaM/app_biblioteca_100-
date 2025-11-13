import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/custom_button.dart'; // 👈 Importa tu botón reutilizable

class SideBarWidget extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onSelect;

  const SideBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.person_outline, 'label': 'Gestión de Usuarios'},
      {'icon': Icons.book_outlined, 'label': 'Gestión de Libros'},
      {'icon': Icons.book_online, 'label': 'Préstamos'},
      {'icon': Icons.bar_chart, 'label': 'Reportes'},
      {'icon': Icons.badge, 'label': 'Empleados'},
    ];

    return Container(
      width: 240,
      color: AppTheme.light().primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text(
            'MENÚ PRINCIPAL',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 18),

          // 🔹 Generamos los botones dinámicamente
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomButton(
                text: items[i]['label'] as String,
                icon: items[i]['icon'] as IconData,
                isSelected: selectedIndex == i,
                onPressed: () => onSelect(i),
              ),
            ),

          const SizedBox(height: 20),

          // 🔴 Cerrar sesión
          CustomButton(
            text: 'Cerrar Sesión',
            icon: Icons.logout,
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
            isSelected: false,
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
