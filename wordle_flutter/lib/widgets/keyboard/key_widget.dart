import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/letter_state.dart';

class KeyWidget extends StatelessWidget {
  const KeyWidget({
    super.key,
    required this.label,
    required this.flex,
    required this.onTap,
    this.state = LetterState.empty,
    this.wide = false,
  });

  /// Taller keys for easier tapping (Wordle-style density).
  static const double keyHeight = 54;

  final String label;
  final int flex;
  final VoidCallback onTap;
  final LetterState state;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colors = context.wordle;
    final bg = _bg(context, colors);
    final fg = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: keyHeight,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: fg,
                    fontSize: wide ? 13 : 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _bg(BuildContext context, WordleColors colors) {
    switch (state) {
      case LetterState.correct:
        return colors.correct;
      case LetterState.present:
        return colors.present;
      case LetterState.absent:
        return colors.absent;
      case LetterState.empty:
      case LetterState.filled:
        return Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF818384)
            : const Color(0xFFD3D6DA);
    }
  }
}
