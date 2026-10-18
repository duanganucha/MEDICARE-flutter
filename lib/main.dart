import 'package:flutter/material.dart';

import 'ui/brand.dart';
import 'ui/header.dart';
import 'ui/motion.dart';
import 'ui/noac_page.dart';
import 'ui/splash_page.dart';
import 'ui/tb_page.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

void main() => runApp(const MedicareApp());

class MedicareApp extends StatefulWidget {
  const MedicareApp({super.key});

  @override
  State<MedicareApp> createState() => _MedicareAppState();
}

class _MedicareAppState extends State<MedicareApp> {
  Brand _brand = Brand.plum;

  @override
  Widget build(BuildContext context) {
    return BrandScope(
      brand: _brand,
      onChanged: (b) => setState(() => _brand = b),
      child: MaterialApp(
        title: 'MEDICARE',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light, _brand),
        darkTheme: buildTheme(Brightness.dark, _brand),
        // Colours cross-fade when the brand changes.
        themeAnimationDuration: Motion.normal,
        themeAnimationCurve: Motion.curve,
        home: const _Root(),
      ),
    );
  }
}

/// Shows the splash, then cross-fades to the app.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.slow,
      switchInCurve: Motion.curve,
      child: _ready
          ? const HomePage()
          : SplashPage(onDone: () => setState(() => _ready = true)),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.dose;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      // The header bleeds to the top edge, so no SafeArea above it.
      backgroundColor: c.headerBottom,
      body: Column(
        children: [
          AppHeader(topInset: topInset),
          // The sheet overlaps the band and carries the rest of the page.
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -18),
              child: SafeArea(
                top: false,
                // Insets the sheet so the header colour frames it on three
                // sides rather than the sheet running edge to edge.
                minimum: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: c.headerBottom.withValues(alpha: .34),
                        blurRadius: 22,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                    child: ConstrainedBox(
                      // Matches the web app's 600px reading column.
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeSlideIn(
                              child: _Tabs(
                                index: _tab,
                                onChanged: (i) => setState(() => _tab = i),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const FadeSlideIn(
                              delay: Duration(milliseconds: 70),
                              child: WarningBanner(
                                title:
                                    'เครื่องมือช่วยคำนวณ — '
                                    'ไม่ใช่คำสั่งการรักษา',
                                body:
                                    'แสดงขนาดยาตามตารางอ้างอิงเพื่อประกอบ'
                                    'การพิจารณาของผู้ประกอบวิชาชีพ '
                                    'ต้องตรวจสอบกับฉลากยา แนวทางล่าสุด '
                                    'และบริบทผู้ป่วยก่อนใช้เสมอ',
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Both tabs stay alive so inputs survive
                            // switching; the switcher only cross-fades the
                            // one on top.
                            AnimatedSwitcher(
                              duration: Motion.normal,
                              switchInCurve: Motion.curve,
                              layoutBuilder: (current, previous) => Stack(
                                alignment: Alignment.topCenter,
                                children: [...previous, ?current],
                              ),
                              child: KeyedSubtree(
                                key: ValueKey(_tab),
                                child: IndexedStack(
                                  index: _tab,
                                  children: const [NoacPage(), TbPage()],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-style tab bar matching the web app's `.tabs`.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _labels = ['NOACs (AF)', 'วัณโรค (TB)'];

  @override
  Widget build(BuildContext context) {
    final dose = context.dose;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: dose.soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: Motion.fast,
                  curve: Motion.curve,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: index == i ? dose.primaryBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: index == i
                          ? Theme.of(context).colorScheme.primary
                          : dose.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
