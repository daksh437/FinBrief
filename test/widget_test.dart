// Placeholder smoke test. FinBriefApp itself needs Firebase.initializeApp()
// (called in main.dart) before it can be pumped in a widget test, so real
// widget tests should mock firebase_core/firebase_auth first.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sanity check — MaterialApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('FinBrief'))));
    expect(find.text('FinBrief'), findsOneWidget);
  });
}
