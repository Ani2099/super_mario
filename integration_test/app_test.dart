import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:super_mario/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Flow Integration Test', () {
    testWidgets('Verify Splash Screen boots services and redirects to Main Menu', (tester) async {
      // Boot the actual application
      app.main();
      await tester.pump();

      // Check for Splash Title
      expect(find.text('ANTIGRAVITY RUNNER'), findsOneWidget);

      // Wait for Hive/Audio services initialization and splash delay
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify Main Menu is loaded
      expect(find.text('PLAY GAME'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
    });
  });
}
