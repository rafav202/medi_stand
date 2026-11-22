import 'package:flutter/material.dart';

import '../models/medicamento.dart';
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

  // Guarda qué vía de administración está seleccionada en el filtro local.
  String _viaSeleccionada = 'TODAS';

  // Sugerencias rápidas para probar búsquedas en openFDA.
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
    // Si llega una nueva lista desde la API, reiniciamos el filtro a TODAS
    // para que el estudiante vea todos los resultados nuevos sin ocultar nada.
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

  /// Extrae dinámicamente las vías únicas presentes en los medicamentos cargados.
  List<String> _obtenerViasDisponibles() {
    final vias = <String>{'TODAS'};
    for (final med in widget.medicamentos) {
      vias.add(med.viaPrincipalCorta);
    }
    return vias.toList();
  }

  /// Filtra la lista en memoria según el ChoiceChip seleccionado.
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
        // 1. Barra de búsqueda por texto
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

        // 2. Chips de búsqueda rápida en la API
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
                label: Text(nombre),
                onPressed: () => _ejecutarBusqueda(nombre),
              );
            },
          ),
        ),

        // 3. Filtro local por vía de administración (se muestra cuando hay datos)
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

        // 4. Lista de resultados filtrados
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
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              child: Text(
                med.nombre.isNotEmpty ? med.nombre[0].toUpperCase() : 'M',
              ),
            ),
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
                Text(
                  'Vía: ${med.viaPrincipalCorta} •${med.formaFarmaceutica}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
}
