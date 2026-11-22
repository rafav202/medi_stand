import 'package:flutter_test/flutter_test.dart';
import 'package:medi_stand/main.dart';

void main() {
  testWidgets('Carga la pantalla principal de Medi-Stand', (
    WidgetTester tester,
  ) async {
    // Construye la aplicación MediStandApp en el entorno de pruebas
    await tester.pumpWidget(const MediStandApp());

    // Verifica que el título superior y las dos pestañas inferiores aparezcan
    expect(find.text('Medi-Stand • Consulta'), findsOneWidget);
    expect(find.text('Medicamentos'), findsOneWidget);
    expect(find.text('Gráficas'), findsOneWidget);
  });
}
