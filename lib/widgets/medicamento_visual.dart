import 'package:flutter/material.dart';

import '../models/medicamento.dart';

/// Devuelve un color e ícono representativo según la vía de administración.
class EstiloViaMedicamento {
  final Color color;
  final IconData icono;
  final String descripcionVisual;

  const EstiloViaMedicamento({
    required this.color,
    required this.icono,
    required this.descripcionVisual,
  });

  static EstiloViaMedicamento obtener(String via) {
    final v = via.toUpperCase();
    if (v.contains('ORAL')) {
      return const EstiloViaMedicamento(
        color: Colors.teal,
        icono: Icons.medication_rounded,
        descripcionVisual: 'Administración Oral',
      );
    }
    if (v.contains('TOPICAL')) {
      return const EstiloViaMedicamento(
        color: Colors.blue,
        icono: Icons.healing_rounded,
        descripcionVisual: 'Aplicación Tópica / Cutánea',
      );
    }
    if (v.contains('OPHTHALMIC')) {
      return const EstiloViaMedicamento(
        color: Colors.indigo,
        icono: Icons.visibility_rounded,
        descripcionVisual: 'Uso Oftálmico (Gotas)',
      );
    }
    if (v.contains('INTRAVENOUS') ||
        v.contains('INJECTION') ||
        v.contains('SUBCUTANEOUS')) {
      return const EstiloViaMedicamento(
        color: Colors.deepOrange,
        icono: Icons.vaccines_rounded,
        descripcionVisual: 'Vía Parenteral / Inyectable',
      );
    }
    if (v.contains('NASAL') ||
        v.contains('RESPIRATORY') ||
        v.contains('INHALATION')) {
      return const EstiloViaMedicamento(
        color: Colors.cyan,
        icono: Icons.air_rounded,
        descripcionVisual: 'Vía Respiratoria / Nasal',
      );
    }
    return const EstiloViaMedicamento(
      color: Colors.blueGrey,
      icono: Icons.medical_services_rounded,
      descripcionVisual: 'Uso Farmacéutico General',
    );
  }
}

/// Avatar colorido con ícono farmacéutico para las tarjetas de la lista.
class MedicamentoAvatar extends StatelessWidget {
  final Medicamento medicamento;
  final double radio;

  const MedicamentoAvatar({
    super.key,
    required this.medicamento,
    this.radio = 24,
  });

  @override
  Widget build(BuildContext context) {
    final estilo = EstiloViaMedicamento.obtener(medicamento.viaPrincipalCorta);

    return Container(
      width: radio * 2,
      height: radio * 2,
      decoration: BoxDecoration(
        color: estilo.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: estilo.color.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Icon(estilo.icono, color: estilo.color, size: radio * 1.05),
    );
  }
}

/// Banner visual para la pantalla de detalle con fotos reales de DailyMed
/// y respaldo ilustrado si no hay imagen disponible.
class MedicamentoBannerVisual extends StatelessWidget {
  final Medicamento medicamento;
  final List<String> urlsImagenes;
  final bool cargandoImagenes;

  const MedicamentoBannerVisual({
    super.key,
    required this.medicamento,
    required this.urlsImagenes,
    required this.cargandoImagenes,
  });

  void _abrirFotoCompleta(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No se pudo cargar la imagen ampliada.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estilo = EstiloViaMedicamento.obtener(medicamento.viaPrincipalCorta);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado ilustrado con degradado según la vía
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [estilo.color, estilo.color.withValues(alpha: 0.72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(estilo.icono, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicamento.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estilo.descripcionVisual,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Galería de fotos reales del medicamento (si DailyMed tiene disponibles)
          if (cargandoImagenes)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Buscando imágenes oficiales del empaque...',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            )
          else if (urlsImagenes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.photo_library_outlined, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Imágenes de referencia (toca para ampliar)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: urlsImagenes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final url = urlsImagenes[index];
                        return GestureDetector(
                          onTap: () => _abrirFotoCompleta(context, url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 130,
                              color: Colors.grey.shade100,
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(
                                    estilo.icono,
                                    color: estilo.color,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Ficha técnica resumida
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _filaDato('Principio activo', medicamento.principioActivo),
                _filaDato(
                  'Vía de administración',
                  medicamento.viaAdministracion,
                ),
                _filaDato('Tipo de producto', medicamento.formaFarmaceutica),
                _filaDato('Fabricante / Titular', medicamento.fabricante),
              ],
            ),
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
}
