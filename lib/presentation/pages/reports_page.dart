// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/services/api_service.dart';

// 👇 Solo importamos para web
import 'dart:html' as html show Blob, Url, AnchorElement;
import 'dart:io' as io show File; // 👈 solo para mobile / desktop

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  Map<String, dynamic>? dashboardData;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await ApiService.getDashboardReport();
      setState(() {
        dashboardData = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _exportToExcel() async {
    try {
      if (dashboardData == null) return;

      final excel = Excel.createExcel();

      // ===== Hoja 1: KPIs =====
      final Sheet kpiSheet = excel['KPIs'];
      final kpis = dashboardData?['kpis'] ?? {};
      kpiSheet.appendRow(['Métrica', 'Valor']);
      kpiSheet.appendRow(['Total Préstamos Mes', kpis['total_prestamos_mes']]);
      kpiSheet.appendRow(['Préstamos Activos', kpis['prestamos_activos']]);
      kpiSheet.appendRow([
        'Préstamos Retrasados',
        kpis['prestamos_retrasados'],
      ]);
      kpiSheet.appendRow([
        'Usuarios Registrados',
        kpis['usuarios_registrados'],
      ]);

      // ===== Hoja 2: Préstamos por Mes =====
      final Sheet mesSheet = excel['Préstamos por Mes'];
      final prestamosPorMes = List<Map<String, dynamic>>.from(
        dashboardData?['graficos']?['prestamos_por_mes'] ?? [],
      );
      mesSheet.appendRow(['Mes', 'Total Préstamos']);
      for (final p in prestamosPorMes) {
        mesSheet.appendRow(['Mes ${p['mes']}', p['total']]);
      }

      // ===== Hoja 3: Categorías Populares =====
      final Sheet catSheet = excel['Categorías Populares'];
      final categorias = List<Map<String, dynamic>>.from(
        dashboardData?['graficos']?['categorias_populares'] ?? [],
      );
      catSheet.appendRow(['Categoría', 'Total Préstamos']);
      for (final c in categorias) {
        catSheet.appendRow([c['categoria'], c['total_prestamos']]);
      }

      // ===== Hoja 4: Libros más Prestados =====
      final Sheet librosSheet = excel['Libros más Prestados'];
      final libros = List<Map<String, dynamic>>.from(
        dashboardData?['libros_mas_prestados'] ?? [],
      );

      librosSheet.appendRow(['Título', 'Autor', 'ISBN', 'Total Préstamos']);
      for (final libro in libros) {
        librosSheet.appendRow([
          libro['titulo'],
          libro['autor'],
          libro['isbn'],
          libro['total_prestamos'],
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception("No se pudo generar el Excel");

      // ✅ Detección automática de plataforma
      if (kIsWeb) {
        // --- MODO WEB ---
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "reporte_biblioteca.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // --- MODO MÓVIL / DESKTOP ---
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/reporte_biblioteca.xlsx';
        final file = io.File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
        await OpenFilex.open(path);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reporte exportado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al exportar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text('❌ Error: $error'));
    }

    final kpis = dashboardData?['kpis'] ?? {};
    final graficos = dashboardData?['graficos'] ?? {};
    final prestamosPorMes = List<Map<String, dynamic>>.from(
      graficos['prestamos_por_mes'] ?? [],
    );
    final categoriasPopulares = List<Map<String, dynamic>>.from(
      graficos['categorias_populares'] ?? [],
    );
    final libros = List<Map<String, dynamic>>.from(
      dashboardData?['libros_mas_prestados'] ?? [],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📊 Panel de Reportes',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _exportToExcel,
                icon: const Icon(Icons.download),
                label: const Text('Exportar Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ===== KPIs =====
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildKpiCard(
                Icons.library_books,
                'Préstamos del Mes',
                kpis['total_prestamos_mes'],
              ),
              _buildKpiCard(
                Icons.bookmark_added,
                'Activos',
                kpis['prestamos_activos'],
              ),
              _buildKpiCard(
                Icons.warning_amber_rounded,
                'Retrasados',
                kpis['prestamos_retrasados'],
              ),
              _buildKpiCard(
                Icons.people,
                'Usuarios Registrados',
                kpis['usuarios_registrados'],
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ===== GRÁFICO DE BARRAS =====
          const Text(
            '📅 Préstamos por Mes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < prestamosPorMes.length) {
                          final mes = prestamosPorMes[index]['mes'];
                          return Text(
                            'Mes $mes',
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barGroups: prestamosPorMes.asMap().entries.map((e) {
                  final index = e.key;
                  final total = e.value['total'] ?? 0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (total as num).toDouble(),
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(6),
                        width: 22,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // ===== GRÁFICO DE PASTEL =====
          const Text(
            '📚 Categorías más Populares',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: categoriasPopulares.map((c) {
                  final total = c['total_prestamos'] ?? 0;
                  return PieChartSectionData(
                    value: (total as num).toDouble(),
                    title: '${c['categoria']}',
                    radius: 90,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // ===== LISTA DE LIBROS =====
          const Text(
            '📖 Libros más Prestados',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Título')),
                DataColumn(label: Text('Autor')),
                DataColumn(label: Text('ISBN')),
                DataColumn(label: Text('Total Préstamos')),
              ],
              rows: libros.map((l) {
                return DataRow(
                  cells: [
                    DataCell(Text(l['titulo'] ?? '-')),
                    DataCell(Text(l['autor'] ?? '-')),
                    DataCell(Text(l['isbn'] ?? '-')),
                    DataCell(Text('${l['total_prestamos'] ?? 0}')),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(IconData icon, String label, dynamic value) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 36),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
