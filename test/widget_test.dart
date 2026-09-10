// Smoke test: la app arranca y muestra su título.
import 'package:flutter_test/flutter_test.dart';

import 'package:mangrove_disease_detector/main.dart';

void main() {
  testWidgets('MangroveApp arranca', (WidgetTester tester) async {
    await tester.pumpWidget(const MangroveApp());

    expect(find.byType(MangroveApp), findsOneWidget);
  });
}
