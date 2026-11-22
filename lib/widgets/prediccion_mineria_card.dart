import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/prediccion_mineria_service.dart';

class PrediccionMineriaCard extends StatefulWidget {
  const PrediccionMineriaCard({super.key});

  @override
  State<PrediccionMineriaCard> createState() => _PrediccionMineriaCardState();
}

class _PrediccionMineriaCardState extends State<PrediccionMineriaCard> {
  final PrediccionMineriaService _service = PrediccionMineriaService();
  late Future<RespuestaPrediccionMineria> _futurePrediccion;

  String _urlActual = PrediccionMineriaService.urlBasePorDefecto;
  int _mesesProyectar = 6;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    setState(() {
      _futurePrediccion = _service.obtenerPrediccion(
        meses: _mesesProyectar,
        urlPersonalizada: _urlActual,
      );
    });
  }

  Future<void> _mostrarDialogoUrl() async {
    final controller = TextEditingController(text: _urlActual);
    final nuevaUrl = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'URL del Túnel Cloudflare',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pega la URL pública activa que muestra la terminal de Python (sin /api/...):',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'https://xxxx.trycloudflare.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Conectar'),
          ),
        ],
      ),
    );

    if (nuevaUrl != null && nuevaUrl.isNotEmpty) {
      _urlActual = nuevaUrl;
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Color(0xFF0D9488),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicción de Demanda (Minería de Datos)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Histórico en MySQL Workbench + proyección por regresión lineal',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cambiar URL del túnel Cloudflare',
                icon: const Icon(Icons.link_rounded, color: Color(0xFF334155)),
                onPressed: _mostrarDialogoUrl,
              ),
              IconButton(
                tooltip: 'Actualizar datos',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF334155),
                ),
                onPressed: _cargarDatos,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text(
                'Horizonte de predicción:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              _chipMeses(3, '3 meses'),
              _chipMeses(6, '6 meses'),
              _chipMeses(12, '12 meses'),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<RespuestaPrediccionMineria>(
            future: _futurePrediccion,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 44),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No se pudo obtener la predicción desde el servidor local:\n${snapshot.error}',
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _mostrarDialogoUrl,
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Actualizar URL del túnel'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _cargarDatos,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return _construirContenidoGrafica(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _chipMeses(int meses, String etiqueta) {
    final seleccionado = _mesesProyectar == meses;
    return ChoiceChip(
      label: Text(etiqueta),
      selected: seleccionado,
      selectedColor: const Color(0xFF0D9488).withValues(alpha: 0.16),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: seleccionado ? const Color(0xFF0F766E) : const Color(0xFF475569),
      ),
      onSelected: (_) {
        _mesesProyectar = meses;
        _cargarDatos();
      },
    );
  }

  Widget _construirContenidoGrafica(RespuestaPrediccionMineria data) {
    final spotsHistoricos = data.historicos
        .map((p) => FlSpot(p.mesNumero.toDouble(), p.unidadesReales ?? 0))
        .toList();

    final spotsPrediccion = <FlSpot>[];
    if (data.historicos.isNotEmpty) {
      final ultimoHist = data.historicos.last;
      spotsPrediccion.add(
        FlSpot(ultimoHist.mesNumero.toDouble(), ultimoHist.unidadesReales ?? 0),
      );
    }
    for (final p in data.predicciones) {
      spotsPrediccion.add(
        FlSpot(p.mesNumero.toDouble(), p.unidadesPredichas ?? 0),
      );
    }

    final etiquetasPorMes = <int, String>{};
    for (final p in data.historicos) {
      etiquetasPorMes[p.mesNumero] = p.etiqueta;
    }
    for (final p in data.predicciones) {
      etiquetasPorMes[p.mesNumero] = p.etiqueta;
    }

    final int maxMes = etiquetasPorMes.keys.isEmpty
        ? 30
        : etiquetasPorMes.keys.reduce((a, b) => a > b ? a : b);

    final String medicamento = data.historicos.isNotEmpty
        ? data.historicos.first.medicamento
        : 'Medicamento';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chipMetrica('Fármaco', medicamento, const Color(0xFF2563EB)),
            _chipMetrica(
              'Precisión R²',
              data.r2Precision.toStringAsFixed(4),
              const Color(0xFF0D9488),
            ),
            _chipMetrica(
              'Error MAE',
              '${data.errorMae.toStringAsFixed(2)} u.',
              const Color(0xFFD97706),
            ),
            _chipMetrica(
              'Entrenamiento',
              '${data.registrosEntrenamiento} meses',
              const Color(0xFF4F46E5),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _itemLeyenda(const Color(0xFF0D9488), 'Unidades reales (MySQL)'),
            const SizedBox(width: 18),
            _itemLeyenda(
              const Color(0xFFEA580C),
              'Predicción (${data.algoritmo})',
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 255,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 250,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
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
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final mes = value.toInt();
                      if (mes % 6 != 1 && mes != maxMes) {
                        return const SizedBox.shrink();
                      }
                      final texto = etiquetasPorMes[mes] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          texto,
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
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(color: Color(0xFFE2E8F0)),
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF0F172A),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final mes = spot.x.toInt();
                      final etiqueta = etiquetasPorMes[mes] ?? 'Mes $mes';
                      final esPrediccion = spot.barIndex == 1;
                      return LineTooltipItem(
                        '$etiqueta\n${esPrediccion ? "Predicción" : "Real"}: ${spot.y.toStringAsFixed(1)} u.',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spotsHistoricos,
                  isCurved: true,
                  color: const Color(0xFF0D9488),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                  ),
                ),
                LineChartBarData(
                  spots: spotsPrediccion,
                  isCurved: true,
                  color: const Color(0xFFEA580C),
                  barWidth: 3,
                  dashArray: [6, 4],
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFFEA580C).withValues(alpha: 0.10),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (data.predicciones.isNotEmpty) ...[
          const Divider(height: 28, color: Color(0xFFF1F5F9)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFFEA580C),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Proyección a ${data.predicciones.last.etiqueta}: '
                    '${data.predicciones.last.unidadesPredichas?.toStringAsFixed(1)} unidades dispensadas '
                    'y ${data.predicciones.last.consultasPredichas?.toStringAsFixed(1)} consultas estimadas.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _chipMetrica(String titulo, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$titulo: $valor',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _itemLeyenda(Color color, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}
