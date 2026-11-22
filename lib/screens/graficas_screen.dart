import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/medicamento.dart';

class GraficasScreen extends StatelessWidget {
  final List<Medicamento> medicamentos;
  final bool cargando;

  const GraficasScreen({
    super.key,
    required this.medicamentos,
    required this.cargando,
  });

  /// Agrupa los medicamentos consultados por su vía de administración principal.
  Map<String, int> _contarPorVia() {
    final conteo = <String, int>{};
    for (final med in medicamentos) {
      final via = med.viaPrincipalCorta;
      conteo[via] = (conteo[via] ?? 0) + 1;
    }
    return conteo;
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (medicamentos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay datos suficientes para graficar.\nRealiza primero una búsqueda en la pestaña Consulta.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final datosPorVia = _contarPorVia();
    final entradas = datosPorVia.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Tomamos máximo las 6 vías más frecuentes para que la gráfica sea legible.
    final topVias = entradas.take(6).toList();
    final maxValor = topVias.first.value.toDouble();

    final colores = <Color>[
      Colors.teal,
      Colors.blue,
      Colors.indigo,
      Colors.orange,
      Colors.purple,
      Colors.green,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumen numérico superior
        Row(
          children: [
            Expanded(
              child: _tarjetaResumen(
                context,
                titulo: 'Medicamentos analizados',
                valor: medicamentos.length.toString(),
                icono: Icons.medication_liquid,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _tarjetaResumen(
                context,
                titulo: 'Vías detectadas',
                valor: datosPorVia.length.toString(),
                icono: Icons.alt_route,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tarjeta con gráfica de barras en fl_chart
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribución por Vía de Administración',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cantidad de medicamentos consultados según su vía principal',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 240,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxValor + 1,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 != 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 11),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= topVias.length) {
                                return const SizedBox.shrink();
                              }
                              final etiqueta = topVias[index].key;
                              final corta = etiqueta.length > 8
                                  ? '${etiqueta.substring(0, 8)}...'
                                  : etiqueta;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  corta,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(topVias.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: topVias[i].value.toDouble(),
                              color: colores[i % colores.length],
                              width: 22,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Desglose detallado en lista
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detalle numérico por categoría',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...List.generate(topVias.length, (i) {
                  final item = topVias[i];
                  final porcentaje = (item.value / medicamentos.length * 100)
                      .toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colores[i % colores.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${item.value} ($porcentaje%)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaResumen(
    BuildContext context, {
    required String titulo,
    required String valor,
    required IconData icono,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              valor,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
