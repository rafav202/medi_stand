import 'package:flutter/material.dart';

import '../models/medicamento.dart';
import '../widgets/medicamento_visual.dart';
import 'detalle_medicamento_screen.dart';

class ConsultaMedicamentosScreen extends StatefulWidget {
  final List<Medicamento> medicamentos;
  final bool cargando;
  final String? error;
  final Future<void> Function(String consulta) onBuscar;

  const ConsultaMedicamentosScreen({
    super.key,
    required this.medicamentos,
    required this.cargando,
    required this.error,
    required this.onBuscar,
  });

  @override
  State<ConsultaMedicamentosScreen> createState() =>
      _ConsultaMedicamentosScreenState();
}

class _ConsultaMedicamentosScreenState
    extends State<ConsultaMedicamentosScreen> {
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _viaSeleccionada = 'TODAS';

  final List<String> _sugerencias = const [
    'Ibuprofen',
    'Amoxicillin',
    'Acetaminophen',
    'Aspirin',
    'Omeprazole',
  ];

  @override
  void didUpdateWidget(covariant ConsultaMedicamentosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.medicamentos != widget.medicamentos) {
      _viaSeleccionada = 'TODAS';
    }
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  void _ejecutarBusqueda([String? termino]) {
    final texto = termino ?? _controladorBusqueda.text;
    if (termino != null) {
      _controladorBusqueda.text = termino;
    }
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _controladorBusqueda,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _ejecutarBusqueda(),
            decoration: InputDecoration(
              labelText: 'Buscar medicamento (ej. Ibuprofen, Aspirin)',
              hintText: 'Nombre comercial o principio activo...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_controladorBusqueda.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Limpiar',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controladorBusqueda.clear();
                        setState(() {});
                        _ejecutarBusqueda('');
                      },
                    ),
                  IconButton(
                    tooltip: 'Buscar',
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _ejecutarBusqueda,
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _sugerencias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final nombre = _sugerencias[index];
              return ActionChip(
                avatar: const Icon(Icons.bolt, size: 16),
                label: Text(nombre),
                onPressed: () => _ejecutarBusqueda(nombre),
              );
            },
          ),
        ),
        if (!widget.cargando &&
            widget.error == null &&
            widget.medicamentos.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: viasDisponibles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final via = viasDisponibles[index];
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
                  selected: _viaSeleccionada == via,
                  onSelected: (_) {
                    setState(() {
                      _viaSeleccionada = via;
                    });
                  },
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 8),
        Expanded(child: _construirCuerpo(medicamentosFiltrados)),
      ],
    );
  }

  Widget _construirCuerpo(List<Medicamento> listaMostrar) {
    if (widget.cargando) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Consultando medicamentos en openFDA...'),
          ],
        ),
      );
    }

    if (widget.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(widget.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _ejecutarBusqueda(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (listaMostrar.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No se encontraron medicamentos con ese filtro o término.\nPrueba con otro nombre como Ibuprofen o selecciona "Todas".',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: listaMostrar.length,
      itemBuilder: (context, index) {
        final med = listaMostrar[index];
        final estiloVia = EstiloViaMedicamento.obtener(med.viaPrincipalCorta);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: MedicamentoAvatar(medicamento: med),
            title: Text(
              med.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Principio activo: ${med.principioActivo}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _etiquetaMini(
                      texto: med.viaPrincipalCorta,
                      color: estiloVia.color,
                    ),
                    _etiquetaMini(
                      texto: med.esVentaLibre
                          ? 'Venta Libre (OTC)'
                          : 'Fórmula Médica',
                      color: med.esVentaLibre
                          ? Colors.green.shade700
                          : Colors.deepPurple,
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetalleMedicamentoScreen(medicamento: med),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _etiquetaMini({required String texto, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
