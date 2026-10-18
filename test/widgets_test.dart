import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/logic/noac.dart';
import 'package:medicare/ui/theme.dart';
import 'package:medicare/ui/widgets.dart';

/// Pumps [child] inside the real app theme.
Future<void> pumpThemed(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // A non-uniform Border with a borderRadius throws during paint and the card
  // renders as a bare rectangle, so every flag is checked for clean painting.
  group('DrugCard paints without exceptions', () {
    for (final flag in DoseFlag.values) {
      testWidgets('flag $flag', (tester) async {
        await pumpThemed(
          tester,
          DrugCard(
            name: 'Apixaban (Eliquis)',
            dose: '2.5 mg วันละ 2 ครั้ง',
            reason: 'CrCl 15–29 mL/min',
            flag: flag,
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Apixaban (Eliquis)'), findsOneWidget);
        expect(find.text('2.5 mg วันละ 2 ครั้ง'), findsOneWidget);
        expect(find.textContaining('CrCl 15–29'), findsOneWidget);
      });
    }
  });

  testWidgets('WarningBanner paints and shows both lines', (tester) async {
    await pumpThemed(
      tester,
      const WarningBanner(title: 'ต้นแบบสำหรับทดสอบ', body: 'ตรวจสอบก่อนใช้เสมอ'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('ต้นแบบสำหรับทดสอบ'), findsOneWidget);
    expect(find.text('ตรวจสอบก่อนใช้เสมอ'), findsOneWidget);
  });

  testWidgets('avoid flag shows the warning pill and hides no text', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      const DrugCard(
        name: 'Dabigatran (Pradaxa)',
        dose: 'ไม่แนะนำ / ห้ามใช้',
        reason: 'CrCl <30 mL/min',
        flag: DoseFlag.avoid,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('ไม่แนะนำ'), findsOneWidget); // the pill
    expect(find.text('ไม่แนะนำ / ห้ามใช้'), findsOneWidget); // the dose
  });

  testWidgets('StatBox renders the CrCl value', (tester) async {
    await pumpThemed(
      tester,
      const StatBox(label: 'ค่า CrCl', crCl: 42.01, unit: 'mL/min'),
    );

    expect(tester.takeException(), isNull);
    // The value counts up, so it only reads 42.01 once settled.
    expect(find.text('42.01'), findsOneWidget);
    expect(find.text('mL/min'), findsOneWidget);
  });
}
