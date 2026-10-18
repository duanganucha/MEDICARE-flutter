import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/noac.dart';
import 'motion.dart';
import 'theme.dart';
import 'widgets.dart';

/// NOAC comparison tab: patient inputs, then all four drugs side by side.
class NoacPage extends StatefulWidget {
  const NoacPage({super.key});

  @override
  State<NoacPage> createState() => _NoacPageState();
}

class _NoacPageState extends State<NoacPage> {
  final _formKey = GlobalKey<FormState>();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _scrCtrl = TextEditingController();
  final _ageFocus = FocusNode();
  final _resultKey = GlobalKey();

  Sex? _sex;
  bool _giRisk = false;
  bool _scopeAck = false;
  bool _stableAck = false;

  /// Set once the user submits, so the checkbox errors stay hidden until then.
  bool _submitted = false;
  NoacAssessment? _assessment;

  @override
  void dispose() {
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _scrCtrl.dispose();
    _ageFocus.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    final formOk = _formKey.currentState!.validate();
    if (!formOk || !_scopeAck || !_stableAck) {
      setState(() => _assessment = null);
      return;
    }

    setState(() {
      _assessment = assessNoacs(
        age: int.parse(_ageCtrl.text),
        weight: double.parse(_weightCtrl.text),
        scr: double.parse(_scrCtrl.text),
        sex: _sex!,
        increasedGiBleedRisk: _giRisk,
      );
    });

    // Let the result card lay out before scrolling it into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
      }
    });
  }

  void _reset() {
    setState(() {
      _formKey.currentState!.reset();
      _ageCtrl.clear();
      _weightCtrl.clear();
      _scrCtrl.clear();
      _sex = null;
      _giRisk = false;
      _scopeAck = false;
      _stableAck = false;
      _submitted = false;
      _assessment = null;
    });
    _ageFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final dose = context.dose;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CardTitle('ข้อมูลทางคลินิก (EHRA 2021)'),
                const FieldLabel('อายุเต็มปี'),
                TextFormField(
                  controller: _ageCtrl,
                  focusNode: _ageFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'เช่น 75',
                    suffixIcon: UnitLabel('ปี'),
                  ),
                  validator: (v) =>
                      _validateRange(v, 18, 120, 'อายุ 18–120 ปี'),
                ),
                const FieldLabel('น้ำหนักตัว (kg)'),
                TextFormField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'เช่น 65',
                    suffixIcon: UnitLabel('kg'),
                  ),
                  validator: (v) =>
                      _validateRange(v, 1, 400, 'น้ำหนัก 1–400 kg'),
                ),
                const FieldLabel('เพศ (สูตร Cockcroft–Gault)'),
                DropdownButtonFormField<Sex>(
                  initialValue: _sex,
                  hint: const Text('-- กรุณาเลือก --'),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: Sex.male,
                      child: Text(
                        'ชาย — ตัวคูณ 1',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: Sex.female,
                      child: Text(
                        'หญิง — ตัวคูณ 0.85',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _sex = v),
                  validator: (v) => v == null ? 'กรุณาเลือกเพศ' : null,
                ),
                const FieldLabel('Serum creatinine (mg/dL)'),
                TextFormField(
                  controller: _scrCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'เช่น 1.2',
                    suffixIcon: UnitLabel('mg/dL'),
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n < 0.01) return 'กรุณากรอกค่าที่ถูกต้อง';
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'กรอกหน่วย mg/dL เท่านั้น (ห้ามกรอก µmol/L)',
                    style: TextStyle(color: dose.muted, fontSize: 14),
                  ),
                ),
                const FieldLabel(
                  'ความเสี่ยงเลือดออกทางเดินอาหารเพิ่มขึ้น '
                  '(มีผลต่อ Dabigatran)',
                ),
                DropdownButtonFormField<bool>(
                  initialValue: _giRisk,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: false,
                      child: Text(
                        'ไม่พบความเสี่ยงสูง',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: true,
                      child: Text(
                        'มี — ประเมินว่ามีความเสี่ยงสูง',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _giRisk = v ?? false),
                ),
                const SizedBox(height: 16),
                _AckCheckbox(
                  value: _scopeAck,
                  showError: _submitted && !_scopeAck,
                  onChanged: (v) => setState(() => _scopeAck = v),
                  label:
                      'ผู้ป่วยเป็นผู้ใหญ่ที่มี AF เพื่อป้องกัน stroke และไม่มี'
                      'ข้อห้ามหลัก (mechanical heart valve, mitral stenosis '
                      'ปานกลาง-รุนแรง, เลือดออกกำลังดำเนินอยู่, ตั้งครรภ์)',
                ),
                const SizedBox(height: 10),
                _AckCheckbox(
                  value: _stableAck,
                  showError: _submitted && !_stableAck,
                  onChanged: (v) => setState(() => _stableAck = v),
                  label: 'การทำงานของไตคงที่ ไม่มี AKI หรือฟอกไต',
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submit,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'ประเมินและเปรียบเทียบขนาดยา NOACs',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _reset,
                  child: const Text('+ ผู้ป่วยรายใหม่'),
                ),
              ],
            ),
          ),
        ),
        if (_assessment != null) _results(_assessment!),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Center(
            child: Text(
              'อ้างอิง: 2021 EHRA Practical Guide on the Use of NOACs '
              'in Patients with AF',
              textAlign: TextAlign.center,
              style: TextStyle(color: dose.muted, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _results(NoacAssessment a) {
    return FadeSlideIn(
      // Keyed by the result so each assessment replays the entrance.
      key: ValueKey(a),
      child: AppCard(
        key: _resultKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardTitle('ผลการประเมินและเปรียบเทียบขนาดยา'),
            StatBox(
              label: 'ค่า CrCl (Cockcroft–Gault)',
              crCl: a.crCl,
              unit: 'mL/min',
            ),
            if (a.thresholdNote != null) ...[
              const SizedBox(height: 10),
              WarningBanner(body: a.thresholdNote!),
            ],
            for (final (i, r) in a.results.indexed)
              FadeSlideIn(
                // Each card trails the one above it.
                delay: Duration(milliseconds: 120 + i * 90),
                child: DrugCard(
                  name: r.name,
                  // Below the 15 mL/min threshold the guideline gives no
                  // dose, so the headline is dropped and only the
                  // explanation remains.
                  dose: a.belowThreshold ? '' : r.dose,
                  reason: r.reason,
                  reasonLabel: a.belowThreshold ? '' : 'เหตุผล: ',
                  flag: r.flag,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _validateRange(String? v, num min, num max, String message) {
    final n = num.tryParse(v?.trim() ?? '');
    if (n == null || n < min || n > max) return message;
    return null;
  }
}

/// Checkbox the pharmacist must tick to confirm the patient is in scope.
class _AckCheckbox extends StatelessWidget {
  const _AckCheckbox({
    required this.value,
    required this.label,
    required this.onChanged,
    required this.showError,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final dose = context.dose;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: dose.soft,
          border: Border.all(color: showError ? dose.bad : dose.line),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14.5, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
