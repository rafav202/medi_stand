import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/medicamento.dart';

class MedicamentoService {
  static const String _baseUrl = 'https://api.fda.gov/drug/label.json';
  static const String _dailyMedBaseUrl =
      'https://dailymed.nlm.nih.gov/dailymed/services/v2/spls';

  /// Memoria temporal de códigos de barras locales (ej. 770...) vinculados
  /// durante la sesión para que al volver a escanear la misma caja abra directo.
  static final Map<String, String> _codigosBarrasVinculados = {};

  /// Diccionario rápido para términos farmacéuticos comunes en español -> inglés.
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

  void vincularCodigoBarras(String codigoBarras, String nombreMedicamento) {
    final codigo = codigoBarras.trim();
    final nombre = nombreMedicamento.trim();
    if (codigo.isNotEmpty && nombre.isNotEmpty) {
      _codigosBarrasVinculados[codigo] = nombre;
    }
  }

  Future<List<Medicamento>> buscarPorCodigoBarras(String codigoLeido) async {
    final limpio = codigoLeido.trim();
    if (limpio.isEmpty) return [];

    if (_codigosBarrasVinculados.containsKey(limpio)) {
      return obtenerMedicamentos(
        consulta: _codigosBarrasVinculados[limpio]!,
        limite: 25,
      );
    }

    final sinCeroInicial = (limpio.length == 13 && limpio.startsWith('0'))
        ? limpio.substring(1)
        : limpio;

    try {
      final parametros = <String, String>{
        'limit': '10',
        'search':
            '(openfda.upc:"$limpio" OR openfda.upc:"$sinCeroInicial" OR openfda.package_ndc:"$limpio")',
      };

      final uri = Uri.parse(_baseUrl).replace(queryParameters: parametros);
      final respuesta = await http
          .get(uri)
          .timeout(const Duration(seconds: 12));

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson =
            json.decode(respuesta.body) as Map<String, dynamic>;
        final List<dynamic> resultados =
            (datosJson['results'] as List<dynamic>?) ?? [];

        final lista = <Medicamento>[];
        for (final item in resultados) {
          if (item is Map<String, dynamic>) {
            lista.add(Medicamento.fromOpenFdaJson(item));
          }
        }
        if (lista.isNotEmpty) {
          return lista;
        }
      }
    } catch (_) {}

    try {
      final uriProducto = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$limpio.json',
      );
      final respProducto = await http
          .get(uriProducto)
          .timeout(const Duration(seconds: 8));

      if (respProducto.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(respProducto.body) as Map<String, dynamic>;
        if (data['status'] == 1 && data['product'] is Map<String, dynamic>) {
          final producto = data['product'] as Map<String, dynamic>;
          final nombreProducto =
              (producto['product_name'] ?? producto['generic_name'] ?? '')
                  .toString()
                  .trim();

          if (nombreProducto.isNotEmpty) {
            final palabraClave = nombreProducto.split(' ').first;
            final encontrados = await obtenerMedicamentos(
              consulta: palabraClave,
              limite: 10,
            );
            if (encontrados.isNotEmpty) {
              vincularCodigoBarras(limpio, palabraClave);
              return encontrados;
            }
          }
        }
      }
    } catch (_) {}

    return [];
  }

  Future<String> _prepararTerminoBusqueda(String consulta) async {
    final limpio = consulta.trim().replaceAll('"', '');
    if (limpio.isEmpty) return '';

    final clave = limpio.toLowerCase();
    if (_diccionarioFarmaceutico.containsKey(clave)) {
      return _diccionarioFarmaceutico[clave]!;
    }

    final traducido = await traducirTexto(
      limpio,
      idiomaOrigen: 'es',
      idiomaDestino: 'en',
    );
    return traducido.trim().isEmpty ? limpio : traducido.trim();
  }

  /// Consulta hasta el máximo permitido por openFDA (100 registros por bloque)
  /// y soporta paginación mediante [saltar] (parámetro `skip` de la API).
  Future<List<Medicamento>> obtenerMedicamentos({
    String consulta = '',
    int limite = 100,
    int saltar = 0,
  }) async {
    final textoOriginal = consulta.trim();
    final int limiteSeguro = limite.clamp(1, 100);

    final parametros = <String, String>{
      'limit': limiteSeguro.toString(),
      if (saltar > 0) 'skip': saltar.toString(),
    };

    if (textoOriginal.isNotEmpty) {
      final terminoIngles = await _prepararTerminoBusqueda(textoOriginal);
      parametros['search'] =
          '(openfda.brand_name:"$terminoIngles" OR openfda.generic_name:"$terminoIngles" OR openfda.substance_name:"$terminoIngles")';
    } else {
      // Trae todos los medicamentos registrados con nombre comercial en openFDA
      parametros['search'] = '_exists_:openfda.brand_name';
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: parametros);

    try {
      final respuesta = await http
          .get(uri)
          .timeout(const Duration(seconds: 18));

      if (respuesta.statusCode == 200) {
        final Map<String, dynamic> datosJson =
            json.decode(respuesta.body) as Map<String, dynamic>;

        final List<dynamic> resultados =
            (datosJson['results'] as List<dynamic>?) ?? [];

        final listaMedicamentos = <Medicamento>[];
        for (final item in resultados) {
          if (item is Map<String, dynamic>) {
            listaMedicamentos.add(Medicamento.fromOpenFdaJson(item));
          }
        }
        return listaMedicamentos;
      } else if (respuesta.statusCode == 404) {
        return [];
      } else {
        throw Exception(
          'Error al conectar con openFDA (Código HTTP: ${respuesta.statusCode})',
        );
      }
    } on TimeoutException {
      throw Exception(
        'La conexión con openFDA tardó más de 18 segundos. Revisa tu internet.',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error de red al consultar medicamentos: $e');
    }
  }

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
        resultadoFinal.write('$fragmento ');
      }
    }

    final textoTraducido = resultadoFinal.toString().trim();
    return textoTraducido.isEmpty ? limpio : textoTraducido;
  }

  List<String> _dividirEnFragmentos(String texto, int maxLargo) {
    if (texto.length <= maxLargo) return [texto];

    final fragmentos = <String>[];
    int inicio = 0;

    while (inicio < texto.length) {
      int fin = inicio + maxLargo;
      if (fin >= texto.length) {
        fragmentos.add(texto.substring(inicio));
        break;
      }
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

  Future<List<String>> obtenerImagenesMedicamento(String setId) async {
    final idLimpio = setId.trim();
    if (idLimpio.isEmpty) {
      return [];
    }

    final uri = Uri.parse('$_dailyMedBaseUrl/$idLimpio/media.json');

    try {
      final respuesta = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (respuesta.statusCode != 200) {
        return [];
      }

      final Map<String, dynamic> datosJson =
          json.decode(respuesta.body) as Map<String, dynamic>;
      final dynamic data = datosJson['data'];

      List<dynamic> mediaLista = [];
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
      return [];
    }
  }
}
