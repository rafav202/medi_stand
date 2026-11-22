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
    const colorPrimario = Color(0xFF0D9488); // Verde azulado clínico moderno
    const colorFondo = Color(0xFFF4F7F9); // Gris hielo muy suave para el fondo

    return MaterialApp(
      title: 'Medi-Stand',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorPrimario,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: colorFondo,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: colorPrimario.withValues(alpha: 0.14),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorPrimario,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            );
          }),
        ),
      ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              tooltip: 'Actualizar datos de la API',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _cargarMedicamentos(),
            ),
          ),
        ],
      ),
      body: pantallas[_indicePestana],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: NavigationBar(
          height: 68,
          selectedIndex: _indicePestana,
          onDestinationSelected: (nuevoIndice) {
            setState(() {
              _indicePestana = nuevoIndice;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.medical_information_outlined),
              selectedIcon: Icon(
                Icons.medical_information,
                color: Color(0xFF0D9488),
              ),
              label: 'Medicamentos',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF0D9488)),
              label: 'Gráficas',
            ),
          ],
        ),
      ),
    );
  }
}
