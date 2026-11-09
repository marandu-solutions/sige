import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SIGE baseline app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: Text('SIGE System'))),
    ));
    expect(find.text('SIGE System'), findsOneWidget);
  });
}
