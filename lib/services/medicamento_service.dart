import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/medicamento.dart';

class MedicamentoService {
  static const String _baseUrl = 'https://api.fda.gov/drug/label.json';

  /// Consulta la API pública de openFDA.
  /// - Si [consulta] está vacía, trae los primeros [limite] medicamentos disponibles.
  /// - Si [consulta] tiene texto, busca por nombre comercial, genérico o principio activo.
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
      // Filtra en la carga inicial para traer solo medicamentos con nombre y vía registrados
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
        // openFDA responde 404 cuando ninguna medicina coincide con la búsqueda.
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
}
