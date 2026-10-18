import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/logic/tb.dart';

AdultDrugDose find(List<AdultDrugDose> doses, String prefix) =>
    doses.firstWhere((d) => d.name.startsWith(prefix));

void main() {
  group('pickTablets', () {
    test('hits an exact target with a single strength', () {
      final pick = pickTablets(
        target: 300,
        strengths: [100],
        maxTotal: 300,
        maxTablets: 4,
      )!;
      expect(pick.counts, [3]);
      expect(pick.total, 300);
      expect(pick.difference, 0);
    });

    test('prefers one strength over mixing when both land equally close', () {
      // 600 is reachable as 2×300 or as 300+450+... ; the single strength wins.
      final pick = pickTablets(
        target: 600,
        strengths: [300, 450],
        maxTotal: 600,
        maxTablets: 4,
      )!;
      expect(pick.counts, [2, 0]);
      expect(pick.total, 600);
    });

    test('never exceeds the maximum daily dose', () {
      final pick = pickTablets(
        target: 2000,
        strengths: [500],
        maxTotal: 2000,
        maxTablets: 4,
      )!;
      expect(pick.total, lessThanOrEqualTo(2000));
      expect(pick.counts, [4]);
    });

    test('mixes strengths when that lands closer', () {
      // 750 = 300 + 450 exactly.
      final pick = pickTablets(
        target: 750,
        strengths: [300, 450],
        maxTotal: 1200,
        maxTablets: 4,
      )!;
      expect(pick.total, 750);
      expect(pick.counts, [1, 1]);
    });

    test('returns null when even one tablet breaks the cap', () {
      expect(
        pickTablets(
          target: 50,
          strengths: [500],
          maxTotal: 100,
          maxTablets: 4,
        ),
        isNull,
      );
    });

    test('always dispenses at least one tablet', () {
      final pick = pickTablets(
        target: 10,
        strengths: [100],
        maxTotal: 300,
        maxTablets: 4,
      )!;
      expect(pick.counts.reduce((a, b) => a + b), greaterThanOrEqualTo(1));
    });
  });

  group('adultRegimen', () {
    test('covers all four first-line drugs', () {
      final r = adultRegimen(weight: 60, days: 7);
      expect(r.map((d) => d.name), [
        'Isoniazid (H)',
        'Rifampicin (R)',
        'Pyrazinamide (Z)',
        'Ethambutol (E)',
      ]);
    });

    test('applies mg/kg at 60 kg', () {
      final r = adultRegimen(weight: 60, days: 7);
      expect(find(r, 'Isoniazid').targetMg, 300); // 5 mg/kg, at the cap
      expect(find(r, 'Rifampicin').targetMg, 600); // 10 mg/kg, at the cap
      expect(find(r, 'Pyrazinamide').targetMg, 1500); // 25 mg/kg
      expect(find(r, 'Ethambutol').targetMg, 1200); // 20 mg/kg, at the cap
    });

    test('caps every drug at its maximum for a heavy patient', () {
      final r = adultRegimen(weight: 120, days: 7);
      expect(find(r, 'Isoniazid').targetMg, 300);
      expect(find(r, 'Rifampicin').targetMg, 600);
      expect(find(r, 'Pyrazinamide').targetMg, 2000);
      expect(find(r, 'Ethambutol').targetMg, 1200);
    });

    test('scales below the caps for a light patient', () {
      final r = adultRegimen(weight: 40, days: 7);
      expect(find(r, 'Isoniazid').targetMg, 200);
      expect(find(r, 'Rifampicin').targetMg, 400);
      expect(find(r, 'Pyrazinamide').targetMg, 1000);
      expect(find(r, 'Ethambutol').targetMg, 800);
    });

    test('day count drives the dispensed total', () {
      final r = adultRegimen(weight: 60, days: 14);
      final inh = find(r, 'Isoniazid');
      expect(inh.days, 14);
      expect(inh.pick.counts[0], 3); // 3 × 100 mg
    });

    test('isOver reports the direction of any mismatch', () {
      final r = adultRegimen(weight: 50, days: 7);
      for (final d in r) {
        if (d.pick.difference > 0) {
          expect(d.isOver, d.pick.total > d.targetMg);
        }
      }
    });

    test('no drug ever exceeds its maximum daily dose', () {
      for (final w in [30.0, 45.0, 60.0, 75.0, 100.0]) {
        final r = adultRegimen(weight: w, days: 7);
        expect(find(r, 'Isoniazid').pick.total, lessThanOrEqualTo(300));
        expect(find(r, 'Rifampicin').pick.total, lessThanOrEqualTo(600));
        expect(find(r, 'Pyrazinamide').pick.total, lessThanOrEqualTo(2000));
        expect(find(r, 'Ethambutol').pick.total, lessThanOrEqualTo(1200));
      }
    });
  });

  group('childRegimen', () {
    test('uses the paediatric mg/kg rates at 14 kg', () {
      final r = childRegimen(weight: 14);
      expect(r.doses[0].targetMg, 140); // INH 10 mg/kg
      expect(r.doses[1].targetMg, 210); // RIF 15 mg/kg
      expect(r.doses[2].targetMg, closeTo(490, 0.01)); // PZA 35 mg/kg
      expect(r.doses[3].targetMg, 280); // EMB 20 mg/kg
    });

    test('derives syrup volume from the INH dose at 10 mg/mL', () {
      final r = childRegimen(weight: 14);
      expect(r.syrupMlPerDay, 14); // 140 mg ÷ 10 mg/mL
      expect(r.bottlesPerDay, closeTo(14 / 60, 1e-9));
    });

    test('respects the adult caps for a heavy child', () {
      final r = childRegimen(weight: 60);
      expect(r.doses[0].targetMg, 300); // INH capped
      expect(r.doses[1].targetMg, 600); // RIF capped
      expect(r.doses[2].targetMg, 2000); // PZA capped
      expect(r.doses[3].targetMg, 1200); // EMB capped
      expect(r.syrupMlPerDay, 30); // capped INH ÷ 10
    });
  });
}
