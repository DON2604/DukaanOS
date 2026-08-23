import 'package:flutter_test/flutter_test.dart';
import 'package:udyam/main.dart';

void main() {
  testWidgets('App opens on ScanShopScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const UdyamApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Show us your shop'), findsOneWidget);
    expect(find.text('Start scan'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
  });
}
