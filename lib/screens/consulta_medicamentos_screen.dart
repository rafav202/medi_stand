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

  // Sugerencias rápidas en inglés porque openFDA indexa nombres en inglés.
  final List<String> _sugerencias = const [
    'Ibuprofen',
    'Amoxicillin',
    'Acetaminophen',
    'Aspirin',
    'Omeprazole',
  ];

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda
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

        // Chips de búsqueda rápida para facilitar pruebas
        SizedBox(
          height: 44,
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
        const SizedBox(height: 8),

        // Contenido dinámico: cargando, error, vacío o lista de resultados
        Expanded(child: _construirCuerpo()),
      ],
    );
  }

  Widget _construirCuerpo() {
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

    if (widget.medicamentos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No se encontraron medicamentos con ese término.\nPrueba con otro nombre como Ibuprofen o Amoxicillin.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: widget.medicamentos.length,
      itemBuilder: (context, index) {
        final med = widget.medicamentos[index];
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
                  'Vía: ${med.viaPrincipalCorta} • ${med.formaFarmaceutica}',
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
