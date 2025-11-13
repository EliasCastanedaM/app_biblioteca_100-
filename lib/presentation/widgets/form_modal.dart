import 'package:flutter/material.dart';

class FormModal extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> fields;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const FormModal({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
  });

  @override
  State<FormModal> createState() => _FormModalState();
}

class _FormModalState extends State<FormModal> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    for (var f in widget.fields) {
      _controllers[f['key']] =
          TextEditingController(text: f['initialValue'] ?? '');
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      child: Container(
        width: 600,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Encabezado (Título + botón de cerrar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 🔹 Campos del formulario
              ...widget.fields.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _controllers[f['key']],
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
                    decoration: InputDecoration(
                      labelText: f['label'],
                      hintText: _getHint(f['label']),
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // 🔹 Botón principal
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _loading = true);
                          final formData = {
                            for (var f in widget.fields)
                              f['key'] as String: _controllers[f['key']]!.text,
                          };
                          await widget.onSubmit(formData);
                          if (mounted) Navigator.pop(context, formData);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Registrar Usuario'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔸 Devuelve placeholders automáticos según el campo
  String _getHint(String label) {
    if (label.contains('Nombre')) return 'Ej: Juan Pérez';
    if (label.contains('Código')) return 'Ej: 12345';
    if (label.contains('Correo')) return 'usuario@estudiante.com';
    return '';
  }
}
