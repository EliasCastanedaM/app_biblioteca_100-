import 'package:flutter/material.dart';
import '../../data/services/api_service.dart';

class RegisterPrestamoModal extends StatefulWidget {
  const RegisterPrestamoModal({super.key});

  @override
  State<RegisterPrestamoModal> createState() => _RegisterPrestamoModalState();
}

class _RegisterPrestamoModalState extends State<RegisterPrestamoModal> {
  List libros = [];
  List usuarios = [];

  String? selectedLibro;
  String? selectedUsuario;
  DateTime? fechaPrestamo;
  DateTime? fechaLimite;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final resLibros = await ApiService.getLibros();
      final resUsuarios = await ApiService.getUsuarios();
      setState(() {
        libros = resLibros['data'] ?? resLibros;
        usuarios = resUsuarios['data'] ?? resUsuarios;
      });
    } catch (e) {
      print('❌ Error al cargar listas: $e');
    }
  }

  Future<void> _registrarPrestamo() async {
    if (selectedLibro == null ||
        selectedUsuario == null ||
        fechaLimite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => loading = true);

    final success = await ApiService.createPrestamo({
      'libro_id': selectedLibro,
      'usuario_id': selectedUsuario,
      'fecha_devolucion_estimada': fechaLimite!
          .toIso8601String()
          .split('T')
          .first, // ✅ formato correcto YYYY-MM-DD
    });

    setState(() => loading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Préstamo registrado correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error al registrar préstamo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Título
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Registrar Nuevo Préstamo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🔹 Seleccionar libro
              const Text(
                'Libro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                decoration: _inputStyle(),
                hint: const Text('Seleccionar libro'),
                value: selectedLibro,
                items: libros
                    .map<DropdownMenuItem<String>>(
                      (l) => DropdownMenuItem(
                        value: l['id'].toString(),
                        child: Text(l['titulo']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedLibro = v),
              ),
              const SizedBox(height: 12),

              // 🔹 Seleccionar usuario
              const Text(
                'Usuario (Estudiante)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                decoration: _inputStyle(),
                hint: const Text('Seleccionar usuario'),
                value: selectedUsuario,
                items: usuarios
                    .map<DropdownMenuItem<String>>(
                      (u) => DropdownMenuItem(
                        value: u['id'].toString(),
                        child: Text('${u['nombre']} ${u['apellido']}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedUsuario = v),
              ),
              const SizedBox(height: 12),

              // 🔹 Fecha préstamo
              const Text(
                'Fecha de Préstamo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                readOnly: true,
                decoration: _inputStyle().copyWith(
                  hintText: 'mm/dd/yyyy',
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                    initialDate: DateTime.now(),
                  );
                  if (date != null) setState(() => fechaPrestamo = date);
                },
                controller: TextEditingController(
                  text: fechaPrestamo == null
                      ? ''
                      : '${fechaPrestamo!.month}/${fechaPrestamo!.day}/${fechaPrestamo!.year}',
                ),
              ),
              const SizedBox(height: 12),

              // 🔹 Fecha límite
              const Text(
                'Fecha Límite',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                readOnly: true,
                decoration: _inputStyle().copyWith(
                  hintText: 'mm/dd/yyyy',
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                  );
                  if (date != null) setState(() => fechaLimite = date);
                },
                controller: TextEditingController(
                  text: fechaLimite == null
                      ? ''
                      : '${fechaLimite!.month}/${fechaLimite!.day}/${fechaLimite!.year}',
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Botón registrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: loading ? null : _registrarPrestamo,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Registrar Préstamo',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle() => InputDecoration(
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
  );
}
