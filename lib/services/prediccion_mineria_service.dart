import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class PuntoGraficaMineria {
  final int mesNumero;
  final String etiqueta;
  final String medicamento;
  final double? unidadesReales;
  final double? consultasReales;
  final double? unidadesPredichas;
  final double? consultasPredichas;
  final String tipo; // "historico" o "prediccion"

  PuntoGraficaMineria({
    required this.mesNumero,
    required this.etiqueta,
    required this.medicamento,
    this.unidadesReales,
    this.consultasReales,
    this.unidadesPredichas,
    this.consultasPredichas,
    required this.tipo,
  });

  factory PuntoGraficaMineria.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    return PuntoGraficaMineria(
      mesNumero: (json['mes_numero'] as num?)?.toInt() ?? 0,
      etiqueta: json['etiqueta']?.toString() ?? '',
      medicamento: json['medicamento']?.toString() ?? '',
      unidadesReales: toDouble(json['unidades_reales']),
      consultasReales: toDouble(json['consultas_reales']),
      unidadesPredichas: toDouble(json['unidades_predichas']),
      consultasPredichas: toDouble(json['consultas_predichas']),
      tipo: json['tipo']?.toString() ?? 'historico',
    );
  }
}

class RespuestaPrediccionMineria {
  final String fuente;
  final String algoritmo;
  final double r2Precision;
  final double errorMae;
  final int registrosEntrenamiento;
  final List<PuntoGraficaMineria> historicos;
  final List<PuntoGraficaMineria> predicciones;

  RespuestaPrediccionMineria({
    required this.fuente,
    required this.algoritmo,
    required this.r2Precision,
    required this.errorMae,
    required this.registrosEntrenamiento,
    required this.historicos,
    required this.predicciones,
  });

  factory RespuestaPrediccionMineria.fromJson(Map<String, dynamic> json) {
    final metricas = (json['metricas'] as Map<String, dynamic>?) ?? {};
    final datosGrafica = (json['datos_grafica'] as Map<String, dynamic>?) ?? {};

    final histRaw = (datosGrafica['historicos'] as List<dynamic>?) ?? [];
    final predRaw = (datosGrafica['predicciones'] as List<dynamic>?) ?? [];

    return RespuestaPrediccionMineria(
      fuente: json['fuente']?.toString() ?? 'MySQL Workbench',
      algoritmo: json['algoritmo']?.toString() ?? 'Regresión Lineal Múltiple',
      r2Precision: (metricas['r2_precision'] as num?)?.toDouble() ?? 0.0,
      errorMae:
          (metricas['error_medio_absoluto_mae'] as num?)?.toDouble() ?? 0.0,
      registrosEntrenamiento:
          (metricas['registros_entrenamiento'] as num?)?.toInt() ?? 0,
      historicos: histRaw
          .map(
            (item) => PuntoGraficaMineria.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      predicciones: predRaw
          .map(
            (item) => PuntoGraficaMineria.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class PrediccionMineriaService {
  /// URL pública activa de tu túnel de Cloudflare
  static const String urlBasePorDefecto =
      'https://bunch-borders-eng-goal.trycloudflare.com';

  Future<RespuestaPrediccionMineria> obtenerPrediccion({
    int meses = 6,
    String? urlPersonalizada,
  }) async {
    final base = (urlPersonalizada ?? urlBasePorDefecto).trim();
    if (base.isEmpty) {
      throw Exception('Ingresa una URL válida del túnel de Cloudflare.');
    }

    final limpia = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final uri = Uri.parse('$limpia/api/graficas/prediccion')
        .replace(queryParameters: {'meses': meses.toString()});

    try {
      final respuesta = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(respuesta.body) as Map<String, dynamic>;
        return RespuestaPrediccionMineria.fromJson(data);
      } else {
        throw Exception(
          'El servidor de Minería respondió con código HTTP ${respuesta.statusCode}.',
        );
      }
    } on TimeoutException {
      throw Exception(
        'Tiempo de espera agotado. Verifica que uvicorn y el túnel de Cloudflare sigan activos.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('No se pudo conectar con la API de Minería: $e');
    }
  }
}
