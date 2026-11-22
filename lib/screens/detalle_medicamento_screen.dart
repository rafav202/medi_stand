import 'package:flutter/material.dart';

import '../models/medicamento.dart';
import '../services/medicamento_service.dart';
import '../widgets/medi_stand_logo.dart';
import '../widgets/medicamento_visual.dart';

class DetalleMedicamentoScreen extends StatefulWidget {
  final Medicamento medicamento;

  const DetalleMedicamentoScreen({super.key, required this.medicamento});

  @override
  State<DetalleMedicamentoScreen> createState() =>
      _DetalleMedicamentoScreenState();
}

class _DetalleMedicamentoScreenState extends State<DetalleMedicamentoScreen> {
  final MedicamentoService _servicio = MedicamentoService();
  List<String> _urlsImagenes = <String>[];
  bool _cargandoImagenes = true;

  @override
  void initState() {
    super.initState();
    _cargarFotos();
  }

  Future<void> _cargarFotos() async {
    final fotos = await _servicio.obtenerImagenesMedicamento(
      widget.medicamento.setId,
    );
    if (!mounted) return;
    setState(() {
      _urlsImagenes = fotos;
      _cargandoImagenes = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medicamento;

    return Scaffold(
      appBar: AppBar(title: const MediStandLogo(subtitulo: 'Ficha Clínica')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner visual + galería de fotos del medicamento
          MedicamentoBannerVisual(
            medicamento: med,
            urlsImagenes: _urlsImagenes,
            cargandoImagenes: _cargandoImagenes,
          ),
          const SizedBox(height: 12),

          // Secciones clínicas detalladas
          _seccionInfo(
            context,
            titulo: 'Indicaciones y uso',
            contenido: med.indicaciones,
            icono: Icons.info_outline,
            color: Colors.teal,
          ),
          _seccionInfo(
            context,
            titulo: 'Dosificación y administración',
            contenido: med.dosificacion,
            icono: Icons.schedule,
            color: Colors.blue,
          ),
          _seccionInfo(
            context,
            titulo: 'Advertencias y precauciones',
            contenido: med.advertencias,
            icono: Icons.warning_amber_rounded,
            color: Colors.orange.shade800,
          ),
          _seccionInfo(
            context,
            titulo: 'Contraindicaciones',
            contenido: med.contraindicaciones,
            icono: Icons.block,
            color: Colors.red.shade700,
          ),
          _seccionInfo(
            context,
            titulo: 'Reacciones o efectos adversos',
            contenido: med.efectosAdversos,
            icono: Icons.health_and_safety_outlined,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _seccionInfo(
    BuildContext context, {
    required String titulo,
    required String contenido,
    required IconData icono,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, size: 20, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(contenido, style: const TextStyle(fontSize: 14, height: 1.45)),
          ],
        ),
      ),
    );
  }
}
