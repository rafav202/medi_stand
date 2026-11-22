import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/medicamento.dart';
import '../widgets/prediccion_mineria_card.dart';

class GraficasScreen extends StatelessWidget {
  final List<Medicamento> medicamentos;
  final bool cargando;

  const GraficasScreen({
    super.key,
    required this.medicamentos,
    required this.cargando,
  });

  Map<String, int> _contarPorVia() {
    final conteo = <String, int>{};
    for (final med in medicamentos) {
      final via = med.viaPrincipalCorta;
      conteo[via] = (conteo[via] ?? 0) + 1;
    }
    return conteo;
  }

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
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF64748B)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Realiza una búsqueda en la pestaña Medicamentos para ver también las gráficas de distribución por vía y tipo.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const PrediccionMineriaCard(),
            ],
          ),
        ),
      );
    }

    final datosPorVia = _contarPorVia();
    final entradasVia = datosPorVia.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topVias = entradasVia.take(6).toList();
    final maxValorVia = topVias.first.value.toDouble();

    final datosPorTipo = _contarPorTipoProducto();
    final entradasTipo = datosPorTipo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final int totalOtc = medicamentos.where((m) => m.esVentaLibre).length;
    final String porcentajeOtc =
        '${(totalOtc / medicamentos.length * 100).toStringAsFixed(0)}%';

    final coloresBarras = <Color>[
      const Color(0xFF0D9488),
      const Color(0xFF2563EB),
      const Color(0xFF4F46E5),
      const Color(0xFFD97706),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
    ];

    final coloresTorta = <Color>[
      const Color(0xFF0D9488),
      const Color(0xFFEA580C),
      const Color(0xFF4F46E5),
      const Color(0xFF0284C7),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool pantallaAncha = constraints.maxWidth >= 860;

        final tarjetaBarras = _construirTarjetaBarras(
          context,
          topVias: topVias,
          maxValorVia: maxValorVia,
          coloresBarras: coloresBarras,
        );

        final tarjetaCircular = _construirTarjetaCircular(
          context,
          entradasTipo: entradasTipo,
          coloresTorta: coloresTorta,
        );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Fila de 3 indicadores clave (KPIs)
                Row(
                  children: [
                    Expanded(
                      child: _tarjetaKpi(
                        titulo: 'Medicamentos analizados',
                        valor: medicamentos.length.toString(),
                        icono: Icons.medication_liquid_rounded,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tarjetaKpi(
                        titulo: 'Vías detectadas',
                        valor: datosPorVia.length.toString(),
                        icono: Icons.alt_route_rounded,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tarjetaKpi(
                        titulo: 'Venta Libre (OTC)',
                        valor: porcentajeOtc,
                        icono: Icons.verified_user_rounded,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Gráficas lado a lado en escritorio o apiladas en móvil
                if (pantallaAncha)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: tarjetaBarras),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: tarjetaCircular),
                    ],
                  )
                else ...[
                  tarjetaBarras,
                  const SizedBox(height: 16),
                  tarjetaCircular,
                ],
                const SizedBox(height: 16),

                // 3. Gráfica predictiva conectada a MySQL Workbench + Python
                const PrediccionMineriaCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _construirTarjetaBarras(
    BuildContext context, {
    required List<MapEntry<String, int>> topVias,
    required double maxValorVia,
    required List<Color> coloresBarras,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución por Vía de Administración',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cantidad de fármacos según su vía principal de ingreso',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValorVia + 1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final via = topVias[group.x].key;
                      final cantidad = rod.toY.toInt();
                      return BarTooltipItem(
                        '$via\n$cantidad med.',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
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
                        if (value % 1 != 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
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
                              color: Color(0xFF334155),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(topVias.length, (i) {
                  final colorBase = coloresBarras[i % coloresBarras.length];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: topVias[i].value.toDouble(),
                        gradient: LinearGradient(
                          colors: [
                            colorBase,
                            colorBase.withValues(alpha: 0.72),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        width: 26,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 28, color: Color(0xFFF1F5F9)),
          ...List.generate(topVias.length, (i) {
            final item = topVias[i];
            final color = coloresBarras[i % coloresBarras.length];
            final fraccion = item.value / medicamentos.length;
            final porcentaje = (fraccion * 100).toStringAsFixed(1);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Text(
                        '${item.value} ($porcentaje%)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fraccion,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _construirTarjetaCircular(
    BuildContext context, {
    required List<MapEntry<String, int>> entradasTipo,
    required List<Color> coloresTorta,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de Dispensación',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Venta libre (OTC) frente a fórmula médica',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 42,
                sections: List.generate(entradasTipo.length, (i) {
                  final item = entradasTipo[i];
                  final porcentaje = (item.value / medicamentos.length * 100)
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
          const Divider(height: 28, color: Color(0xFFF1F5F9)),
          ...List.generate(entradasTipo.length, (i) {
            final item = entradasTipo[i];
            final color = coloresTorta[i % coloresTorta.length];
            final fraccion = item.value / medicamentos.length;
            final porcentaje = (fraccion * 100).toStringAsFixed(1);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Text(
                        '${item.value} ($porcentaje%)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: fraccion,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tarjetaKpi({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
