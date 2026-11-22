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

  /// Agrupa los medicamentos según su tipo de comercialización (Venta libre vs. Prescripción).
  Map<String, int> _contarPorTipoProducto() {
    final conteo = <String, int>{};
    for (final med in medicamentos) {
      final tipoBruto = med.formaFarmaceutica.trim().toUpperCase();
      String categoria;
      if (tipoBruto.contains('OTC')) {
        categoria = 'Venta Libre (OTC)';
      } else if (tipoBruto.contains('PRESCRIPTION')) {
        categoria = 'Fórmula Médica';
      } else if (tipoBruto == 'NO REGISTRADA' || tipoBruto.isEmpty) {
        categoria = 'No especificado';
      } else {
        categoria = tipoBruto;
      }
      conteo[categoria] = (conteo[categoria] ?? 0) + 1;
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
            'No hay datos suficientes para graficar.\nRealiza primero una búsqueda en la pestaña Medicamentos.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Datos para Gráfica 1: Barras por Vía de Administración
    final datosPorVia = _contarPorVia();
    final entradasVia = datosPorVia.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topVias = entradasVia.take(6).toList();
    final maxValorVia = topVias.first.value.toDouble();

    // Datos para Gráfica 2: Circular (PieChart) por Tipo de Producto
    final datosPorTipo = _contarPorTipoProducto();
    final entradasTipo = datosPorTipo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final coloresBarras = <Color>[
      Colors.teal,
      Colors.blue,
      Colors.indigo,
      Colors.orange,
      Colors.purple,
      Colors.green,
    ];

    final coloresTorta = <Color>[
      Colors.teal,
      Colors.deepOrange,
      Colors.indigo,
      Colors.amber.shade700,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Tarjetas de resumen superior
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

        // 2. Gráfica de Barras: Distribución por Vía de Administración
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. Distribución por Vía de Administración',
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
                      maxY: maxValorVia + 1,
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
                              // Subimos el límite a 12 caracteres para que OPHTHALMIC se lea completo
                              final etiqueta = topVias[index].key;
                              final corta = etiqueta.length > 12
                                  ? '${etiqueta.substring(0, 12)}...'
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
                              color: coloresBarras[i % coloresBarras.length],
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
                const Divider(height: 24),
                ...List.generate(topVias.length, (i) {
                  final item = topVias[i];
                  final porcentaje = (item.value / medicamentos.length * 100)
                      .toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: coloresBarras[i % coloresBarras.length],
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
        const SizedBox(height: 16),

        // 3. Segunda Gráfica (Circular / PieChart): Venta Libre vs. Fórmula Médica
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2. Clasificación por Tipo de Dispensación',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Proporción entre venta libre (OTC) y medicamentos con fórmula médica',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 210,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 38,
                      sections: List.generate(entradasTipo.length, (i) {
                        final item = entradasTipo[i];
                        final porcentaje =
                            (item.value / medicamentos.length * 100)
                                .toStringAsFixed(0);
                        return PieChartSectionData(
                          value: item.value.toDouble(),
                          title: '$porcentaje%',
                          color: coloresTorta[i % coloresTorta.length],
                          radius: 56,
                          titleStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const Divider(height: 24),
                ...List.generate(entradasTipo.length, (i) {
                  final item = entradasTipo[i];
                  final porcentaje = (item.value / medicamentos.length * 100)
                      .toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: coloresTorta[i % coloresTorta.length],
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
