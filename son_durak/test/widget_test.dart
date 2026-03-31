import 'package:flutter_test/flutter_test.dart';

import 'package:son_durak/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SonDurakApp());

    // Google Maps is a platform view, which might cause issues in simple widget tests
    // so we just check if SonDurakApp is rendering successfully.
    expect(find.byType(SonDurakApp), findsOneWidget);
  });
}
