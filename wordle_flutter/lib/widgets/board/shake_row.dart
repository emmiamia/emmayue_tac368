import 'package:flutter/material.dart';

/// Horizontal shake triggered when [shakeToken] increments (invalid guess).
class ShakeRow extends StatefulWidget {
  const ShakeRow({
    super.key,
    required this.shakeToken,
    required this.child,
  });

  /// Per-row token; increment to play the animation. Rows that should not shake
  /// can pass a constant (e.g. 0).
  final int shakeToken;
  final Widget child;

  @override
  State<ShakeRow> createState() => _ShakeRowState();
}

class _ShakeRowState extends State<ShakeRow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didUpdateWidget(covariant ShakeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeToken > oldWidget.shakeToken) {
      _controller.forward(from: 0);
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
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = (t < 0.25
                ? -6.0 * (t / 0.25)
                : t < 0.5
                    ? -6.0 + 12.0 * ((t - 0.25) / 0.25)
                    : t < 0.75
                        ? 6.0 - 10.0 * ((t - 0.5) / 0.25)
                        : 10.0 - 10.0 * ((t - 0.75) / 0.25)) *
            (1 - Curves.easeOut.transform(t));
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
