import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/logic/noac.dart';

/// Finds one drug's result by the prefix of its name.
DoseResult drug(NoacAssessment a, String prefix) =>
    a.results.firstWhere((r) => r.name.startsWith(prefix));

NoacAssessment assess({
  int age = 60,
  double weight = 80,
  double scr = 1.0,
  Sex sex = Sex.male,
  bool gi = false,
}) => assessNoacs(
  age: age,
  weight: weight,
  scr: scr,
  sex: sex,
  increasedGiBleedRisk: gi,
);

void main() {
  group('Cockcroft–Gault', () {
    test('male uses a multiplier of 1', () {
      // (140-60)*80/(72*1.0) = 88.888...
      expect(
        cockcroftGault(age: 60, weight: 80, scr: 1.0, sex: Sex.male),
        closeTo(88.89, 0.01),
      );
    });

    test('female applies the 0.85 multiplier', () {
      expect(
        cockcroftGault(age: 60, weight: 80, scr: 1.0, sex: Sex.female),
        closeTo(75.56, 0.01),
      );
    });

    test('clearance falls as creatinine rises', () {
      final low = cockcroftGault(age: 75, weight: 65, scr: 1.0, sex: Sex.male);
      final high = cockcroftGault(age: 75, weight: 65, scr: 2.0, sex: Sex.male);
      expect(high, lessThan(low));
    });
  });

  group('CrCl below 15 mL/min', () {
    // age 85, 50 kg, SCr 4.0 → (140-85)*50/(72*4) = 9.55
    final a = assess(age: 85, weight: 50, scr: 4.0);

    test('is flagged as outside the guideline', () {
      expect(a.crCl, lessThan(15));
      expect(a.belowThreshold, isTrue);
      expect(a.thresholdNote, isNotNull);
    });

    test('shows no doses at all', () {
      expect(a.results, hasLength(1));
      expect(a.results.single.flag, DoseFlag.avoid);
    });
  });

  group('Apixaban', () {
    test('standard 5 mg when no criterion is met', () {
      final r = drug(assess(), 'Apixaban');
      expect(r.dose, contains('5 mg'));
      expect(r.flag, DoseFlag.standard);
    });

    test('one criterion alone does not reduce the dose', () {
      // 85 years old but 80 kg and normal SCr → 1 of 3 only.
      final r = drug(assess(age: 85, weight: 80, scr: 1.0), 'Apixaban');
      expect(r.dose, contains('5 mg'));
      expect(r.flag, DoseFlag.standard);
    });

    test('two criteria reduce the dose to 2.5 mg', () {
      // age 85 + weight 55 → 2 of 3; CrCl = (140-85)*55/72 = 42 (above 29).
      final a = assess(age: 85, weight: 55, scr: 1.0);
      expect(a.crCl, greaterThan(29));
      final r = drug(a, 'Apixaban');
      expect(r.dose, contains('2.5 mg'));
      expect(r.reason, contains('2/3'));
      expect(r.flag, DoseFlag.reduced);
    });

    test('CrCl 15–29 reduces the dose regardless of criteria', () {
      // (140-70)*70/(72*2.6) = 26.2
      final a = assess(age: 70, weight: 70, scr: 2.6);
      expect(a.crCl, inInclusiveRange(15, 29));
      final r = drug(a, 'Apixaban');
      expect(r.dose, contains('2.5 mg'));
      expect(r.reason, contains('15–29'));
    });
  });

  group('Rivaroxaban', () {
    test('20 mg at CrCl 50 or above', () {
      final r = drug(assess(), 'Rivaroxaban');
      expect(r.dose, contains('20 mg'));
      expect(r.flag, DoseFlag.standard);
    });

    test('15 mg below CrCl 50', () {
      // (140-75)*60/(72*1.8) = 30.1
      final a = assess(age: 75, weight: 60, scr: 1.8);
      expect(a.crCl, lessThan(50));
      final r = drug(a, 'Rivaroxaban');
      expect(r.dose, contains('15 mg'));
      expect(r.flag, DoseFlag.reduced);
    });
  });

  group('Edoxaban', () {
    test('60 mg when no criterion is met', () {
      final r = drug(assess(), 'Edoxaban');
      expect(r.dose, contains('60 mg'));
    });

    test('30 mg on low weight alone', () {
      // 55 kg, CrCl = (140-50)*55/72 = 68.75 → weight is the only trigger.
      final a = assess(age: 50, weight: 55, scr: 1.0);
      expect(a.crCl, greaterThan(49));
      final r = drug(a, 'Edoxaban');
      expect(r.dose, contains('30 mg'));
    });

    test('CrCl above 95 keeps 60 mg but carries the EMA warning', () {
      // (140-30)*95/(72*1.0) = 145 → very high clearance, weight above 60.
      final a = assess(age: 30, weight: 95, scr: 1.0);
      expect(a.crCl, greaterThan(95));
      final r = drug(a, 'Edoxaban');
      expect(r.dose, contains('60 mg'));
      expect(r.reason, contains('EMA'));
    });
  });

  group('Dabigatran', () {
    test('either strength when renal function and age are fine', () {
      final r = drug(assess(), 'Dabigatran');
      expect(r.dose, contains('150 mg'));
      expect(r.flag, DoseFlag.standard);
    });

    test('contraindicated below CrCl 30', () {
      final a = assess(age: 70, weight: 70, scr: 2.6);
      expect(a.crCl, lessThan(30));
      final r = drug(a, 'Dabigatran');
      expect(r.flag, DoseFlag.avoid);
      expect(r.dose, contains('ไม่แนะนำ'));
    });

    test('CrCl 30–49 is usable but flagged for caution', () {
      // (140-75)*60/(72*1.8) = 30.1
      final a = assess(age: 75, weight: 60, scr: 1.8);
      expect(a.crCl, inInclusiveRange(30, 49));
      final r = drug(a, 'Dabigatran');
      expect(r.flag, DoseFlag.caution);
      expect(r.reason, contains('30–49'));
    });

    test('age 80 or over prefers 110 mg', () {
      // 85 years, 80 kg, SCr 1.0 → CrCl = 61, above the caution band.
      final a = assess(age: 85, weight: 80, scr: 1.0);
      expect(a.crCl, greaterThan(50));
      final r = drug(a, 'Dabigatran');
      expect(r.dose, contains('110 mg'));
      expect(r.reason, contains('≥80'));
    });

    test('GI bleed risk prefers 110 mg and only affects this drug', () {
      final plain = assess();
      final risky = assess(gi: true);
      expect(drug(risky, 'Dabigatran').dose, contains('110 mg'));
      expect(drug(risky, 'Dabigatran').reason, contains('ทางเดินอาหาร'));
      // The other three are untouched by the GI flag.
      for (final name in ['Apixaban', 'Rivaroxaban', 'Edoxaban']) {
        expect(drug(risky, name).dose, drug(plain, name).dose);
      }
    });
  });

  test('a normal patient gets all four drugs', () {
    expect(assess().results, hasLength(4));
  });
}
