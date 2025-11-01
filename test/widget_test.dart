import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eco_manage/main.dart';

void main() {
  testWidgets('App navigation smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoManageApp());
    expect(find.text('Selamat Datang!'), findsOneWidget);

    expect(find.text('Gunakan Tas Belanja Pakai Ulang'), findsNothing);

    await tester.tap(find.byIcon(Icons.lightbulb_outline));
    await tester.pump();
    expect(find.text('Gunakan Tas Belanja Pakai Ulang'), findsOneWidget);
    expect(find.text('Selamat Datang!'), findsNothing);
  });
}
