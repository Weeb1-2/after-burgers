import 'package:burguer_app/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://test.supabase.co
SUPABASE_ANON_KEY=sb_publishable_test_key_for_widget_tests
ADMIN_PASSWORD=test
WHATSAPP_NUMBER=5490000000000
OPENING_HOUR=21
CLOSING_HOUR=3
STORAGE_BUCKET=productos-imagenes
''',
    );
  });

  testWidgets('AfterBurgersEvoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AfterBurgersEvoApp());
    await tester.pump();

    expect(find.text('AFTER'), findsOneWidget);
    expect(find.text('BURGERS'), findsOneWidget);
  });
}
