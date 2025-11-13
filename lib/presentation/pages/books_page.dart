import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  List libros = [];
  bool loading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadLibros();
  }

  Future<void> _loadLibros() async {
    try {
      final res = await ApiService.getLibros(page: 1);
      setState(() {
        libros = res['data'] ?? [];
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error cargando libros: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _crearLibro(Map<String, dynamic> data) async {
    try {
      final ok = await ApiService.createLibro(data);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Libro registrado correctamente")),
        );
        _loadLibros();
      } else {
        throw Exception("Error al registrar el libro");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ $e")));
    }
  }

  Future<void> _eliminarLibro(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar libro"),
        content: const Text("¿Seguro que deseas eliminar este libro?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancelar")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Eliminar")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final ok = await ApiService.deleteLibro(id);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Libro eliminado correctamente")),
        );
        _loadLibros();
      } else {
        throw Exception("No se pudo eliminar el libro");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ $e")));
    }
  }

  Future<void> _editarLibro(int id, Map<String, dynamic> data) async {
    try {
      final ok = await ApiService.updateLibro(id, data);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Libro actualizado correctamente")),
        );
        _loadLibros();
      } else {
        throw Exception("Error al actualizar el libro");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ $e")));
    }
  }

  List get filteredLibros {
    if (searchQuery.isEmpty) return libros;
    return libros.where((b) {
      final query = searchQuery.toLowerCase();
      return (b['titulo'] ?? '').toLowerCase().contains(query) ||
          (b['autor'] ?? '').toLowerCase().contains(query) ||
          (b['isbn'] ?? '').toLowerCase().contains(query);
    }).toList();
  }

  void _abrirDialogoLibro({Map<String, dynamic>? libro}) {
    final tituloCtrl = TextEditingController(text: libro?['titulo'] ?? '');
    final autorCtrl = TextEditingController(text: libro?['autor'] ?? '');
    final isbnCtrl = TextEditingController(text: libro?['isbn'] ?? '');
    final categoriaCtrl = TextEditingController(text: libro?['categoria'] ?? '');
    final disponiblesCtrl = TextEditingController(
        text: libro?['ejemplares_disponibles']?.toString() ?? '');
    final totalesCtrl = TextEditingController(
        text: libro?['ejemplares_totales']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final modalWidth = screenWidth < 600
            ? screenWidth * 0.9
            : screenWidth < 1000
                ? screenWidth * 0.6
                : 600.0;

        return Dialog(
          backgroundColor: Colors.blueGrey[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: modalWidth,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    libro == null ? "Registrar Libro" : "Editar Libro",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                      controller: tituloCtrl,
                      decoration:
                          const InputDecoration(labelText: "Título")),
                  const SizedBox(height: 20),
                  TextField(
                      controller: autorCtrl,
                      decoration:
                          const InputDecoration(labelText: "Autor")),
                  const SizedBox(height: 20),
                  TextField(
                      controller: isbnCtrl,
                      decoration: const InputDecoration(labelText: "ISBN")),
                                        const SizedBox(height: 20),

                  TextField(
                      controller: categoriaCtrl,
                      decoration:
                          const InputDecoration(labelText: "Categoría")),
                                            const SizedBox(height: 20),

                  TextField(
                    controller: totalesCtrl,
                    decoration: const InputDecoration(
                        labelText: "Ejemplares totales"),
                    keyboardType: TextInputType.number,
                  ),
                                    const SizedBox(height: 20),

                  TextField(
                    controller: disponiblesCtrl,
                    decoration: const InputDecoration(
                        labelText: "Ejemplares disponibles"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cancelar"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final data = {
                            "titulo": tituloCtrl.text,
                            "autor": autorCtrl.text,
                            "isbn": isbnCtrl.text,
                            "categoria": categoriaCtrl.text,
                            "ejemplares_totales":
                                int.tryParse(totalesCtrl.text) ?? 0,
                            "ejemplares_disponibles":
                                int.tryParse(disponiblesCtrl.text) ?? 0,
                          };

                          Navigator.pop(ctx);
                          if (libro == null) {
                            _crearLibro(data);
                          } else {
                            _editarLibro(libro['id'], data);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child:
                            Text(libro == null ? "Registrar" : "Guardar"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 🔹 Encabezado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Gestión de Libros',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _abrirDialogoLibro(),
              icon: const Icon(Icons.add),
              label: const Text('Registrar Nuevo Libro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 🔹 Buscador
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Buscar por título, autor o ISBN...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (v) => setState(() => searchQuery = v),
        ),

        const SizedBox(height: 20),

        // 🔹 Tabla
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text("Título")),
                        DataColumn(label: Text("Autor")),
                        DataColumn(label: Text("ISBN")),
                        DataColumn(label: Text("Categoría")),
                        DataColumn(label: Text("Disponibles")),
                        DataColumn(label: Text("Estado")),
                        DataColumn(label: Text("Acciones")),
                      ],
                      rows: filteredLibros.map((b) {
                        final disponibles = b['ejemplares_disponibles'] ?? 0;
                        final estado =
                            disponibles > 0 ? 'Disponible' : 'Agotado';
                        final colorEstado =
                            disponibles > 0 ? Colors.green : Colors.red;

                        return DataRow(cells: [
                          DataCell(Text(b['titulo'] ?? 'Sin título')),
                          DataCell(Text(b['autor'] ?? '')),
                          DataCell(Text(b['isbn'] ?? '')),
                          DataCell(Text(b['categoria'] ?? '')),
                          DataCell(Text('$disponibles')),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorEstado.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              estado,
                              style: TextStyle(
                                color: colorEstado,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _abrirDialogoLibro(libro: b),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () =>
                                    _eliminarLibro(b['id']),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}
