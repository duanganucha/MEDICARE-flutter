@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/logic/tb.dart';
import 'package:medicare/ui/theme.dart';
import 'package:medicare/ui/widgets.dart';

/// App Review rejected 1.0 (3) under guideline 1.4.2: an app that calculates
/// medical dosages must come from the manufacturer or a recognised
/// institution. The iOS build answers that by shipping without the dose
/// output, so these tests check the pieces that build relies on.
///
/// The flag itself reads `Platform.isIOS`, which a host test cannot fake, so
/// the widget-level checks live in `flutter test -d ios` territory. What is
/// testable here is that the reference data says what the guideline says and
/// that the replacement widget renders — both of which a refactor could break
/// without any test noticing.

void main() {
  group('published reference values', () {
    test('adult rows match the WHO mg/kg and daily maximums', () {
      expect(adultReference.map((r) => (r.perKg, r.maxMg)), [
        (5.0, 300.0), // isoniazid
        (10.0, 600.0), // rifampicin
        (25.0, 2000.0), // pyrazinamide
        (20.0, 1200.0), // ethambutol
      ]);
    });

    test('child rows carry the higher paediatric mg/kg', () {
      expect(childReference.map((r) => (r.perKg, r.maxMg)), [
        (10.0, 300.0),
        (15.0, 600.0),
        (35.0, 2000.0),
        (20.0, 1200.0),
      ]);
    });

    test('reference and regimen agree, so the two cannot drift apart', () {
      // Both are derived from the same guideline. If someone edits one set of
      // numbers, this fails rather than letting the app state one thing and
      // compute another.
      final computed = adultRegimen(weight: 1, days: 1);
      for (final (i, row) in adultReference.indexed) {
        expect(
          computed[i].targetMg,
          row.perKg,
          reason: '${row.name}: reference says ${row.perKg} mg/kg',
        );
      }
    });

    test('every reference row is a real dose band, not a placeholder', () {
      for (final r in [...adultReference, ...childReference]) {
        expect(r.perKg, greaterThan(0));
        expect(r.maxMg, greaterThan(0));
        expect(r.maxMg, greaterThan(r.perKg));
        expect(r.name, isNotEmpty);
      }
    });
  });

  testWidgets('the notice explains the omission without naming a dose',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const Scaffold(body: DosesUnavailableNote()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DosesUnavailableNote), findsOneWidget);
    expect(tester.takeException(), isNull);

    // It must say why the numbers are missing, so the page does not read as
    // broken, and must not itself state a dose.
    final text = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(text, contains('เกณฑ์อ้างอิง'));
    expect(text, isNot(contains('มก./วัน')));
  });
}
