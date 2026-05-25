import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_testing/main.dart';

void main() {
  testWidgets('Uses picture_info addOne', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Entrada actual: 2'), findsOneWidget);
    expect(find.text('Resultado addOne: 3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    expect(find.text('Entrada actual: 3'), findsOneWidget);
    expect(find.text('Resultado addOne: 4'), findsOneWidget);
  });
}
