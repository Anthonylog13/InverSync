import 'package:flutter_test/flutter_test.dart';
import 'package:inver_sync/main.dart';
import 'package:inver_sync/screens/login/login_screen.dart';

void main() {
  testWidgets('App shows login screen with title and Google button',
      (WidgetTester tester) async {
    // Pasamos LoginScreen directamente para evitar inicializar Firebase en tests.
    await tester.pumpWidget(const InverSyncApp(home: LoginScreen()));

    // La LoginScreen debe mostrar el título y el botón de Google.
    expect(find.text('InverSync'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}
