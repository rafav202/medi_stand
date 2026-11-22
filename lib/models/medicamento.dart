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

  /// Vía principal en español para mostrar en tarjetas, filtros y gráficas.
  String get viaPrincipalCorta {
    final primeraLinea = viaAdministracion.split('\n').first.trim();
    final primeraVia = primeraLinea.split(',').first.trim().toUpperCase();
    if (primeraVia.isEmpty || primeraVia == 'NO REGISTRADA') {
      return 'NO REGISTRADA';
    }
    if (primeraVia.contains('ORAL')) return 'ORAL';
    if (primeraVia.contains('TOPICAL')) return 'TÓPICA';
    if (primeraVia.contains('OPHTHALMIC')) return 'OFTÁLMICA';
    if (primeraVia.contains('INTRAVENOUS')) return 'INTRAVENOSA';
    if (primeraVia.contains('INJECTION') ||
        primeraVia.contains('SUBCUTANEOUS')) {
      return 'INYECTABLE';
    }
    if (primeraVia.contains('NASAL')) return 'NASAL';
    if (primeraVia.contains('RESPIRATORY') ||
        primeraVia.contains('INHALATION')) {
      return 'INHALATORIA';
    }
    return primeraVia;
  }

  /// Indica si el medicamento es de venta libre (OTC) o requiere fórmula médica.
  bool get esVentaLibre => formaFarmaceutica.toUpperCase().contains('OTC');

  /// Tipo de dispensación legible en español.
  String get tipoDispensacionEspanol {
    final tipo = formaFarmaceutica.toUpperCase();
    if (tipo.contains('OTC')) return 'Venta Libre (OTC)';
    if (tipo.contains('PRESCRIPTION')) return 'Fórmula Médica (Rx)';
    return formaFarmaceutica;
  }

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
