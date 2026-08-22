import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udyam/main.dart';

void main() {
  testWidgets('App renders WelcomeScreen with logo asset and action buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const UdyamApp());
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
    expect(find.text('Set up my shop'), findsOneWidget);
    expect(find.text('See how it works'), findsOneWidget);
  });
}
