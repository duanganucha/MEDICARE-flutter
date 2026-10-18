import 'package:flutter/material.dart';

import '../logic/noac.dart';
import 'motion.dart';
import 'theme.dart';

/// White panel that groups a form or a result set.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = 18});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: context.dose.line.withValues(alpha: .7)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// The amber "prototype only" disclaimer, and the CrCl <15 notice.
class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key, this.title, required this.body});

  final String? title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final dose = context.dose;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: dose.cautionBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dose.caution.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: dose.caution, size: 22),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      color: dose.caution,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                Text(
                  body,
                  style: const TextStyle(fontSize: 13.5, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading inside a card.
class CardTitle extends StatelessWidget {
  const CardTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Field label above an input.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// The big CrCl readout.
class StatBox extends StatelessWidget {
  const StatBox({
    super.key,
    required this.label,
    required this.crCl,
    required this.unit,
  });

  final String label;

  /// Counted up to on display, rather than appearing at once.
  final double crCl;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final dose = context.dose;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: dose.primaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: dose.muted, fontSize: 14)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedNumber(
                value: crCl,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: primary,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: dose.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single drug recommendation, colour-coded by [DoseFlag].
class DrugCard extends StatelessWidget {
  const DrugCard({
    super.key,
    required this.name,
    required this.dose,
    this.reasonLabel = 'เหตุผล: ',
    this.reason,
    this.flag = DoseFlag.standard,
    this.details,
  });

  final String name;

  /// The headline dose. Omitted from the layout when empty.
  final String dose;
  final String reasonLabel;
  final String? reason;
  final DoseFlag flag;

  /// Rich body used by the TB tab in place of [reason].
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    final c = context.dose;
    final (accent, fill, pill) = switch (flag) {
      DoseFlag.reduced => (c.ok, c.okBg, null),
      DoseFlag.caution => (c.caution, c.cautionBg, 'ระวัง'),
      DoseFlag.avoid => (c.bad, c.badBg, 'ไม่แนะนำ'),
      DoseFlag.standard => (c.line, c.soft, null),
    };
    final isAvoid = flag == DoseFlag.avoid;

    // A left accent bar, drawn as a sibling rather than as a non-uniform
    // Border: Flutter cannot paint a per-side border colour together with a
    // borderRadius, so the CSS `border-left` becomes a Row child.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 11),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isAvoid ? '⚠ $name' : name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isAvoid ? c.bad : null,
                            ),
                          ),
                        ),
                        if (pill != null) _Pill(text: pill, color: accent),
                      ],
                    ),
                    if (dose.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3, bottom: 4),
                        child: Text(
                          dose,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: isAvoid ? c.bad : null,
                          ),
                        ),
                      ),
                    ?details,
                    if (reason != null)
                      Text(
                        '$reasonLabel${reason!}',
                        style: TextStyle(
                          color: c.muted,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.dose.pillInk,
        ),
      ),
    );
  }
}

/// Inline emphasis for numbers inside a muted sentence.
TextSpan highlight(String text, Color color) {
  return TextSpan(
    text: text,
    style: TextStyle(color: color, fontWeight: FontWeight.w700),
  );
}

/// A unit shown at the trailing edge of a field, e.g. "kg".
///
/// Uses `suffix` rather than `suffixText` so the unit stays visible while
/// the field is empty and unfocused, as the design calls for.
class UnitLabel extends StatelessWidget {
  const UnitLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    // suffixIcon fills a box, so the label is sized to its text and centred
    // vertically against the input's content.
    return Padding(
      padding: const EdgeInsets.only(right: 15, left: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: TextStyle(color: context.dose.muted, fontSize: 14)),
        ],
      ),
    );
  }
}
