/// Anti-TB dosing: adult tablet picking and paediatric mg/kg targets.
///
/// Pure Dart: no Flutter imports, so every rule here is unit-testable.
library;

import 'dart:math' as math;

/// The tablet/capsule combination chosen for one drug.
class TabletPick {
  const TabletPick({
    required this.counts,
    required this.total,
    required this.difference,
  });

  /// Tablets per day, index-aligned with the strengths that were offered.
  final List<int> counts;

  /// Actual delivered dose in mg/day.
  final double total;

  /// Absolute distance from the target dose, in mg.
  final double difference;
}

/// One adult drug line: the target and the tablets that best meet it.
class AdultDrugDose {
  const AdultDrugDose({
    required this.name,
    required this.label,
    required this.targetMg,
    required this.strengths,
    required this.pick,
    required this.days,
  });

  final String name;

  /// Short dispensing label, e.g. "RIF cap".
  final String label;
  final double targetMg;

  /// Strengths available, index-aligned with [TabletPick.counts].
  final List<int> strengths;
  final TabletPick pick;
  final int days;

  /// True when the chosen tablets overshoot the target.
  bool get isOver => pick.total > targetMg;
}

/// One paediatric drug line — mg/kg target only, no tablet splitting.
class ChildDrugDose {
  const ChildDrugDose({required this.name, required this.targetMg});

  final String name;
  final double targetMg;
}

/// Paediatric result: the four drug targets plus the INH syrup volume.
class ChildRegimen {
  const ChildRegimen({
    required this.doses,
    required this.syrupMlPerDay,
    required this.bottlesPerDay,
  });

  final List<ChildDrugDose> doses;

  /// Isoniazid syrup at 10 mg/mL.
  final double syrupMlPerDay;

  /// Fraction of a 60 mL bottle used per day.
  final double bottlesPerDay;
}

/// Finds the tablet combination landing closest to [target] mg.
///
/// Searches every combination of [strengths] up to [maxTablets] tablets in
/// total, rejecting any that exceeds [maxTotal] mg. Ties break toward fewer
/// distinct strengths, then fewer tablets — a regimen the patient can
/// actually take. Returns null when nothing satisfies the limits.
TabletPick? pickTablets({
  required double target,
  required List<int> strengths,
  required double maxTotal,
  required int maxTablets,
}) {
  TabletPick? best;
  int? bestKinds;
  int? bestCount;

  void search(int i, List<int> current, double total, int count) {
    if (i == strengths.length) {
      if (count < 1 || total > maxTotal) return;
      final diff = (total - target).abs();
      final kinds = current.where((c) => c > 0).length;
      final isBetter =
          best == null ||
          diff < best!.difference - 1e-9 ||
          ((diff - best!.difference).abs() < 1e-9 &&
              (kinds < bestKinds! ||
                  (kinds == bestKinds! && count < bestCount!)));
      if (isBetter) {
        best = TabletPick(
          counts: List<int>.of(current),
          total: total,
          difference: diff,
        );
        bestKinds = kinds;
        bestCount = count;
      }
      return;
    }
    for (var c = 0; c <= maxTablets - count; c++) {
      current[i] = c;
      search(i + 1, current, total + c * strengths[i], count + c);
    }
    current[i] = 0;
  }

  search(0, List<int>.filled(strengths.length, 0), 0, 0);
  return best;
}

/// Adult regimen (≥15 years): HRZE at standard mg/kg, capped at the usual
/// maximum daily dose, dispensed from the strengths stocked on site.
List<AdultDrugDose> adultRegimen({required double weight, required int days}) {
  // name, label, mg/kg, max mg/day, strengths stocked.
  const spec = [
    ('Isoniazid (H)', 'INH tab', 5.0, 300.0, [100]),
    ('Rifampicin (R)', 'RIF cap', 10.0, 600.0, [300, 450]),
    ('Pyrazinamide (Z)', 'PZA tab', 25.0, 2000.0, [500]),
    ('Ethambutol (E)', 'EMB tab', 20.0, 1200.0, [400, 500]),
  ];

  return spec.map((s) {
    final (name, label, perKg, maxMg, strengths) = s;
    final target = math.min(weight * perKg, maxMg);
    final pick = pickTablets(
      target: target,
      strengths: strengths,
      maxTotal: maxMg,
      maxTablets: 4,
    );
    return AdultDrugDose(
      name: name,
      label: label,
      targetMg: target,
      strengths: strengths,
      // A non-null pick is guaranteed: one tablet of the lowest strength is
      // always within every maxTotal above.
      pick: pick!,
      days: days,
    );
  }).toList();
}

/// Paediatric regimen (<15 years): higher mg/kg than adults, same caps,
/// plus the isoniazid syrup volume.
ChildRegimen childRegimen({required double weight}) {
  final inh = math.min(weight * 10, 300.0);
  final syrupMl = inh / 10; // syrup is 10 mg/mL

  return ChildRegimen(
    doses: [
      ChildDrugDose(name: 'Isoniazid (10 mg/kg)', targetMg: inh),
      ChildDrugDose(
        name: 'Rifampicin (15 mg/kg)',
        targetMg: math.min(weight * 15, 600.0),
      ),
      ChildDrugDose(
        name: 'Pyrazinamide (35 mg/kg)',
        targetMg: math.min(weight * 35, 2000.0),
      ),
      ChildDrugDose(
        name: 'Ethambutol (20 mg/kg)',
        targetMg: math.min(weight * 20, 1200.0),
      ),
    ],
    syrupMlPerDay: syrupMl,
    bottlesPerDay: syrupMl / 60,
  );
}
