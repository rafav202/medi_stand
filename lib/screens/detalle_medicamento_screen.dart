import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  bool _traduciendo = true;
  bool _mostrarEnEspanol = true;

  late String _indicacionesEs;
  late String _dosificacionEs;
  late String _advertenciasEs;
  late String _contraindicacionesEs;
  late String _efectosAdversosEs;

  @override
  void initState() {
    super.initState();
    final med = widget.medicamento;
    _indicacionesEs = med.indicaciones;
    _dosificacionEs = med.dosificacion;
    _advertenciasEs = med.advertencias;
    _contraindicacionesEs = med.contraindicaciones;
    _efectosAdversosEs = med.efectosAdversos;

    _cargarFotos();
    _traducirFichaAlEspanol();
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

  Future<void> _traducirFichaAlEspanol() async {
    final med = widget.medicamento;

    // Traducimos las 5 secciones clínicas en paralelo para máxima velocidad
    final resultados = await Future.wait<String>([
      _servicio.traducirTexto(med.indicaciones),
      _servicio.traducirTexto(med.dosificacion),
      _servicio.traducirTexto(med.advertencias),
      _servicio.traducirTexto(med.contraindicaciones),
      _servicio.traducirTexto(med.efectosAdversos),
    ]);

    if (!mounted) return;
    setState(() {
      _indicacionesEs = resultados[0];
      _dosificacionEs = resultados[1];
      _advertenciasEs = resultados[2];
      _contraindicacionesEs = resultados[3];
      _efectosAdversosEs = resultados[4];
      _traduciendo = false;
    });
  }

  void _copiarTexto(String titulo, String contenido) {
    Clipboard.setData(
      ClipboardData(
        text: '${widget.medicamento.nombre} - $titulo:\n$contenido',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sección "$titulo" copiada al portapapeles'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medicamento;

    return Scaffold(
      appBar: AppBar(
        title: const MediStandLogo(subtitulo: 'Ficha Clínica'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: _traduciendo
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.translate_rounded, size: 16),
              label: Text(
                _traduciendo
                    ? 'Traduciendo...'
                    : (_mostrarEnEspanol ? 'Español' : 'Inglés (Original)'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: _traduciendo
                  ? null
                  : () {
                      setState(() {
                        _mostrarEnEspanol = !_mostrarEnEspanol;
                      });
                    },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banner visual + galería de fotos del medicamento
              MedicamentoBannerVisual(
                medicamento: med,
                urlsImagenes: _urlsImagenes,
                cargandoImagenes: _cargandoImagenes,
              ),
              const SizedBox(height: 14),

              // Secciones clínicas detalladas en español (con opción de ver original)
              _seccionInfo(
                context,
                titulo: 'Indicaciones y uso',
                contenido: _mostrarEnEspanol
                    ? _indicacionesEs
                    : med.indicaciones,
                icono: Icons.info_outline_rounded,
                color: const Color(0xFF0D9488),
              ),
              _seccionInfo(
                context,
                titulo: 'Dosificación y administración',
                contenido: _mostrarEnEspanol
                    ? _dosificacionEs
                    : med.dosificacion,
                icono: Icons.schedule_rounded,
                color: const Color(0xFF2563EB),
              ),
              _seccionInfo(
                context,
                titulo: 'Advertencias y precauciones',
                contenido: _mostrarEnEspanol
                    ? _advertenciasEs
                    : med.advertencias,
                icono: Icons.warning_amber_rounded,
                color: const Color(0xFFD97706),
              ),
              _seccionInfo(
                context,
                titulo: 'Contraindicaciones',
                contenido: _mostrarEnEspanol
                    ? _contraindicacionesEs
                    : med.contraindicaciones,
                icono: Icons.block_rounded,
                color: const Color(0xFFDC2626),
              ),
              _seccionInfo(
                context,
                titulo: 'Reacciones o efectos adversos',
                contenido: _mostrarEnEspanol
                    ? _efectosAdversosEs
                    : med.efectosAdversos,
                icono: Icons.health_and_safety_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
        ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copiar sección',
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                onPressed: () => _copiarTexto(titulo, contenido),
              ),
            ],
          ),
          const Divider(height: 22, color: Color(0xFFF1F5F9)),
          Text(
            contenido,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
