import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/letter_state.dart';
import '../../models/tile.dart';

class TileWidget extends StatefulWidget {
  const TileWidget({
    super.key,
    required this.tile,
    required this.col,
  });

  final Tile tile;
  final int col;

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(covariant TileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final was = _evaluationState(oldWidget.tile.state);
    final now = _evaluationState(widget.tile.state);
    if (was == null && now != null) {
      final delay = Duration(milliseconds: widget.col * 90);
      Future<void>.delayed(delay, () {
        if (mounted) _controller.forward(from: 0);
      });
    }
  }

  LetterState? _evaluationState(LetterState s) {
    switch (s) {
      case LetterState.correct:
      case LetterState.present:
      case LetterState.absent:
        return s;
      case LetterState.empty:
      case LetterState.filled:
        return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.wordle;
    final evaluated = _evaluationState(widget.tile.state) != null;

    Widget face({required bool back}) {
      final bg = back && evaluated ? _evalColor(context) : colors.tileEmptyFill;
      final borderColor =
          evaluated && back ? Colors.transparent : colors.tileBorder;
      return Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: back ? bg : colors.tileEmptyFill,
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.tile.letter,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: back
                    ? Colors.white
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87),
              ),
        ),
      );
    }

    if (!evaluated) {
      return face(back: false);
    }

    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final angle = _curve.value * math.pi;
        final isBack = angle > math.pi / 2;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);
        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: isBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: face(back: true),
                )
              : face(back: false),
        );
      },
    );
  }

  Color _evalColor(BuildContext context) {
    final colors = context.wordle;
    switch (widget.tile.state) {
      case LetterState.correct:
        return colors.correct;
      case LetterState.present:
        return colors.present;
      case LetterState.absent:
        return colors.absent;
      case LetterState.empty:
      case LetterState.filled:
        return colors.tileEmptyFill;
    }
  }
}
