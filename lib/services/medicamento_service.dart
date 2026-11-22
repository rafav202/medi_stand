import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/medicamento.dart';

class MedicamentoService {
  static const String _baseUrl = 'https://api.fda.gov/drug/label.json';
  static const String _dailyMedBaseUrl =
      'https://dailymed.nlm.nih.gov/dailymed/services/v2/spls';

  /// Consulta la API pública de openFDA.
  Future<List<Medicamento>> obtenerMedicamentos({
    String consulta = '',
    int limite = 20,
  }) async {
    final texto = consulta.trim();

    final parametros = <String, String>{'limit': limite.toString()};

    if (texto.isNotEmpty) {
      final limpio = texto.replaceAll('"', '');
      parametros['search'] =
          '(openfda.brand_name:"$limpio" OR openfda.generic_name:"$limpio" OR openfda.substance_name:"$limpio")';
    } else {
      parametros['search'] =
          '_exists_:openfda.brand_name AND _exists_:openfda.route';
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: parametros);

    try {
      final respuesta = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson =
            json.decode(respuesta.body) as Map<String, dynamic>;

        final List<dynamic> resultados =
            (datosJson['results'] as List<dynamic>?) ?? <dynamic>[];

        final listaMedicamentos = <Medicamento>[];
        for (final item in resultados) {
          if (item is Map<String, dynamic>) {
            listaMedicamentos.add(Medicamento.fromOpenFdaJson(item));
          }
        }
        return listaMedicamentos;
      } else if (respuesta.statusCode == 404) {
        return <Medicamento>[];
      } else {
        throw Exception(
          'Error al conectar con openFDA (Código HTTP: ${respuesta.statusCode})',
        );
      }
    } on TimeoutException {
      throw Exception(
        'La conexión con openFDA tardó más de 15 segundos. Revisa tu internet.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error de red al consultar medicamentos: $e');
    }
  }

  /// Consulta las URLs de imágenes reales (empaques/tabletas) en DailyMed (NIH)
  /// usando el [setId] obtenido desde openFDA.
  Future<List<String>> obtenerImagenesMedicamento(String setId) async {
    final idLimpio = setId.trim();
    if (idLimpio.isEmpty) {
      return <String>[];
    }

    final uri = Uri.parse('$_dailyMedBaseUrl/$idLimpio/media.json');

    try {
      final respuesta = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (respuesta.statusCode != 200) {
        return <String>[];
      }

      final Map<String, dynamic> datosJson =
          json.decode(respuesta.body) as Map<String, dynamic>;
      final dynamic data = datosJson['data'];

      List<dynamic> mediaLista = <dynamic>[];
      if (data is Map<String, dynamic> && data['media'] is List<dynamic>) {
        mediaLista = data['media'] as List<dynamic>;
      } else if (data is List<dynamic>) {
        mediaLista = data;
      }

      final urlsImagenes = <String>[];
      for (final item in mediaLista) {
        if (item is Map<String, dynamic>) {
          final url = item['url']?.toString().trim() ?? '';
          final mime = item['mime_type']?.toString().toLowerCase() ?? '';
          if (url.isNotEmpty &&
              (mime.startsWith('image/') ||
                  url.toLowerCase().endsWith('.jpg') ||
                  url.toLowerCase().endsWith('.png'))) {
            urlsImagenes.add(url);
          }
        }
      }
      return urlsImagenes;
    } catch (_) {
      // Si no hay fotos o el navegador bloquea CORS, devolvemos lista vacía
      // para que la interfaz muestre el banner ilustrado sin errores.
      return <String>[];
    }
  }
}
