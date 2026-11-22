import 'package:flutter/material.dart';

class MediStandLogo extends StatelessWidget {
  final String subtitulo;

  const MediStandLogo({super.key, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emblema visual de Medi-Stand (escudo con degradado + cruz médica)
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [esquema.primary, Colors.teal.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: esquema.primary.withValues(alpha: 0.28),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 22),
              Positioned(
                right: 4,
                bottom: 4,
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: Colors.amberAccent,
                  child: Icon(Icons.add, size: 8, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Nombre de la marca + etiqueta de sección actual
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Medi',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: esquema.primary,
                    letterSpacing: -0.4,
                  ),
                ),
                const Text(
                  '-Stand',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            Text(
              subtitulo,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: esquema.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
