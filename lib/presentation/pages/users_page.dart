import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_service.dart';
import '../widgets/form_modal.dart';
import '../pages/login_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List allUsers = [];
  List filteredUsers = [];
  bool loading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');

    if (savedToken == null || savedToken.isEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    if (!mounted) return;
    setState(() => token = savedToken);
    await _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.getUsuarios(page: 1);
      if (!mounted) return;
      setState(() {
        allUsers = res['data'] ?? res;
        filteredUsers = allUsers;
        loading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar usuarios: $e');
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void _filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredUsers = allUsers.where((u) {
        final nombre = '${u['nombre']} ${u['apellido']}'.toLowerCase();
        final codigo = (u['codigo_estudiante'] ?? '').toLowerCase();
        final email = (u['email'] ?? '').toLowerCase();
        return nombre.contains(lowerQuery) ||
            codigo.contains(lowerQuery) ||
            email.contains(lowerQuery);
      }).toList();
    });
  }

  void _openUserModal({Map<String, dynamic>? usuario}) {
    final isEdit = usuario != null;

    showDialog(
      context: context,
      builder: (ctx) => FormModal(
        title: isEdit ? 'Editar Usuario' : 'Registrar Nuevo Usuario',
        fields: [
          {'key': 'nombre', 'label': 'Nombre', 'initialValue': usuario?['nombre'] ?? ''},
          {'key': 'apellido', 'label': 'Apellido', 'initialValue': usuario?['apellido'] ?? ''},
          {
            'key': 'codigo_estudiante',
            'label': 'Código de Estudiante',
            'initialValue': usuario?['codigo_estudiante'] ?? ''
          },
          {'key': 'email', 'label': 'Correo Electrónico', 'initialValue': usuario?['email'] ?? ''},
        ],
        onSubmit: (formData) async {
          // ✅ Cerramos el modal ANTES de hacer la petición
          Navigator.of(ctx, rootNavigator: true).pop();

          try {
            if (mounted) setState(() => loading = true);

            bool ok;
            if (isEdit) {
              ok = await ApiService.updateUsuario(
                id: usuario!['id'].toString(),
                nombre: formData['nombre'],
                apellido: formData['apellido'],
                codigoEstudiante: formData['codigo_estudiante'],
                email: formData['email'],
              );
            } else {
              ok = await ApiService.createUsuario(
                nombre: formData['nombre'],
                apellido: formData['apellido'],
                codigoEstudiante: formData['codigo_estudiante'],
                email: formData['email'],
              );
            }

            // ✅ Refrescamos los datos
            if (mounted) await _load();

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? (isEdit
                          ? '✅ Usuario actualizado correctamente'
                          : '✅ Usuario registrado correctamente')
                      : '❌ Error al guardar usuario',
                ),
              ),
            );
          } catch (e) {
            debugPrint('Error al guardar usuario: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('❌ Error: $e')),
              );
            }
          } finally {
            if (mounted) setState(() => loading = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
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
                  'Gestión de Usuarios',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openUserModal(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Registrar Nuevo Usuario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Barra de búsqueda
            TextField(
              onChanged: _filterUsers,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por nombre, código o correo...',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Tabla de datos
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 40,
                    headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    columns: const [
                      DataColumn(label: Text('Nombre Completo')),
                      DataColumn(label: Text('Código')),
                      DataColumn(label: Text('Correo Electrónico')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Préstamos Activos')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: filteredUsers.map((u) {
                      final nombreCompleto =
                          '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim();
                      final prestamos = u['prestamos_activos_count'] ?? 0;
                      final activo = prestamos > 0;

                      return DataRow(
                        cells: [
                          DataCell(Text(nombreCompleto.isEmpty ? '-' : nombreCompleto)),
                          DataCell(Text(u['codigo_estudiante'] ?? '-')),
                          DataCell(Text(u['email'] ?? '-')),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: activo
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              activo ? 'Activo' : 'Sin préstamos',
                              style: TextStyle(
                                color: activo
                                    ? Colors.green.shade800
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                          DataCell(Text('$prestamos')),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                                onPressed: () => _openUserModal(usuario: u),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () async {
                                  final ok = await ApiService.deleteUsuario(u['id'].toString());
                                  if (!mounted) return;

                                  if (ok) {
                                    await _load();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Usuario eliminado')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Error al eliminar usuario')),
                                    );
                                  }
                                },
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
