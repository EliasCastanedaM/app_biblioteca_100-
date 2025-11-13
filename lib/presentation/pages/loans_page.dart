import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../widgets/register_prestamo_modal.dart';

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  List prestamos = [];
  bool loading = true;
  String estado = 'activos';
  String search = '';

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 🔹 Cargar préstamos (con estado y búsqueda)
  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.getPrestamos(
        estado: estado == 'historial' ? 'devueltos' : estado,
        search: search,
      );

      setState(() {
        prestamos = res is List ? res : (res['data'] ?? []);
        loading = false;
      });
    } catch (e) {
      print("❌ Error al cargar préstamos: $e");
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar préstamos: $e')),
      );
    }
  }

  /// 🔹 Cambiar estado (Activos / Retrasados / Historial)
  void _changeEstado(String nuevo) {
    setState(() => estado = nuevo);
    _load();
  }

  /// 🔹 Marcar préstamo como devuelto
  Future<void> _devolverPrestamo(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar devolución'),
        content: const Text('¿Seguro que deseas marcar este préstamo como devuelto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final ok = await ApiService.devolverPrestamo(id);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Préstamo marcado como devuelto')),
        );
        _load(); // refrescar lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ No se pudo actualizar el préstamo')),
        );
      }
    } catch (e) {
      print('❌ Error al devolver préstamo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al devolver préstamo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                blurRadius: 6,
                color: Colors.black.withOpacity(0.05),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Encabezado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gestión de Préstamos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) => const RegisterPrestamoModal(),
                        ).then((refresh) {
                          if (refresh == true) _load(); // 👈 refresca al cerrar
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Registrar Nuevo Préstamo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 🔹 Tabs de estado
                Row(
                  children: [
                    _buildTab('activos', '✓ Activos', Colors.green),
                    const SizedBox(width: 12),
                    _buildTab('retrasados', '⚠️ Retrasados', Colors.red),
                    const SizedBox(width: 12),
                    _buildTab('historial', '○ Historial (Devueltos)', Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),

                // 🔹 Buscador
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2735),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white70,
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 600), () {
                        setState(() => search = value);
                        _load();
                      });
                    },
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF1E2735),
                      prefixIcon: Icon(Icons.search, color: Colors.white70),
                      hintText: 'Buscar por título o estudiante...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 🔹 Encabezados de tabla
                Row(
                  children: const [
                    Expanded(flex: 2, child: Text('Libro', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Usuario', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Fecha Préstamo', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Fecha Límite', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(
                      width: 80,
                      child: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(),

                // 🔹 Lista o loader
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : prestamos.isEmpty
                          ? const Center(child: Text('No hay préstamos registrados'))
                          : ListView.builder(
                              itemCount: prestamos.length,
                              itemBuilder: (context, i) {
                                final p = prestamos[i];
                                final libro = p['libro']?['titulo'] ?? 'Desconocido';
                                final usuario = p['usuario']?['nombre'] ?? 'Sin usuario';
                                final fechaPrestamo = p['fecha_prestamo'] ?? '-';
                                final fechaLimite = p['fecha_devolucion_estimada'] ?? '-';
                                final devuelto = p['fecha_devolucion_real'] != null;

                                final retrasado = !devuelto &&
                                    DateTime.tryParse(p['fecha_devolucion_estimada'] ?? '')?.isBefore(DateTime.now()) == true;

                                final estadoPrestamo = devuelto
                                    ? 'Devuelto'
                                    : retrasado
                                        ? 'Retrasado'
                                        : 'Activo';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 2, child: Text(libro)),
                                      Expanded(flex: 2, child: Text(usuario)),
                                      Expanded(child: Text(fechaPrestamo)),
                                      Expanded(child: Text(fechaLimite)),
                                      Expanded(
                                        child: Text(
                                          estadoPrestamo,
                                          style: TextStyle(
                                            color: retrasado
                                                ? Colors.red
                                                : devuelto
                                                    ? Colors.grey
                                                    : Colors.green,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: IconButton(
                                          icon: const Icon(Icons.assignment_turned_in_outlined, color: Colors.green),
                                          tooltip: 'Marcar como devuelto',
                                          onPressed: devuelto
                                              ? null
                                              : () => _devolverPrestamo(p['id']),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔸 Widget pestaña de estado
  Widget _buildTab(String value, String label, Color color) {
    final selected = estado == value;
    return GestureDetector(
      onTap: () => _changeEstado(value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? color : Colors.black54,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (selected)
            Container(
              height: 2,
              width: 60,
              margin: const EdgeInsets.only(top: 4),
              color: color,
            ),
        ],
      ),
    );
  }
}
