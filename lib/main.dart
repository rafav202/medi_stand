import 'package:flutter/material.dart';

import 'models/medicamento.dart';
import 'screens/consulta_medicamentos_screen.dart';
import 'screens/graficas_screen.dart';
import 'services/medicamento_service.dart';
import 'widgets/medi_stand_logo.dart';

void main() {
  runApp(const MediStandApp());
}

class MediStandApp extends StatelessWidget {
  const MediStandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medi-Stand',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final MedicamentoService _servicio = MedicamentoService();

  int _indicePestana = 0;
  List<Medicamento> _medicamentos = <Medicamento>[];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarMedicamentos();
  }

  Future<void> _cargarMedicamentos([String consulta = '']) async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultados = await _servicio.obtenerMedicamentos(
        consulta: consulta,
        limite: 20,
      );
      if (!mounted) return;
      setState(() {
        _medicamentos = resultados;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los datos.\nDetalle: $e';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pantallas = <Widget>[
      ConsultaMedicamentosScreen(
        medicamentos: _medicamentos,
        cargando: _cargando,
        error: _error,
        onBuscar: _cargarMedicamentos,
      ),
      GraficasScreen(medicamentos: _medicamentos, cargando: _cargando),
    ];

    return Scaffold(
      appBar: AppBar(
        title: MediStandLogo(
          subtitulo: _indicePestana == 0
              ? 'Consulta Farmacológica'
              : 'Estadísticas y Gráficas',
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar datos',
            icon: const Icon(Icons.refresh),
            onPressed: () => _cargarMedicamentos(),
          ),
        ],
      ),
      body: pantallas[_indicePestana],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indicePestana,
        onDestinationSelected: (nuevoIndice) {
          setState(() {
            _indicePestana = nuevoIndice;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.medical_information_outlined),
            selectedIcon: Icon(Icons.medical_information),
            label: 'Medicamentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Gráficas',
          ),
        ],
      ),
    );
  }
}
