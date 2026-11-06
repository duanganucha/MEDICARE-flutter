import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:medicare/features.dart';
import 'package:medicare/ui/noac_page.dart';
import 'package:medicare/ui/tb_page.dart';
import 'package:medicare/ui/theme.dart';
import 'package:medicare/ui/widgets.dart';

/// Runs on a real iOS device or simulator, where `Platform.isIOS` is true, to
/// prove the build Apple receives carries no dose output. A host unit test
/// cannot check this: it has no platform, so the flag falls back to on.
///
///   flutter test integration_test/no_doses_on_ios_test.dart -d `ios device`

Future<void> pumpPage(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: SingleChildScrollView(child: page)),
    ),
  );
  await tester.pumpAndSettle();
}

String visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .join('\n');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iOS builds ship with dose output disabled', (tester) async {
    expect(Platform.isIOS, isTrue,
        reason: 'run this on an iOS device or simulator');
    expect(showDoses, isFalse,
        reason: 'the iOS build must not show drug doses');
  });

  testWidgets('the TB tab shows the reference table, not a regimen',
      (tester) async {
    await pumpPage(tester, const TbPage());

    expect(find.byType(DosesUnavailableNote), findsOneWidget);
    expect(find.text('เกณฑ์ขนาดยาวัณโรคตามแนวทาง WHO'), findsOneWidget);

    final text = visibleText(tester);
    // A regimen states tablets per day for a given patient; the reference
    // states mg/kg. Seeing tablets here means the dose output came back.
    expect(text, isNot(contains('เม็ด/วัน')));
    expect(text, isNot(contains('รวมจริง')));
    expect(text, contains('มก./กก./วัน'));
  });

  testWidgets('the NOAC tab keeps CrCl but names no drug dose',
      (tester) async {
    await pumpPage(tester, const NoacPage());

    // Creatinine clearance is a measure of kidney function, not a dose, so
    // it stays. The per-drug milligrams do not.
    expect(find.textContaining('Cockcroft'), findsWidgets);

    final text = visibleText(tester);
    for (final dose in ['5 mg', '2.5 mg', '20 mg', '15 mg', '150 mg']) {
      expect(text, isNot(contains(dose)), reason: '$dose is a drug dose');
    }
  });
}
