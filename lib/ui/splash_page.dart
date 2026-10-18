import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'theme.dart';

/// Branded splash.
///
/// The sequence, on one controller so the beats stay in step:
/// capsules drift in behind → the tile springs up and the cross draws itself
/// → a ring pulses out → the wordmark reveals letter by letter → the tagline
/// and a progress sweep arrive → the whole thing lifts and fades.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.onDone});

  /// Called once the entrance has played out.
  final VoidCallback onDone;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  Animation<double> _at(
    double begin,
    double end, {
    Curve curve = Motion.curve,
  }) {
    return CurvedAnimation(
      parent: _c,
      curve: Interval(begin, end, curve: curve),
    );
  }

  late final _backdrop = _at(0.00, 0.40);
  late final _tile = _at(0.04, 0.42, curve: Curves.easeOutBack);
  late final _cross = _at(0.16, 0.52);
  late final _ring = _at(0.22, 0.68);
  late final _word = _at(0.38, 0.74);
  late final _tagline = _at(0.56, 0.80);
  late final _bar = _at(0.60, 0.90);
  late final _exit = _at(0.90, 1.00, curve: Curves.easeIn);

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dose = context.dose;

    return Scaffold(
      backgroundColor: dose.headerBottom,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Opacity(
            // Lifts slightly as it fades, so the hand-off has direction.
            opacity: 1 - _exit.value,
            child: Transform.translate(
              offset: Offset(0, -26 * _exit.value),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Backdrop(progress: _backdrop.value, colors: dose),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Mark(
                          tile: _tile.value,
                          cross: _cross.value,
                          ring: _ring.value,
                          colors: dose,
                        ),
                        const SizedBox(height: 32),
                        _Wordmark(progress: _word.value, color: dose.onHeader),
                        const SizedBox(height: 10),
                        Opacity(
                          opacity: _tagline.value,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - _tagline.value)),
                            child: Text(
                              'เครื่องมือช่วยคำนวณขนาดยาสำหรับเภสัชกร',
                              style: TextStyle(
                                color: dose.onHeaderMuted,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _ProgressBar(
                          progress: _bar.value,
                          track: dose.onHeader.withValues(alpha: .16),
                          fill: dose.accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Soft radial glow plus two drifting capsules behind the mark.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.progress, required this.colors});

  final double progress;
  final DoseColors colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _BackdropPainter(progress: progress, colors: colors),
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({required this.progress, required this.colors});

  final double progress;
  final DoseColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = size.center(Offset.zero);

    // Glow behind the mark, widening as it fades up.
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              colors.accent.withValues(alpha: .20 * progress),
              colors.accent.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.shortestSide * 0.62),
          );
    canvas.drawRect(Offset.zero & size, glow);

    // Two capsules easing in from opposite corners.
    _capsule(
      canvas,
      center: center + Offset(-size.width * .30, -size.height * .20),
      drift: Offset(-60 * (1 - progress), -70 * (1 - progress)),
      angle: -math.pi * .25,
      length: size.shortestSide * .34,
      width: size.shortestSide * .125,
      color: colors.ok.withValues(alpha: .20 * progress),
    );
    _capsule(
      canvas,
      center: center + Offset(size.width * .31, size.height * .20),
      drift: Offset(60 * (1 - progress), 70 * (1 - progress)),
      angle: math.pi * .25,
      length: size.shortestSide * .40,
      width: size.shortestSide * .145,
      color: colors.accent.withValues(alpha: .22 * progress),
    );
  }

  void _capsule(
    Canvas canvas, {
    required Offset center,
    required Offset drift,
    required double angle,
    required double length,
    required double width,
    required Color color,
  }) {
    canvas.save();
    canvas.translate(center.dx + drift.dx, center.dy + drift.dy);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: length, height: width),
        Radius.circular(width / 2),
      ),
      Paint()..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.progress != progress;
}

/// The rounded tile, the cross drawn inside it, and the pulse ring.
class _Mark extends StatelessWidget {
  const _Mark({
    required this.tile,
    required this.cross,
    required this.ring,
    required this.colors,
  });

  final double tile;
  final double cross;
  final double ring;
  final DoseColors colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(180),
            painter: _RingPainter(progress: ring, color: colors.accent),
          ),
          Transform.scale(
            scale: tile,
            // A slow settle out of the spring, so it lands rather than snaps.
            child: Transform.rotate(
              angle: -0.06 * (1 - tile),
              child: Container(
                width: 98,
                height: 98,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: .38 * tile),
                      blurRadius: 34,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _CrossPainter(
                    progress: cross,
                    color: colors.headerBottom,
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

/// Two rings pulsing outward, the second trailing the first.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = size.center(Offset.zero);

    for (final delay in [0.0, 0.26]) {
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      canvas.drawCircle(
        center,
        52 + 36 * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = color.withValues(alpha: .34 * (1 - t)),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Draws the medical cross stroke by stroke.
class _CrossPainter extends CustomPainter {
  const _CrossPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final c = size.center(Offset.zero);
    const arm = 24.0;

    // The vertical arm draws first, the horizontal one trails it.
    final v = Curves.easeOutCubic.transform((progress / 0.6).clamp(0.0, 1.0));
    final h = Curves.easeOutCubic.transform(
      ((progress - 0.3) / 0.7).clamp(0.0, 1.0),
    );

    if (v > 0) {
      canvas.drawLine(
        Offset(c.dx, c.dy - arm * v),
        Offset(c.dx, c.dy + arm * v),
        paint,
      );
    }
    if (h > 0) {
      canvas.drawLine(
        Offset(c.dx - arm * h, c.dy),
        Offset(c.dx + arm * h, c.dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CrossPainter old) =>
      old.progress != progress || old.color != color;
}

/// MEDICARE, revealed one letter at a time.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const _text = 'MEDICARE';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, ch) in _text.split('').indexed)
          _Letter(
            char: ch,
            // Each letter gets its own slice of the reveal.
            progress: _slice(i, _text.length),
            color: color,
          ),
      ],
    );
  }

  /// The portion of [progress] belonging to letter [i], eased.
  double _slice(int i, int count) {
    // Letters overlap heavily, so the word reads as one gesture.
    const overlap = 0.55;
    final step = (1 - overlap) / count;
    final begin = i * step;
    final t = ((progress - begin) / (1 - begin)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(t);
  }
}

class _Letter extends StatelessWidget {
  const _Letter({
    required this.char,
    required this.progress,
    required this.color,
  });

  final String char;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, 18 * (1 - progress)),
        child: Text(
          char,
          style: TextStyle(
            fontSize: 33,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// A short determinate sweep under the wordmark.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      // Fades in over its first fifth, then stays.
      opacity: (progress * 5).clamp(0.0, 1.0),
      child: Container(
        width: 132,
        height: 3,
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
