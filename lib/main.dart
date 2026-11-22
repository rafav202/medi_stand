import 'package:flutter/material.dart';

import 'models/medicamento.dart';
import 'screens/consulta_medicamentos_screen.dart';
import 'screens/escaner_qr_screen.dart';
import 'screens/graficas_screen.dart';
import 'services/medicamento_service.dart';
import 'widgets/fondo_hospitalario.dart';
import 'widgets/medi_stand_logo.dart';

void main() {
  runApp(const MediStandApp());
}

class MediStandApp extends StatelessWidget {
  const MediStandApp({super.key});

  @override
  Widget build(BuildContext context) {
    const colorPrimario = Color(0xFF0D9488);

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
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white.withValues(alpha: 0.92),
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white.withValues(alpha: 0.94),
          elevation: 0,
          indicatorColor: colorPrimario.withValues(alpha: 0.16),
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

  String _obtenerSubtituloAppBar() {
    switch (_indicePestana) {
      case 0:
        return 'Unidad de Consulta Farmacológica';
      case 1:
        return 'Lectura de Códigos QR Clínicos';
      default:
        return 'Panel Estadístico Clínico';
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
      const EscanerQrScreen(),
      GraficasScreen(medicamentos: _medicamentos, cargando: _cargando),
    ];

    return FondoHospitalario(
      child: Scaffold(
        appBar: AppBar(
          title: MediStandLogo(subtitulo: _obtenerSubtituloAppBar()),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: const Color(0xFFCBD5E1).withValues(alpha: 0.7),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monitor_heart_rounded,
                    size: 15,
                    color: Color(0xFF15803D),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'API en línea',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
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
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: const Color(0xFFCBD5E1).withValues(alpha: 0.7),
                width: 1,
              ),
            ),
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
                icon: Icon(Icons.qr_code_scanner_outlined),
                selectedIcon: Icon(
                  Icons.qr_code_scanner,
                  color: Color(0xFF0D9488),
                ),
                label: 'Escanear QR',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF0D9488)),
                label: 'Gráficas',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
