import 'package:flutter/material.dart';

import '../models/medicamento.dart';

class DetalleMedicamentoScreen extends StatelessWidget {
  final Medicamento medicamento;

  const DetalleMedicamentoScreen({super.key, required this.medicamento});

  @override
  Widget build(BuildContext context) {
    final esquemaColor = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ficha del Medicamento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjeta principal de identificación
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: esquemaColor.primaryContainer,
                        child: Icon(
                          Icons.medication,
                          color: esquemaColor.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          medicamento.nombre,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _filaDato('Principio activo', medicamento.principioActivo),
                  _filaDato(
                    'Vía de administración',
                    medicamento.viaAdministracion,
                  ),
                  _filaDato(
                    'Forma farmacéutica',
                    medicamento.formaFarmaceutica,
                  ),
                  _filaDato('Fabricante / Titular', medicamento.fabricante),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Secciones clínicas detalladas para el estudiante
          _seccionInfo(
            context,
            titulo: 'Indicaciones y uso',
            contenido: medicamento.indicaciones,
            icono: Icons.info_outline,
          ),
          _seccionInfo(
            context,
            titulo: 'Dosificación y administración',
            contenido: medicamento.dosificacion,
            icono: Icons.schedule,
          ),
          _seccionInfo(
            context,
            titulo: 'Advertencias y precauciones',
            contenido: medicamento.advertencias,
            icono: Icons.warning_amber_rounded,
          ),
          _seccionInfo(
            context,
            titulo: 'Contraindicaciones',
            contenido: medicamento.contraindicaciones,
            icono: Icons.block,
          ),
          _seccionInfo(
            context,
            titulo: 'Reacciones o efectos adversos',
            contenido: medicamento.efectosAdversos,
            icono: Icons.health_and_safety_outlined,
          ),
        ],
      ),
    );
  }

  Widget _filaDato(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$etiqueta: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }

  Widget _seccionInfo(
    BuildContext context, {
    required String titulo,
    required String contenido,
    required IconData icono,
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
                Icon(
                  icono,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 8),
            Text(contenido, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
