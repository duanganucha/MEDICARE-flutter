import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/ui/splash_page.dart';
import 'package:medicare/ui/theme.dart';

void main() {
  testWidgets('splash animates in and reports completion once', (
    tester,
  ) async {
    var doneCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: SplashPage(onDone: () => doneCount++),
      ),
    );

    // The wordmark is drawn letter by letter, so it is eight Text widgets
    // rather than one; the tagline is a single one.
    for (final ch in 'MEDICARE'.split('')) {
      expect(find.text(ch), findsWidgets, reason: 'letter $ch missing');
    }
    expect(find.text('เครื่องมือช่วยคำนวณขนาดยาสำหรับเภสัชกร'), findsOneWidget);

    // The last letter reveals last, so it tracks the wordmark's progress.
    double wordmarkOpacity() {
      final opacities = tester
          .widgetList<Opacity>(
            find.ancestor(of: find.text('E').last, matching: find.byType(Opacity)),
          )
          .map((o) => o.opacity);
      // Outer wrappers are included, so take the smallest.
      return opacities.reduce((a, b) => a < b ? a : b);
    }

    // Starts hidden.
    expect(wordmarkOpacity(), lessThan(0.05));
    expect(doneCount, 0);

    // Mid-flight it is partly revealed.
    await tester.pump(const Duration(milliseconds: 1500));
    final mid = wordmarkOpacity();
    expect(mid, greaterThan(0.05));
    expect(doneCount, 0, reason: 'must not finish early');

    // It keeps progressing.
    await tester.pump(const Duration(milliseconds: 400));
    expect(wordmarkOpacity(), greaterThanOrEqualTo(mid));

    // The whole sequence completes and fires onDone exactly once.
    await tester.pumpAndSettle();
    expect(doneCount, 1);

    expect(tester.takeException(), isNull);
  });

  testWidgets('splash disposes cleanly if dismissed early', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: SplashPage(onDone: () {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Replacing it mid-animation must not leave a ticker running.
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
