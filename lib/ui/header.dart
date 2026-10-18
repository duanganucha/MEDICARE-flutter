import 'package:flutter/material.dart';

import 'brand.dart';
import 'motion.dart';
import 'theme.dart';

/// The dark plum band at the top: peach cross, wordmark, tagline.
///
/// Draws behind the status bar; the caller supplies the top inset so the
/// content clears the notch.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    final c = context.dose;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 34),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.headerTop, c.headerBottom],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Faint arcs echoing the mockup's top-right flourish.
          Positioned(
            right: -70,
            top: -90,
            child: IgnorePointer(
              child: CustomPaint(
                size: const Size(220, 220),
                painter: _ArcsPainter(color: c.onHeader.withValues(alpha: .07)),
              ),
            ),
          ),
          Row(
            children: [
              _CrossMark(color: c.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'MEDICARE',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.5,
                          height: 1.1,
                          color: c.onHeader,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'เครื่องมือช่วยคำนวณขนาดยาสำหรับเภสัชกร',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: c.onHeaderMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _BrandSwitch(),
            ],
          ),
        ],
      ),
    );
  }
}

/// The peach medical cross beside the wordmark.
class _CrossMark extends StatelessWidget {
  const _CrossMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: CustomPaint(painter: _CrossPainter(color)),
    );
  }
}

class _CrossPainter extends CustomPainter {
  const _CrossPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    // A plus built from two rounded bars, as in the mockup.
    const t = 11.0; // bar thickness
    final r = Radius.circular(t * 0.32);
    final c = size.center(Offset.zero);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: t, height: size.height),
        r,
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: size.width, height: t),
        r,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.color != color;
}

/// Decorative concentric arcs for the header's top-right corner.
class _ArcsPainter extends CustomPainter {
  const _ArcsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..color = color;
    final center = size.center(Offset.zero);
    for (final r in [70.0, 112.0]) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_ArcsPainter old) => old.color != color;
}

/// Top-right control that flips between the plum and teal palettes.
class _BrandSwitch extends StatelessWidget {
  const _BrandSwitch();

  @override
  Widget build(BuildContext context) {
    final c = context.dose;
    final scope = BrandScope.of(context);
    final next = scope.brand.next;

    return Tooltip(
      message: 'เปลี่ยนเป็นธีม${next.label}',
      child: Semantics(
        button: true,
        label: 'เปลี่ยนธีมสี ปัจจุบัน ${scope.brand.label}',
        child: InkWell(
          onTap: () => scope.onChanged(next),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: Motion.normal,
            curve: Motion.curve,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.onHeader.withValues(alpha: .12),
              shape: BoxShape.circle,
              border: Border.all(color: c.onHeader.withValues(alpha: .22)),
            ),
            // A dot in the colour the tap will switch to.
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: next == Brand.teal
                    ? const Color(0xFF4CC6D2)
                    : const Color(0xFFF08A6B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
