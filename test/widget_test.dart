import 'package:flutter_test/flutter_test.dart';

import 'package:dinely/main.dart';

void main() {
  testWidgets('app loads the customer login screen', (tester) async {
    await tester.pumpWidget(const DinelyApp());

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to your account to continue'), findsOneWidget);
  });
}
