import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';
import '../widgets/form_modal.dart';
import '../pages/login_page.dart';

class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({super.key});

  @override
  State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  List allEmpleados = [];
  List filteredEmpleados = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  /// 🔹 Carga inicial (sin token)
  Future<void> _initPage() async {
    try {
      await _load();
    } catch (e) {
      debugPrint('Error inicializando empleados: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo conectar con el servidor')),
      );

      // Opcional: volver al login si la API no responde
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  /// 🔹 Carga empleados desde la API
  Future<void> _load() async {
    try {
      final res = await ApiService.getEmpleados(page: 1);
      if (!mounted) return;
      setState(() {
        allEmpleados = res['data'] ?? res;
        filteredEmpleados = allEmpleados;
        loading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar empleados: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  /// 🔹 Filtrar empleados
  void _filterEmpleados(String query) {
    final lower = query.toLowerCase();
    setState(() {
      filteredEmpleados = allEmpleados.where((u) {
        final n = (u['nombre'] ?? '').toLowerCase();
        final e = (u['email'] ?? '').toLowerCase();
        final r = (u['rol'] ?? '').toLowerCase();
        return n.contains(lower) || e.contains(lower) || r.contains(lower);
      }).toList();
    });
  }

  /// 🔹 Modal Crear/Editar empleado
  void _openEmpleadoModal({Map<String, dynamic>? empleado}) {
    final isEdit = empleado != null;

    // ✅ Importante: usar `showDialog` con rootNavigator
    showDialog(
      context: context,
      barrierDismissible: false, // evita cerrar accidentalmente
      builder: (dialogCtx) {
        return FormModal(
          title: isEdit ? 'Editar Empleado' : 'Registrar Nuevo Empleado',
          fields: [
            {
              'key': 'nombre',
              'label': 'Nombre',
              'initialValue': empleado?['nombre'] ?? '',
            },
            {
              'key': 'email',
              'label': 'Correo Electrónico',
              'initialValue': empleado?['email'] ?? '',
            },
            {
              'key': 'password',
              'label': 'Contraseña',
              'initialValue': '',
              'obscureText': true,
              'hint': isEdit
                  ? 'Deja vacío para mantener la contraseña actual'
                  : 'Mínimo 8 caracteres',
            },
            {
              'key': 'rol',
              'label': 'Rol (admin o empleado)',
              'initialValue': empleado?['rol'] ?? 'empleado',
            },
          ],
          onSubmit: (formData) async {
            try {
              final data = {
                'nombre': formData['nombre'],
                'email': formData['email'],
                'rol': formData['rol'],
              };

              if (!isEdit || (formData['password']?.isNotEmpty ?? false)) {
                data['password'] = formData['password'];
              }

              // 🔹 Crear o editar
              final ok = isEdit
                  ? await ApiService.updateEmpleado(empleado!['id'], data)
                  : await ApiService.createEmpleado(data);

              if (!mounted) return;

              if (!mounted) return;

              // 🔹 Primero cerramos el modal correctamente
              Navigator.of(dialogCtx, rootNavigator: true).pop();

              // 🔹 Esperamos un pequeño delay antes de recargar
              await Future.delayed(const Duration(milliseconds: 300));

              if (!mounted) return;

              // 🔹 Luego recargamos la lista de empleados
              await _load();

              if (!mounted) return;

              // 🔹 Mostramos el mensaje de éxito
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEdit
                        ? 'Empleado actualizado correctamente'
                        : 'Empleado registrado correctamente',
                  ),
                ),
              );
            } catch (e) {
              debugPrint('Error al guardar empleado: $e');
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
        );
      },
    );
  }

  /// 🔹 Eliminar empleado
  Future<void> _deleteEmpleado(int id) async {
    try {
      final ok = await ApiService.deleteEmpleado(id);
      if (!mounted) return;
      if (ok) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empleado eliminado correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar empleado')),
        );
      }
    } catch (e) {
      debugPrint('Error al eliminar empleado: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestión de Empleados',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openEmpleadoModal(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Registrar Nuevo Empleado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Barra de búsqueda
            TextField(
              onChanged: _filterEmpleados,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por nombre, correo o rol...',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Tabla
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 40,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  columns: const [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Correo')),
                    DataColumn(label: Text('Rol')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: filteredEmpleados.map((u) {
                    return DataRow(
                      cells: [
                        DataCell(Text(u['nombre'] ?? '-')),
                        DataCell(Text(u['email'] ?? '-')),
                        DataCell(Text(u['rol'] ?? '-')),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    _openEmpleadoModal(empleado: u),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteEmpleado(u['id']),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
