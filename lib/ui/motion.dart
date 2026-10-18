import 'package:flutter/material.dart';

/// Shared motion vocabulary, so every screen animates with one rhythm.
abstract final class Motion {
  /// Taps and small state flips.
  static const fast = Duration(milliseconds: 180);

  /// The default for entrances and tab changes.
  static const normal = Duration(milliseconds: 320);

  /// Longer, for the splash and result reveals.
  static const slow = Duration(milliseconds: 520);

  /// Standard easing — decelerating, no overshoot.
  static const curve = Curves.easeOutCubic;

  /// Slight overshoot, for things that should feel alive (the splash mark).
  static const spring = Curves.easeOutBack;
}

/// Fades and lifts [child] in once, after an optional [delay].
///
/// Used to stagger lists: pass an increasing [delay] per item so results
/// cascade rather than appearing all at once.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.normal,
    this.offset = 16,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// How far up the child travels, in logical pixels.
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: Motion.curve,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        // The delay can outlive the widget when a tab is switched quickly.
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        return Opacity(
          opacity: _curved.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - _curved.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Counts from zero to [value] so a number lands rather than blinks.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    this.fractionDigits = 2,
    this.duration = Motion.slow,
  });

  final double value;
  final TextStyle style;
  final int fractionDigits;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // Keyed by value so a new assessment re-runs the count.
      key: ValueKey(value),
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Motion.curve,
      builder: (context, v, _) =>
          Text(v.toStringAsFixed(fractionDigits), style: style),
    );
  }
}

/// Scales [child] down slightly while pressed.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: Motion.fast,
        curve: Motion.curve,
        child: widget.child,
      ),
    );
  }
}
