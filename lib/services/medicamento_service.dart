import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/medicamento.dart';

class MedicamentoService {
  static const String _baseUrl = 'https://api.fda.gov/drug/label.json';
  static const String _dailyMedBaseUrl =
      'https://dailymed.nlm.nih.gov/dailymed/services/v2/spls';

  /// Diccionario rápido para términos farmacéuticos comunes en español -> inglés
  /// antes de consultar openFDA.
  static const Map<String, String> _diccionarioFarmaceutico = {
    'ibuprofeno': 'Ibuprofen',
    'amoxicilina': 'Amoxicillin',
    'acetaminofen': 'Acetaminophen',
    'acetaminofén': 'Acetaminophen',
    'paracetamol': 'Acetaminophen',
    'aspirina': 'Aspirin',
    'omeprazol': 'Omeprazole',
    'naproxeno': 'Naproxen',
    'loratadina': 'Loratadine',
    'diclofenaco': 'Diclofenac',
    'metformina': 'Metformin',
    'losartan': 'Losartan',
    'losartán': 'Losartan',
    'atorvastatina': 'Atorvastatin',
    'azitromicina': 'Azithromycin',
    'ciprofloxacino': 'Ciprofloxacin',
    'cetirizina': 'Cetirizine',
  };

  /// Convierte el término de búsqueda de español a inglés si es necesario
  /// para que openFDA encuentre resultados.
  Future<String> _prepararTerminoBusqueda(String consulta) async {
    final limpio = consulta.trim().replaceAll('"', '');
    if (limpio.isEmpty) return '';

    final clave = limpio.toLowerCase();
    if (_diccionarioFarmaceutico.containsKey(clave)) {
      return _diccionarioFarmaceutico[clave]!;
    }

    // Si el estudiante escribe otro medicamento en español, lo traducimos al inglés
    final traducido = await traducirTexto(
      limpio,
      idiomaOrigen: 'es',
      idiomaDestino: 'en',
    );
    return traducido.trim().isEmpty ? limpio : traducido.trim();
  }

  /// Consulta la API pública de openFDA.
  Future<List<Medicamento>> obtenerMedicamentos({
    String consulta = '',
    int limite = 20,
  }) async {
    final textoOriginal = consulta.trim();

    final parametros = <String, String>{'limit': limite.toString()};

    if (textoOriginal.isNotEmpty) {
      final terminoIngles = await _prepararTerminoBusqueda(textoOriginal);
      parametros['search'] =
          '(openfda.brand_name:"$terminoIngles" OR openfda.generic_name:"$terminoIngles" OR openfda.substance_name:"$terminoIngles")';
    } else {
      // Carga inicial variada (Oral, Tópica, Oftálmica, etc.)
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

  /// Traduce textos clínicos largos dividiéndolos en bloques seguros
  /// para que toda la ficha del medicamento se lea en español.
  Future<String> traducirTexto(
    String texto, {
    String idiomaOrigen = 'en',
    String idiomaDestino = 'es',
  }) async {
    final limpio = texto.trim();
    if (limpio.isEmpty ||
        limpio == 'No disponible en la ficha.' ||
        limpio == 'Sin advertencias registradas.' ||
        limpio == 'No registradas en la ficha.' ||
        limpio == 'No registrados en la ficha.') {
      return limpio;
    }

    // Dividimos textos muy largos en fragmentos de máximo 1100 caracteres
    final fragmentos = _dividirEnFragmentos(limpio, 1100);
    final resultadoFinal = StringBuffer();

    for (final fragmento in fragmentos) {
      final uri = Uri.https(
        'translate.googleapis.com',
        '/translate_a/single',
        <String, String>{
          'client': 'gtx',
          'sl': idiomaOrigen,
          'tl': idiomaDestino,
          'dt': 't',
          'q': fragmento,
        },
      );

      try {
        final respuesta = await http
            .get(uri)
            .timeout(const Duration(seconds: 10));

        if (respuesta.statusCode == 200) {
          final dynamic decoded = json.decode(respuesta.body);
          if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
            final oraciones = decoded[0] as List<dynamic>;
            for (final oracion in oraciones) {
              if (oracion is List && oracion.isNotEmpty && oracion[0] != null) {
                resultadoFinal.write(oracion[0].toString());
              }
            }
            resultadoFinal.write(' ');
          } else {
            resultadoFinal.write('$fragmento ');
          }
        } else {
          resultadoFinal.write('$fragmento ');
        }
      } catch (_) {
        // Si falla la traducción de un bloque, conserva el texto original
        resultadoFinal.write('$fragmento ');
      }
    }

    final textoTraducido = resultadoFinal.toString().trim();
    return textoTraducido.isEmpty ? limpio : textoTraducido;
  }

  List<String> _dividirEnFragmentos(String texto, int maxLargo) {
    if (texto.length <= maxLargo) return <String>[texto];

    final fragmentos = <String>[];
    int inicio = 0;

    while (inicio < texto.length) {
      int fin = inicio + maxLargo;
      if (fin >= texto.length) {
        fragmentos.add(texto.substring(inicio));
        break;
      }
      // Intentar cortar en un punto o espacio para no partir palabras a la mitad
      int corte = texto.lastIndexOf('. ', fin);
      if (corte <= inicio) {
        corte = texto.lastIndexOf(' ', fin);
      }
      if (corte <= inicio) {
        corte = fin;
      } else {
        corte += 1;
      }
      fragmentos.add(texto.substring(inicio, corte).trim());
      inicio = corte;
    }

    return fragmentos;
  }

  /// Consulta las URLs de imágenes reales en DailyMed (NIH).
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
      return <String>[];
    }
  }
}
