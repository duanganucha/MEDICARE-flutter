import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/ui/noac_page.dart';
import 'package:medicare/ui/tb_page.dart';
import 'package:medicare/ui/theme.dart';
import 'package:medicare/ui/widgets.dart';

/// App Review rejected 1.0 under guideline 1.4.1 because the dosing pages
/// carried no citations. These tests pin the sources in place so a later
/// refactor cannot quietly drop them and earn the same rejection twice.

Future<void> pumpPage(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: SingleChildScrollView(child: page)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every url a page offers, in the order they appear.
List<String> citationUrls(WidgetTester tester) => tester
    .widgetList<CitationLink>(find.byType(CitationLink))
    .map((w) => w.url)
    .toList();

void main() {
  testWidgets('NOAC page cites EHRA and Cockcroft-Gault', (tester) async {
    await pumpPage(tester, const NoacPage());

    expect(find.text('แหล่งอ้างอิง'), findsOneWidget);
    expect(
      citationUrls(tester),
      containsAll(<String>[
        'https://pubmed.ncbi.nlm.nih.gov/33895845/',
        'https://pubmed.ncbi.nlm.nih.gov/1244564/',
      ]),
    );
  });

  testWidgets('TB page cites the WHO guidance', (tester) async {
    await pumpPage(tester, const TbPage());

    expect(find.text('แหล่งอ้างอิง'), findsOneWidget);
    expect(
      citationUrls(tester),
      containsAll(<String>[
        'https://www.who.int/publications/i/item/9789240048126',
        'https://www.who.int/publications/i/item/9789240050761',
      ]),
    );
  });

  testWidgets('every citation is a reachable https link', (tester) async {
    for (final page in <Widget>[const NoacPage(), const TbPage()]) {
      await pumpPage(tester, page);
      final urls = citationUrls(tester);
      expect(urls, isNotEmpty);
      for (final url in urls) {
        final uri = Uri.tryParse(url);
        expect(uri, isNotNull, reason: '$url does not parse');
        expect(uri!.scheme, 'https', reason: '$url is not https');
        expect(uri.host, isNotEmpty, reason: '$url has no host');
      }
    }
  });

  testWidgets('citation text names the source, not just the url',
      (tester) async {
    await pumpPage(tester, const NoacPage());
    for (final link in tester.widgetList<CitationLink>(
      find.byType(CitationLink),
    )) {
      // A bare url is not a citation: reviewers look for the document title.
      expect(link.text.length, greaterThan(30));
      expect(link.text, isNot(contains('http')));
    }
  });

  testWidgets('citations paint cleanly at phone width', (tester) async {
    // The DrugCard bug only showed on a real device: a decoration Flutter
    // cannot paint throws during paint while the tree still builds. Pump at
    // a real phone size and fail on any paint exception or overflow.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    for (final page in <Widget>[const NoacPage(), const TbPage()]) {
      await pumpPage(tester, page);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CitationLink), findsWidgets);
      expect(tester.takeException(), isNull);

      // Each link must be tappable, not collapsed to nothing.
      for (final e in find.byType(CitationLink).evaluate()) {
        final size = e.size!;
        expect(size.height, greaterThan(16));
        expect(size.width, greaterThan(100));
      }
    }
  });

  testWidgets('tapping a citation asks the platform to open its url',
      (tester) async {
    // url_launcher goes through a platform channel that no-ops in tests, so
    // record the call instead: a tap must reach launchUrl with the right url.
    final calls = <String>[];
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      if (call.method == 'launch' || call.method == 'canLaunch') {
        calls.add(call.arguments['url'] as String);
      }
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    // A tall viewport, because the citations sit below a full input form and
    // tap() refuses a target that is off-screen.
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await pumpPage(tester, const NoacPage());
    await tester.ensureVisible(find.byType(CitationLink).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CitationLink).first);
    await tester.pumpAndSettle();

    expect(calls, isNotEmpty, reason: 'tap did not reach url_launcher');
    expect(calls.first, 'https://pubmed.ncbi.nlm.nih.gov/33895845/');
  });
}
