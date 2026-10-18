import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/main.dart';
import 'package:medicare/ui/brand.dart';
import 'package:medicare/ui/theme.dart';

void main() {
  test('Brand.next alternates between the two palettes', () {
    expect(Brand.plum.next, Brand.teal);
    expect(Brand.teal.next, Brand.plum);
  });

  test('each brand and brightness yields its own header colour', () {
    Color header(Brightness b, Brand brand) =>
        buildTheme(b, brand).extension<DoseColors>()!.headerBottom;

    final colours = {
      header(Brightness.light, Brand.plum),
      header(Brightness.dark, Brand.plum),
      header(Brightness.light, Brand.teal),
      header(Brightness.dark, Brand.teal),
    };
    expect(colours, hasLength(4), reason: 'all four must differ');
  });

  test('dose colours keep their clinical meaning across brands', () {
    // Green/amber/red must not follow the brand.
    for (final brand in Brand.values) {
      final d = buildTheme(Brightness.light, brand).extension<DoseColors>()!;
      expect(d.ok, const Color(0xFF12804F));
      expect(d.caution, const Color(0xFF9A5A00));
      expect(d.bad, const Color(0xFFB3261E));
    }
  });

  testWidgets('tapping the header switch changes the palette', (tester) async {
    // A realistic phone surface; the default 800x600 is not a phone.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MedicareApp());
    // Let the splash finish so the header is on screen.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    DoseColors doseOf() => Theme.of(
      tester.element(find.text('MEDICARE')),
    ).extension<DoseColors>()!;

    final before = doseOf().headerBottom;

    final switcher = find.byTooltip('เปลี่ยนเป็นธีมเขียว');
    expect(switcher, findsOneWidget);
    await tester.tap(switcher);
    await tester.pumpAndSettle();

    expect(doseOf().headerBottom, isNot(before));
    // And the tooltip now offers the way back.
    expect(find.byTooltip('เปลี่ยนเป็นธีมม่วง'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
