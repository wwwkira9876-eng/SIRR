import 'package:flutter_test/flutter_test.dart';
import 'package:sirr/main.dart';

void main() {
  testWidgets('SIRR app displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SIRRApp());

    expect(find.text('S I R R'), findsOneWidget);
    expect(find.text('افتح رسالتك'), findsOneWidget);
  });
}
