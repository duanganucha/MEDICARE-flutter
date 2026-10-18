import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/tb.dart';
import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

/// TB tab: adult tablet picking, or paediatric mg/kg plus syrup volume.
class TbPage extends StatefulWidget {
  const TbPage({super.key});

  @override
  State<TbPage> createState() => _TbPageState();
}

class _TbPageState extends State<TbPage> {
  final _adultWeight = TextEditingController();
  final _adultDays = TextEditingController(text: '7');
  final _childWeight = TextEditingController();
  final _childAge = TextEditingController();

  bool _adultMode = true;
  List<AdultDrugDose>? _adultResult;
  ChildRegimen? _childResult;

  @override
  void dispose() {
    _adultWeight.dispose();
    _adultDays.dispose();
    _childWeight.dispose();
    _childAge.dispose();
    super.dispose();
  }

  void _calcAdult() {
    final w = double.tryParse(_adultWeight.text.trim());
    if (w == null || w <= 0) {
      _complain('กรุณากรอกน้ำหนักตัวให้ถูกต้อง');
      setState(() => _adultResult = null);
      return;
    }
    final days = int.tryParse(_adultDays.text.trim()) ?? 7;
    setState(() {
      _adultResult = adultRegimen(weight: w, days: days);
    });
  }

  void _calcChild() {
    final w = double.tryParse(_childWeight.text.trim());
    if (w == null || w <= 0) {
      _complain('กรุณากรอกน้ำหนักเด็กให้ถูกต้อง');
      setState(() => _childResult = null);
      return;
    }
    setState(() {
      _childResult = childRegimen(weight: w);
    });
  }

  /// Replaces the web app's blocking `alert()`.
  void _complain(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: context.dose.bad,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _setMode(bool adult) {
    setState(() => _adultMode = adult);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [if (_adultMode) _adultCard() else _childCard()],
    );
  }

  Widget _adultCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle('ข้อมูลผู้ป่วย'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: 'ผู้ใหญ่ (≥15 ปี)',
                  icon: Icons.person_rounded,
                  selected: _adultMode,
                  onTap: () => _setMode(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeButton(
                  label: 'เด็ก (<15 ปี)',
                  icon: Icons.child_care_rounded,
                  selected: !_adultMode,
                  onTap: () => _setMode(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _TwoUp(
            left: _NumberField(
              label: 'น้ำหนักตัว (กก.)',
              controller: _adultWeight,
              hint: 'เช่น 60',
              suffix: 'กก.',
              decimal: true,
            ),
            right: _NumberField(
              label: 'จำนวนวัน',
              controller: _adultDays,
              hint: '7',
              suffix: 'วัน',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _calcAdult,
            child: const _ButtonLabel('คำนวณยาเดี่ยวผู้ใหญ่'),
          ),
          if (_adultResult != null)
            for (final (i, d) in _adultResult!.indexed)
              FadeSlideIn(
                key: ValueKey('${d.name}-${d.targetMg}-${d.days}'),
                delay: Duration(milliseconds: i * 90),
                child: _adultDrugCard(d),
              ),
        ],
      ),
    );
  }

  Widget _adultDrugCard(AdultDrugDose d) {
    final c = context.dose;
    final muted = TextStyle(color: c.muted, fontSize: 14, height: 1.6);

    // One line per stocked strength that is actually dispensed.
    final chosen = <TextSpan>[];
    for (var i = 0; i < d.strengths.length; i++) {
      final count = d.pick.counts[i];
      if (count == 0) continue;
      if (chosen.isNotEmpty) chosen.add(const TextSpan(text: ' + '));
      chosen.addAll([
        TextSpan(text: '${d.label} ${d.strengths[i]} มก. × '),
        highlight('$count เม็ด/วัน', c.ok),
        TextSpan(text: ' (รวม ${count * d.days} เม็ด)'),
      ]);
    }

    return DrugCard(
      name: d.name,
      dose: '',
      details: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text.rich(
          TextSpan(
            style: muted,
            children: [
              const TextSpan(text: 'ขนาดแนะนำ: '),
              highlight('${d.targetMg.toStringAsFixed(0)} มก./วัน', c.ok),
              const TextSpan(text: '\nเลือกใช้: '),
              ...chosen,
              const TextSpan(text: '\nรวมจริง: '),
              highlight('${_trim(d.pick.total)} มก./วัน', c.ok),
              if (d.pick.difference > 0)
                TextSpan(
                  text:
                      ' (ต่างจากเป้าหมาย ${d.isOver ? '+' : '−'}'
                      '${d.pick.difference.toStringAsFixed(0)} มก.)',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _childCard() {
    final c = context.dose;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle('ข้อมูลผู้ป่วย'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: 'ผู้ใหญ่ (≥15 ปี)',
                  icon: Icons.person_rounded,
                  selected: _adultMode,
                  onTap: () => _setMode(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeButton(
                  label: 'เด็ก (<15 ปี)',
                  icon: Icons.child_care_rounded,
                  selected: !_adultMode,
                  onTap: () => _setMode(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _TwoUp(
            left: _NumberField(
              label: 'น้ำหนักเด็ก (กก.)',
              controller: _childWeight,
              hint: 'เช่น 14',
              suffix: 'กก.',
              decimal: true,
            ),
            right: _NumberField(
              label: 'อายุ (ปี)',
              controller: _childAge,
              hint: 'เช่น 4',
              suffix: 'ปี',
              decimal: true,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _calcChild,
            child: const _ButtonLabel('คำนวณยาเด็กและยาน้ำ'),
          ),
          if (_childResult != null) ...[
            for (final (i, d) in _childResult!.doses.indexed)
              FadeSlideIn(
                key: ValueKey('${d.name}-${d.targetMg}'),
                delay: Duration(milliseconds: i * 90),
                child: DrugCard(
                  name: d.name,
                  dose: '',
                  details: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(color: c.muted, fontSize: 14),
                        children: [
                          const TextSpan(text: 'ขนาดที่ต้องการ: '),
                          highlight(
                            '${d.targetMg.toStringAsFixed(1)} มก./วัน',
                            c.ok,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            FadeSlideIn(
              key: ValueKey(_childResult!.syrupMlPerDay),
              delay: const Duration(milliseconds: 380),
              child: _syrupBox(_childResult!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _syrupBox(ChildRegimen r) {
    final c = context.dose;
    final muted = TextStyle(color: c.muted, fontSize: 14, height: 1.6);
    return Container(
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
              style: muted,
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
    );
  }

  /// Drops the trailing ".0" so whole milligrams read as integers.
  String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

/// Segmented adult/child selector: a lilac chip when active.
class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dose;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? c.primaryBg : c.soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary.withValues(alpha: .35) : c.line,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? scheme.primary : c.muted),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? scheme.primary : c.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Button text with the trailing arrow used throughout the mockup.
class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: Text(text, textAlign: TextAlign.center)),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward_rounded, size: 19),
      ],
    );
  }
}

/// Side-by-side fields that stack on narrow screens, like the CSS `.row`.
class _TwoUp extends StatelessWidget {
  const _TwoUp({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(children: [left, right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.hint,
    this.suffix,
    this.decimal = false,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

  /// Unit shown inside the field, e.g. "กก.".
  final String? suffix;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: decimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(hintText: hint, suffixText: suffix),
        ),
      ],
    );
  }
}
