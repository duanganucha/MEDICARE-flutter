// Screenshot entry point: boots the app straight into a given screen so
// store screenshots can be captured without driving the UI.
//
//   flutter run --dart-define=SHOT=noac_result -t lib/main_shots.dart
//
// Not part of the shipped app; main.dart remains the real entry point.
import 'package:flutter/material.dart';

import 'logic/noac.dart';
import 'logic/tb.dart';
import 'ui/brand.dart';
import 'ui/noac_page.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';
import 'ui/header.dart';

const _shot = String.fromEnvironment('SHOT', defaultValue: 'noac_form');

void main() => runApp(const _ShotApp());

class _ShotApp extends StatelessWidget {
  const _ShotApp();

  @override
  Widget build(BuildContext context) {
    final brand = _shot.endsWith('_teal') ? Brand.teal : Brand.plum;
    return BrandScope(
      brand: brand,
      onChanged: (_) {},
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light, brand),
        home: const _ShotScaffold(),
      ),
    );
  }
}

class _ShotScaffold extends StatelessWidget {
  const _ShotScaffold();

  @override
  Widget build(BuildContext context) {
    final c = context.dose;
    return Scaffold(
      backgroundColor: c.headerBottom,
      body: Column(
        children: [
          AppHeader(topInset: MediaQuery.paddingOf(context).top),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -18),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
                    child: _body(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    switch (_shot) {
      case 'noac_result':
      case 'noac_result_teal':
        return _NoacResult();
      case 'tb_adult':
        return _TbAdult();
      case 'tb_child':
        return _TbChild();
      default:
        return const NoacPage();
    }
  }
}

/// The same assessment the Android screenshots use: 85y, 55kg, male, SCr 1.0.
class _NoacResult extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final a = assessNoacs(
      age: 85,
      weight: 55,
      scr: 1.0,
      sex: Sex.male,
      increasedGiBleedRisk: false,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle('ผลการประเมินและเปรียบเทียบขนาดยา'),
          StatBox(
            label: 'ค่า CrCl (Cockcroft–Gault)',
            crCl: a.crCl,
            unit: 'mL/min',
          ),
          for (final r in a.results)
            DrugCard(
              name: r.name,
              dose: r.dose,
              reason: r.reason,
              flag: r.flag,
            ),
        ],
      ),
    );
  }
}

class _TbAdult extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.dose;
    final doses = adultRegimen(weight: 52, days: 7);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle('ยาวัณโรค — ผู้ใหญ่ 52 กก.'),
          for (final d in doses)
            DrugCard(
              name: d.name,
              dose: '',
              details: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(color: c.muted, fontSize: 14, height: 1.6),
                    children: [
                      const TextSpan(text: 'ขนาดแนะนำ: '),
                      highlight('${d.targetMg.toStringAsFixed(0)} มก./วัน', c.ok),
                      const TextSpan(text: '\nเลือกใช้: '),
                      for (var i = 0; i < d.strengths.length; i++)
                        if (d.pick.counts[i] > 0) ...[
                          TextSpan(text: '${d.label} ${d.strengths[i]} มก. × '),
                          highlight('${d.pick.counts[i]} เม็ด/วัน', c.ok),
                        ],
                      const TextSpan(text: '\nรวมจริง: '),
                      highlight('${d.pick.total.toStringAsFixed(0)} มก./วัน', c.ok),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TbChild extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.dose;
    final r = childRegimen(weight: 14);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle('ยาวัณโรค — เด็ก 14 กก.'),
          for (final d in r.doses)
            DrugCard(
              name: d.name,
              dose: '',
              details: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(color: c.muted, fontSize: 14),
                    children: [
                      const TextSpan(text: 'ขนาดที่ต้องการ: '),
                      highlight('${d.targetMg.toStringAsFixed(1)} มก./วัน', c.ok),
                    ],
                  ),
                ),
              ),
            ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: c.okBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.ok, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Isoniazid syrup (10 mg/ml)',
                  style: TextStyle(
                    color: c.ok,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: TextStyle(color: c.muted, fontSize: 14, height: 1.6),
                    children: [
                      const TextSpan(text: 'ปริมาตรต่อวัน: '),
                      highlight('${r.syrupMlPerDay.toStringAsFixed(1)} มล.', c.ok),
                      const TextSpan(text: '\nขวดละ 60 มล.: ประมาณ '),
                      highlight('${r.bottlesPerDay.toStringAsFixed(2)} ขวด', c.ok),
                      const TextSpan(text: ' ต่อวัน'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
