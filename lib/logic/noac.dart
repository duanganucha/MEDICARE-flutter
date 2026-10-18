/// NOAC (AF) dosing logic — 2021 EHRA Practical Guide.
///
/// Pure Dart: no Flutter imports, so every rule here is unit-testable.
library;

enum Sex { male, female }

/// Severity of a recommendation, drives the colour of the result card.
enum DoseFlag {
  /// Standard dose, no adjustment triggered.
  standard,

  /// Dose was reduced per the reference table.
  reduced,

  /// Usable but needs close monitoring.
  caution,

  /// Not recommended / contraindicated — no dose is shown.
  avoid,
}

/// One drug's recommendation.
class DoseResult {
  const DoseResult({
    required this.name,
    required this.dose,
    required this.reason,
    required this.flag,
  });

  final String name;

  /// The dose text, or a "not recommended" phrase when [flag] is
  /// [DoseFlag.avoid].
  final String dose;
  final String reason;
  final DoseFlag flag;
}

/// The whole assessment for one patient.
class NoacAssessment {
  const NoacAssessment({
    required this.crCl,
    required this.belowThreshold,
    required this.results,
    this.thresholdNote,
  });

  /// Creatinine clearance in mL/min.
  final double crCl;

  /// True when CrCl < 15 mL/min — outside the guideline, no doses given.
  final bool belowThreshold;
  final List<DoseResult> results;
  final String? thresholdNote;
}

/// Cockcroft–Gault creatinine clearance, mL/min.
///
/// [age] in years, [weight] in kg, [scr] serum creatinine in **mg/dL**
/// (not µmol/L). Female sex applies the 0.85 multiplier.
double cockcroftGault({
  required int age,
  required double weight,
  required double scr,
  required Sex sex,
}) {
  final factor = sex == Sex.female ? 0.85 : 1.0;
  return ((140 - age) * weight * factor) / (72 * scr);
}

/// Evaluates all four NOACs for one patient.
///
/// [increasedGiBleedRisk] only affects dabigatran, matching EHRA's table.
NoacAssessment assessNoacs({
  required int age,
  required double weight,
  required double scr,
  required Sex sex,
  required bool increasedGiBleedRisk,
}) {
  final crCl = cockcroftGault(age: age, weight: weight, scr: scr, sex: sex);

  if (crCl < 15) {
    return NoacAssessment(
      crCl: crCl,
      belowThreshold: true,
      thresholdNote:
          'CrCl <15 mL/min: อยู่นอกกรอบคำแนะนำมาตรฐานของ NOACs '
          'ประสิทธิผลและความปลอดภัยยังไม่ชัดเจน ต้องปรึกษาผู้เชี่ยวชาญ',
      results: const [
        DoseResult(
          name: 'Apixaban ใน CrCl <15 mL/min',
          dose: 'ไม่แสดงขนาดยา',
          reason:
              'EHRA 2021 ไม่แนะนำให้ใช้ NOACs เมื่อ CrCl <15 mL/min และผู้ป่วย'
              'กลุ่มนี้ไม่ได้อยู่ในการศึกษาหลัก (ARISTOTLE ไม่รวมผู้ที่ CrCl <25) '
              'หากแพทย์พิจารณาใช้ apixaban (เช่น ผู้ป่วยฟอกไต) ต้องมีการตัดสินใจ'
              'ร่วมกับผู้เชี่ยวชาญและติดตามอย่างใกล้ชิด ระบบนี้จึงไม่แสดงขนาดยา',
          flag: DoseFlag.avoid,
        ),
      ],
    );
  }

  return NoacAssessment(
    crCl: crCl,
    belowThreshold: false,
    results: [
      _apixaban(crCl: crCl, age: age, weight: weight, scr: scr),
      _rivaroxaban(crCl),
      _edoxaban(crCl: crCl, weight: weight),
      _dabigatran(crCl: crCl, age: age, giRisk: increasedGiBleedRisk),
    ],
  );
}

DoseResult _apixaban({
  required double crCl,
  required int age,
  required double weight,
  required double scr,
}) {
  // Two of three criteria trigger the reduced dose.
  final criteria = <String>[
    if (age >= 80) 'อายุ ≥80 ปี',
    if (weight <= 60) 'น้ำหนัก ≤60 kg',
    if (scr >= 1.5) 'SCr ≥1.5 mg/dL',
  ];

  var dose = '5 mg วันละ 2 ครั้ง (Standard)';
  var reason = 'ไม่เข้าเกณฑ์ลดขนาด (ต้องเข้าข่าย ≥2 ข้อ)';
  var reduced = false;

  if (crCl <= 29) {
    dose = '2.5 mg วันละ 2 ครั้ง';
    reason = 'CrCl อยู่ในช่วง 15–29 mL/min';
    reduced = true;
  } else if (criteria.length >= 2) {
    dose = '2.5 mg วันละ 2 ครั้ง';
    reason =
        'เข้าเกณฑ์ลดขนาด ${criteria.length}/3 ข้อ (${criteria.join(", ")})';
    reduced = true;
  }

  return DoseResult(
    name: 'Apixaban (Eliquis)',
    dose: dose,
    reason: reason,
    flag: reduced ? DoseFlag.reduced : DoseFlag.standard,
  );
}

DoseResult _rivaroxaban(double crCl) {
  final reduced = crCl < 50;
  return DoseResult(
    name: 'Rivaroxaban (Xarelto)',
    dose: reduced
        ? '15 mg วันละ 1 ครั้ง (พร้อมอาหาร)'
        : '20 mg วันละ 1 ครั้ง (พร้อมอาหาร)',
    reason: reduced ? 'CrCl 15–49 mL/min ลดขนาดตามตาราง' : 'CrCl ≥50 mL/min',
    flag: reduced ? DoseFlag.reduced : DoseFlag.standard,
  );
}

DoseResult _edoxaban({required double crCl, required double weight}) {
  final reasons = <String>[
    if (crCl <= 49) 'CrCl 15–49 mL/min',
    if (weight <= 60) 'น้ำหนัก ≤60 kg',
  ];
  // Whether the dose drops is decided before the >95 warning is appended,
  // since that warning is about reduced efficacy, not a dose reduction.
  final lowDose = reasons.isNotEmpty;
  if (crCl > 95) {
    reasons.add('CrCl >95 mL/min (ควรระวังประสิทธิผลลดลงตามคำเตือน EMA)');
  }

  return DoseResult(
    name: 'Edoxaban (Lixiana)',
    dose: lowDose ? '30 mg วันละ 1 ครั้ง' : '60 mg วันละ 1 ครั้ง',
    reason: reasons.isEmpty ? 'ไม่เข้าเกณฑ์ลดขนาด' : reasons.join(', '),
    flag: reasons.isEmpty ? DoseFlag.standard : DoseFlag.reduced,
  );
}

DoseResult _dabigatran({
  required double crCl,
  required int age,
  required bool giRisk,
}) {
  if (crCl < 30) {
    return const DoseResult(
      name: 'Dabigatran (Pradaxa)',
      dose: 'ไม่แนะนำ / ห้ามใช้',
      reason:
          'CrCl <30 mL/min (ถูกขับทางไตประมาณ 80% เสี่ยงสะสมยาและเลือดออก) '
          'ควรเลือก NOACs ตัวอื่นหรือปรึกษาผู้เชี่ยวชาญ',
      flag: DoseFlag.avoid,
    );
  }

  final lowDoseReasons = <String>[
    if (age >= 80) 'อายุ ≥80 ปี',
    if (giRisk) 'มีความเสี่ยงเลือดออกทางเดินอาหารเพิ่มขึ้น',
  ];
  final cautionNote = crCl < 50
      ? ' ⚠ CrCl 30–49 mL/min: ใช้ด้วยความระมัดระวัง '
            'ติดตามการทำงานของไตและความเสี่ยงเลือดออกอย่างใกล้ชิด'
      : '';
  final base = lowDoseReasons.isNotEmpty
      ? 'แนะนำ 110 mg เนื่องจาก: ${lowDoseReasons.join(", ")}'
      : 'พิจารณาระหว่าง 150 หรือ 110 mg ตามความเสี่ยงเลือดออก/ลิ่มเลือด';

  return DoseResult(
    name: 'Dabigatran (Pradaxa)',
    dose: lowDoseReasons.isNotEmpty
        ? '110 mg วันละ 2 ครั้ง'
        : '150 mg หรือ 110 mg วันละ 2 ครั้ง',
    reason: base + cautionNote,
    flag: crCl < 50
        ? DoseFlag.caution
        : lowDoseReasons.isNotEmpty
        ? DoseFlag.reduced
        : DoseFlag.standard,
  );
}
