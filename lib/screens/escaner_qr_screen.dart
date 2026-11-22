import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/medicamento_service.dart';
import 'detalle_medicamento_screen.dart';

class EscanerQrScreen extends StatefulWidget {
  const EscanerQrScreen({super.key});

  @override
  State<EscanerQrScreen> createState() => _EscanerQrScreenState();
}

class _EscanerQrScreenState extends State<EscanerQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final MedicamentoService _servicio = MedicamentoService();

  bool _procesando = false;
  String? _ultimoCodigoLeido;

  // Códigos de barras comerciales reales (UPC/EAN) para probar sin cámara web
  final _codigosPrueba = const [
    {
      'titulo': 'Barras • Advil Ibuprofen (0305730164207)',
      'codigo': '0305730164207',
    },
    {
      'titulo': 'Barras • Tylenol Acetaminophen (0300450449108)',
      'codigo': '0300450449108',
    },
    {
      'titulo': 'Barras • Bayer Aspirin (0312843536362)',
      'codigo': '0312843536362',
    },
    {
      'titulo': 'QR Tótem • Betadine (MEDISTAND:Betadine)',
      'codigo': 'MEDISTAND:Betadine',
    },
  ];

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  /// Determina si el código leído por la cámara es un código de barras numérico
  /// (EAN-13 / UPC-A) o un código QR textual, y busca el medicamento en openFDA.
  Future<void> _procesarCodigoEscaneado(String rawValue) async {
    if (_procesando) return;

    final limpio = rawValue.trim();
    if (limpio.isEmpty) return;

    setState(() {
      _procesando = true;
      _ultimoCodigoLeido = limpio;
    });

    try {
      final bool esCodigoBarrasNumerico = RegExp(r'^\d{8,14}$')
          .hasMatch(limpio);

      final resultados = esCodigoBarrasNumerico
          ? await _servicio.buscarPorCodigoBarras(limpio)
          : await _servicio.obtenerMedicamentos(
              consulta: limpio.toUpperCase().startsWith('MEDISTAND:')
                  ? limpio.substring('MEDISTAND:'.length).trim()
                  : limpio,
              limite: 5,
            );

      if (!mounted) return;

      if (resultados.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DetalleMedicamentoScreen(medicamento: resultados.first),
          ),
        );
      } else if (esCodigoBarrasNumerico) {
        // Si es una caja colombiana (ej. 770...) que no está en la base de EE. UU.,
        // permitimos asociarla con el nombre impreso en la caja una sola vez.
        await _mostrarDialogoVincularCaja(limpio);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se encontró ningún medicamento para "$limpio".'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar el código: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) {
          setState(() {
            _procesando = false;
          });
        }
      }
    }
  }

  /// Abre un cuadro clínico cuando se escanea el código de barras de una caja local
  /// (como los códigos 770 de Colombia) para vincularla con su principio activo.
  Future<void> _mostrarDialogoVincularCaja(String codigoBarras) async {
    final controladorNombre = TextEditingController();

    final String? nombreIngresado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0D9488)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Código de Barras Detectado',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Código EAN/UPC: $codigoBarras',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Este código de barras comercial no está registrado en la base de EE. UU. (openFDA). Escribe el nombre o principio activo que ves en la caja para vincularlo:',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controladorNombre,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (val) => Navigator.of(ctx).pop(val.trim()),
              decoration: InputDecoration(
                labelText: 'Ej. Ibuprofeno, Acetaminofén, Loratadina',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controladorNombre.text.trim()),
            child: const Text('Vincular y Buscar'),
          ),
        ],
      ),
    );

    controladorNombre.dispose();

    if (nombreIngresado != null && nombreIngresado.isNotEmpty && mounted) {
      _servicio.vincularCodigoBarras(codigoBarras, nombreIngresado);
      final resultados = await _servicio.obtenerMedicamentos(
        consulta: nombreIngresado,
        limite: 5,
      );
      if (!mounted) return;
      if (resultados.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DetalleMedicamentoScreen(medicamento: resultados.first),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Encabezado hospitalario del escáner multifunción
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B4F6C), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B4F6C).withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.barcode_reader,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Escáner de Códigos de Barras y QR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Apunta la cámara al código de barras (EAN/UPC) de la caja del medicamento o a una etiqueta QR de Medi-Stand.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Visor de cámara con guía panorámica (ideal para códigos de barras)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFCBD5E1).withValues(alpha: 0.85),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.videocam_rounded,
                            color: Color(0xFF0D9488),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Lector Óptico en Vivo (Barras EAN/UPC y QR)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Encender / Apagar linterna',
                            icon: const Icon(
                              Icons.flashlight_on_rounded,
                              size: 20,
                            ),
                            onPressed: () => _scannerController.toggleTorch(),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            tooltip: 'Cambiar cámara',
                            icon: const Icon(
                              Icons.cameraswitch_rounded,
                              size: 20,
                            ),
                            onPressed: () => _scannerController.switchCamera(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 280,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: (BarcodeCapture capture) {
                              for (final barcode in capture.barcodes) {
                                final valor = barcode.rawValue;
                                if (valor != null && valor.isNotEmpty) {
                                  _procesarCodigoEscaneado(valor);
                                  break;
                                }
                              }
                            },
                          ),

                          // Guía rectangular horizontal adaptada a códigos de barras reales
                          Container(
                            width: 260,
                            height: 145,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF14B8A6),
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                height: 2,
                                width: 220,
                                color: Colors.redAccent.withValues(alpha: 0.75),
                              ),
                            ),
                          ),

                          if (_procesando)
                            Container(
                              color: Colors.black.withValues(alpha: 0.65),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Buscando código: $_ultimoCodigoLeido',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Alinea las barras verticales del empaque sobre la línea roja del visor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Simulador con códigos de barras reales de medicamentos comerciales
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFCBD5E1).withValues(alpha: 0.85),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.science_outlined,
                        color: Color(0xFF0B4F6C),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Simulador de Códigos de Barras Reales (Demo PC)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pulsa cualquiera de estos códigos de barras comerciales reales para probar la búsqueda automática en openFDA:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _codigosPrueba.map((item) {
                      return FilledButton.tonalIcon(
                        onPressed: _procesando
                            ? null
                            : () => _procesarCodigoEscaneado(item['codigo']!),
                        icon: const Icon(Icons.barcode_reader, size: 18),
                        label: Text(item['titulo']!),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
