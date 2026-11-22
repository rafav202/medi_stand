import 'dart:async';

import 'package:flutter/material.dart';

import '../models/medicamento.dart';
import '../widgets/medicamento_visual.dart';
import 'detalle_medicamento_screen.dart';

class ConsultaMedicamentosScreen extends StatefulWidget {
  final List<Medicamento> medicamentos;
  final bool cargando;
  final bool cargandoMas;
  final bool hayMasResultados;
  final String? error;
  final Future<void> Function(String consulta) onBuscar;
  final Future<void> Function() onCargarMas;

  const ConsultaMedicamentosScreen({
    super.key,
    required this.medicamentos,
    required this.cargando,
    required this.cargandoMas,
    required this.hayMasResultados,
    required this.error,
    required this.onBuscar,
    required this.onCargarMas,
  });

  @override
  State<ConsultaMedicamentosScreen> createState() =>
      _ConsultaMedicamentosScreenState();
}

class _ConsultaMedicamentosScreenState
    extends State<ConsultaMedicamentosScreen> {
  final TextEditingController _controladorBusqueda = TextEditingController();
  Timer? _debounceTimer;
  String _ultimaBusquedaEnviada = '';
  String _viaSeleccionada = 'TODAS';

  final List<String> _sugerencias = const [
    'Todos',
    'Ibuprofeno',
    'Amoxicilina',
    'Acetaminofén',
    'Aspirina',
    'Omeprazol',
  ];

  @override
  void didUpdateWidget(covariant ConsultaMedicamentosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.medicamentos != widget.medicamentos &&
        !widget.cargandoMas &&
        oldWidget.medicamentos.length != widget.medicamentos.length) {
      // Mantiene la vía seleccionada si se cargaron más páginas,
      // pero la reinicia a 'TODAS' si cambió la búsqueda principal.
      if (widget.medicamentos.length <= 100) {
        _viaSeleccionada = 'TODAS';
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controladorBusqueda.dispose();
    super.dispose();
  }

  void _alCambiarTexto(String valor) {
    setState(() {});
    _debounceTimer?.cancel();

    final textoLimpio = valor.trim();
    final espera = textoLimpio.isEmpty
        ? const Duration(milliseconds: 350)
        : const Duration(milliseconds: 550);

    _debounceTimer = Timer(espera, () {
      if (!mounted) return;
      if (textoLimpio != _ultimaBusquedaEnviada) {
        _ultimaBusquedaEnviada = textoLimpio;
        _viaSeleccionada = 'TODAS';
        widget.onBuscar(textoLimpio);
      }
    });
  }

  void _ejecutarBusquedaInmediata([String? termino]) {
    _debounceTimer?.cancel();
    _viaSeleccionada = 'TODAS';

    if (termino == 'Todos') {
      _controladorBusqueda.clear();
      setState(() {});
      _ultimaBusquedaEnviada = '';
      widget.onBuscar('');
      return;
    }

    final texto = (termino ?? _controladorBusqueda.text).trim();
    if (termino != null) {
      _controladorBusqueda.text = termino;
      setState(() {});
    }

    _ultimaBusquedaEnviada = texto;
    widget.onBuscar(texto);
  }

  List<String> _obtenerViasDisponibles() {
    final vias = <String>{'TODAS'};
    for (final med in widget.medicamentos) {
      vias.add(med.viaPrincipalCorta);
    }
    return vias.toList();
  }

  List<Medicamento> _filtrarMedicamentos() {
    if (_viaSeleccionada == 'TODAS') {
      return widget.medicamentos;
    }
    return widget.medicamentos
        .where((med) => med.viaPrincipalCorta == _viaSeleccionada)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final viasDisponibles = _obtenerViasDisponibles();
    final medicamentosFiltrados = _filtrarMedicamentos();

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final int columnas = ancho >= 1050 ? 3 : (ancho >= 680 ? 2 : 1);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: Column(
              children: [
                // 1. Cabecera Hero Hospitalaria
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0B4F6C),
                        Color(0xFF0F766E),
                        Color(0xFF0D9488),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B4F6C).withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(painter: _BannerEcgPainter()),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.28,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_hospital_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Estación Farmacéutica Hospitalaria • openFDA',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!widget.cargando &&
                                    widget.medicamentos.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${widget.medicamentos.length} medicamentos cargados',
                                      style: const TextStyle(
                                        color: Color(0xFF0B4F6C),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Consulta clínica y vademécum estudiantil',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Catálogo ampliado hasta 100 registros por carga desde openFDA con paginación continua.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Barra de búsqueda
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _controladorBusqueda,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) =>
                                    _ejecutarBusquedaInmediata(),
                                onChanged: _alCambiarTexto,
                                decoration: InputDecoration(
                                  hintText: 'Ej. Ibuprofeno, Amoxicilina, Acetaminofén...',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: Color(0xFF0D9488),
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_controladorBusqueda.text.isNotEmpty)
                                        IconButton(
                                          tooltip: 'Limpiar búsqueda',
                                          icon: const Icon(Icons.close_rounded),
                                          onPressed: () =>
                                              _ejecutarBusquedaInmediata(
                                                'Todos',
                                              ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6,
                                        ),
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF0F172A,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                          ),
                                          onPressed: _ejecutarBusquedaInmediata,
                                          child: const Text('Buscar'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Botones rápidos personalizados
                            SizedBox(
                              height: 36,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _sugerencias.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final nombre = _sugerencias[index];
                                  final esTodos = nombre == 'Todos';

                                  return Material(
                                    color: esTodos
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () =>
                                          _ejecutarBusquedaInmediata(nombre),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.45,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              esTodos
                                                  ? Icons.apps_rounded
                                                  : Icons.bolt_rounded,
                                              size: 15,
                                              color: esTodos
                                                  ? const Color(0xFF0B4F6C)
                                                  : Colors.white,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              nombre,
                                              style: TextStyle(
                                                color: esTodos
                                                    ? const Color(0xFF0B4F6C)
                                                    : Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
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
                    ],
                  ),
                ),

                // 2. Barra de filtros por vía de administración
                if (!widget.cargando &&
                    widget.error == null &&
                    widget.medicamentos.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                    child: SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: viasDisponibles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final via = viasDisponibles[index];
                          final seleccionado = _viaSeleccionada == via;
                          final cantidad = via == 'TODAS'
                              ? widget.medicamentos.length
                              : widget.medicamentos
                                    .where((m) => m.viaPrincipalCorta == via)
                                    .length;
                          final etiqueta = via == 'TODAS'
                              ? 'Todas ($cantidad)'
                              : '$via ($cantidad)';

                          return ChoiceChip(
                            label: Text(etiqueta),
                            selected: seleccionado,
                            showCheckmark: false,
                            selectedColor: const Color(0xFF0B4F6C),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.92,
                            ),
                            side: BorderSide(
                              color: seleccionado
                                  ? const Color(0xFF0B4F6C)
                                  : const Color(0xFFCBD5E1),
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: seleccionado
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                            onSelected: (_) {
                              setState(() {
                                _viaSeleccionada = via;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // 3. Cuadrícula de tarjetas + botón "Cargar más" al final
                Expanded(
                  child: _construirCuerpo(medicamentosFiltrados, columnas),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _construirCuerpo(List<Medicamento> listaMostrar, int columnas) {
    if (widget.cargando) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'Descargando catálogo de medicamentos desde openFDA...',
              style: TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF334155)),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _ejecutarBusquedaInmediata(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (listaMostrar.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No se encontraron medicamentos con ese filtro o término.\nPrueba con otro nombre como Ibuprofeno o pulsa "Todos".',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final int totalFilas = (listaMostrar.length / columnas).ceil();
    final bool mostrarPiePaginacion =
        _viaSeleccionada == 'TODAS' && widget.hayMasResultados;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: totalFilas + (mostrarPiePaginacion ? 1 : 0),
      itemBuilder: (context, filaIndex) {
        if (mostrarPiePaginacion && filaIndex == totalFilas) {
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 16),
            child: Center(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4F6C),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: widget.cargandoMas ? null : widget.onCargarMas,
                icon: widget.cargandoMas
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_circle_outline_rounded),
                label: Text(
                  widget.cargandoMas
                      ? 'Cargando siguientes 100 medicamentos...'
                      : 'Cargar 100 medicamentos más (${widget.medicamentos.length} actuales)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(columnas, (colIndex) {
              final itemIndex = filaIndex * columnas + colIndex;
              if (itemIndex >= listaMostrar.length) {
                return const Expanded(child: SizedBox.shrink());
              }
              final med = listaMostrar[itemIndex];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: colIndex < columnas - 1 ? 12 : 0,
                  ),
                  child: _tarjetaMedicamentoModerna(context, med),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _tarjetaMedicamentoModerna(BuildContext context, Medicamento med) {
    final estiloVia = EstiloViaMedicamento.obtener(med.viaPrincipalCorta);

    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetalleMedicamentoScreen(medicamento: med),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFCBD5E1).withValues(alpha: 0.85),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MedicamentoAvatar(medicamento: med, radio: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          med.principioActivo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: Color(0xFF0B4F6C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _etiquetaMini(
                    texto: med.viaPrincipalCorta,
                    color: estiloVia.color,
                  ),
                  _etiquetaMini(
                    texto: med.tipoDispensacionEspanol,
                    color: med.esVentaLibre
                        ? const Color(0xFF059669)
                        : const Color(0xFF6D28D9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _etiquetaMini({required String texto, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _BannerEcgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final double y = size.height * 0.28;
    final double inicioX = size.width * 0.45;

    path.moveTo(inicioX, y);
    path.lineTo(inicioX + 60, y);
    path.lineTo(inicioX + 72, y - 10);
    path.lineTo(inicioX + 82, y + 12);
    path.lineTo(inicioX + 94, y - 34);
    path.lineTo(inicioX + 106, y + 20);
    path.lineTo(inicioX + 116, y);
    path.lineTo(inicioX + 145, y);
    path.quadraticBezierTo(inicioX + 160, y - 14, inicioX + 175, y);
    path.lineTo(size.width, y);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
