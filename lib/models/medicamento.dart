class Medicamento {
  final String setId;
  final String nombre;
  final String principioActivo;
  final String viaAdministracion;
  final String formaFarmaceutica;
  final String fabricante;
  final String indicaciones;
  final String dosificacion;
  final String advertencias;
  final String contraindicaciones;
  final String efectosAdversos;

  Medicamento({
    required this.setId,
    required this.nombre,
    required this.principioActivo,
    required this.viaAdministracion,
    required this.formaFarmaceutica,
    required this.fabricante,
    required this.indicaciones,
    required this.dosificacion,
    required this.advertencias,
    required this.contraindicaciones,
    required this.efectosAdversos,
  });

  /// Convierte de forma segura cualquier dato del JSON en un texto limpio.
  static String _textoSeguro(dynamic dato, String porDefecto) {
    if (dato == null) {
      return porDefecto;
    }
    if (dato is List) {
      final textos = <String>[];
      for (final item in dato) {
        if (item != null && item.toString().trim().isNotEmpty) {
          textos.add(item.toString().trim());
        }
      }
      if (textos.isEmpty) {
        return porDefecto;
      }
      return textos.join('\n\n');
    }
    final textoLimpio = dato.toString().trim();
    return textoLimpio.isEmpty ? porDefecto : textoLimpio;
  }

  /// Toma la primera vía de administración corta para agrupar en las gráficas y filtros.
  String get viaPrincipalCorta {
    final primeraLinea = viaAdministracion.split('\n').first.trim();
    final primeraVia = primeraLinea.split(',').first.trim();
    if (primeraVia.isEmpty) return 'NO REGISTRADA';
    return primeraVia.toUpperCase();
  }

  /// Indica si el medicamento es de venta libre (OTC) o requiere fórmula médica.
  bool get esVentaLibre => formaFarmaceutica.toUpperCase().contains('OTC');

  /// Construye un objeto Medicamento a partir de un elemento JSON de openFDA.
  factory Medicamento.fromOpenFdaJson(Map<String, dynamic> json) {
    final Map<String, dynamic> openFda = json['openfda'] is Map<String, dynamic>
        ? json['openfda'] as Map<String, dynamic>
        : <String, dynamic>{};

    return Medicamento(
      setId: _textoSeguro(json['set_id'] ?? openFda['spl_set_id'], ''),
      nombre: _textoSeguro(
        openFda['brand_name'] ?? openFda['generic_name'],
        'Medicamento sin nombre comercial',
      ),
      principioActivo: _textoSeguro(
        openFda['substance_name'] ??
            json['active_ingredient'] ??
            openFda['generic_name'],
        'No especificado',
      ),
      viaAdministracion: _textoSeguro(openFda['route'], 'No registrada'),
      formaFarmaceutica: _textoSeguro(
        openFda['dosage_form'] ?? openFda['product_type'],
        'No registrada',
      ),
      fabricante: _textoSeguro(
        openFda['manufacturer_name'],
        'Fabricante no registrado',
      ),
      indicaciones: _textoSeguro(
        json['indications_and_usage'],
        'No disponible en la ficha.',
      ),
      dosificacion: _textoSeguro(
        json['dosage_and_administration'],
        'No disponible en la ficha.',
      ),
      advertencias: _textoSeguro(
        json['warnings'] ?? json['warnings_and_cautions'],
        'Sin advertencias registradas.',
      ),
      contraindicaciones: _textoSeguro(
        json['contraindications'],
        'No registradas en la ficha.',
      ),
      efectosAdversos: _textoSeguro(
        json['adverse_reactions'],
        'No registrados en la ficha.',
      ),
    );
  }
}
