import 'package:flutter/material.dart';

/// Fondo con estética hospitalaria: degradado clínico, halos de luz suave,
/// cuadrícula médica, onda de electrocardiograma (ECG) y cruces farmacéuticas.
class FondoHospitalario extends StatelessWidget {
  final Widget child;

  const FondoHospitalario({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Capa base: degradado clínico luminoso (verde menta -> blanco -> azul cielo)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFE0F2FE), // Azul hospitalario muy suave arriba
                Color(0xFFF4F9F9), // Blanco clínico en el centro
                Color(0xFFDDF3EE), // Verde agua quirúrgico suave abajo
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // 2. Halo de luz ambiental superior derecho (color monitor clínico)
        Positioned(
          top: -90,
          right: -70,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0D9488).withValues(alpha: 0.16),
                  const Color(0xFF0D9488).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // 3. Halo de luz ambiental inferior izquierdo (azul médico)
        Positioned(
          bottom: -110,
          left: -80,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF0284C7).withValues(alpha: 0.14),
                  const Color(0xFF0284C7).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // 4. Capa vectorial: cuadrícula de historia clínica, onda ECG y cruces médicas
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _HospitalAmbientPainter()),
          ),
        ),

        // 5. Contenido real de la pantalla encima del fondo
        child,
      ],
    );
  }
}

class _HospitalAmbientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // A. Cuadrícula sutil estilo papel de electrocardiograma / hoja clínica
    final gridPaint = Paint()
      ..color = const Color(0xFF0D9488).withValues(alpha: 0.045)
      ..strokeWidth = 1.0;

    const double pasoCuadricula = 36.0;
    for (double x = 0; x < size.width; x += pasoCuadricula) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += pasoCuadricula) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // B. Onda de electrocardiograma (ECG) cruzando suavemente a media altura
    final ecgPaint = Paint()
      ..color = const Color(0xFF0D9488).withValues(alpha: 0.11)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final ecgPath = Path();
    final double baseY = size.height * 0.52;
    ecgPath.moveTo(0, baseY);

    double currentX = 0;
    const double cicloAncho = 260.0;

    while (currentX < size.width + cicloAncho) {
      // Línea base inicial
      ecgPath.lineTo(currentX + 70, baseY);
      // Onda P (pequeña elevación)
      ecgPath.quadraticBezierTo(
        currentX + 82,
        baseY - 12,
        currentX + 94,
        baseY,
      );
      ecgPath.lineTo(currentX + 110, baseY);
      // Complejo QRS (pico pronunciado de latido)
      ecgPath.lineTo(currentX + 118, baseY + 14);
      ecgPath.lineTo(currentX + 130, baseY - 58);
      ecgPath.lineTo(currentX + 142, baseY + 26);
      ecgPath.lineTo(currentX + 150, baseY);
      // Segmento ST y onda T
      ecgPath.lineTo(currentX + 170, baseY);
      ecgPath.quadraticBezierTo(
        currentX + 188,
        baseY - 20,
        currentX + 206,
        baseY,
      );
      ecgPath.lineTo(currentX + cicloAncho, baseY);

      currentX += cicloAncho;
    }
    canvas.drawPath(ecgPath, ecgPaint);

    // C. Cruces médicas sutiles en posiciones estratégicas
    final cruzPaint = Paint()
      ..color = const Color(0xFF0F766E).withValues(alpha: 0.065)
      ..style = PaintingStyle.fill;

    _dibujarCruzMedica(
      canvas,
      centro: Offset(size.width * 0.10, size.height * 0.24),
      tamano: 44,
      paint: cruzPaint,
    );
    _dibujarCruzMedica(
      canvas,
      centro: Offset(size.width * 0.88, size.height * 0.30),
      tamano: 56,
      paint: cruzPaint,
    );
    _dibujarCruzMedica(
      canvas,
      centro: Offset(size.width * 0.16, size.height * 0.78),
      tamano: 50,
      paint: cruzPaint,
    );
    _dibujarCruzMedica(
      canvas,
      centro: Offset(size.width * 0.85, size.height * 0.82),
      tamano: 42,
      paint: cruzPaint,
    );
  }

  void _dibujarCruzMedica(
    Canvas canvas, {
    required Offset centro,
    required double tamano,
    required Paint paint,
  }) {
    final double grosor = tamano * 0.34;
    final double mitad = tamano / 2;
    final double mitadGrosor = grosor / 2;

    // Barra vertical redondeada
    final vertical = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        centro.dx - mitadGrosor,
        centro.dy - mitad,
        centro.dx + mitadGrosor,
        centro.dy + mitad,
      ),
      const Radius.circular(6),
    );

    // Barra horizontal redondeada
    final horizontal = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        centro.dx - mitad,
        centro.dy - mitadGrosor,
        centro.dx + mitad,
        centro.dy + mitadGrosor,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(vertical, paint);
    canvas.drawRRect(horizontal, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
