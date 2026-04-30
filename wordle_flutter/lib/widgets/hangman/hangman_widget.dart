import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import '../../models/letter_state.dart';

/// Number of submitted (evaluated) guess rows — drives hangman stages (0–6).
int hangmanStageFromGameplay(GameplayModel g) {
  final len = g.secretWord.length;
  var count = 0;
  for (var r = 0; r < 6; r++) {
    final row = g.board[r];
    if (row.length < len) break;
    var evaluated = true;
    for (var i = 0; i < len; i++) {
      final s = row[i].state;
      if (s != LetterState.correct &&
          s != LetterState.present &&
          s != LetterState.absent) {
        evaluated = false;
        break;
      }
    }
    if (!evaluated) break;
    count++;
  }
  return count.clamp(0, 6);
}

/// Classic stick-figure hangman: gallows + up to 6 body parts as guesses are used.
class HangmanWidget extends StatelessWidget {
  const HangmanWidget({
    super.key,
    required this.stage,
    this.width = 112,
    this.height = 132,
  });

  final int stage;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final figure = scheme.onSurface;
    final gallows = scheme.onSurface.withValues(alpha: 0.55);

    return Semantics(
      label: 'Hangman, $stage of 6 guesses used',
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) {
            return FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.88, end: 1).animate(anim),
                child: child,
              ),
            );
          },
          child: CustomPaint(
            key: ValueKey<int>(stage),
            painter: HangmanPainter(
              stage: stage,
              figureColor: figure,
              gallowsColor: gallows,
            ),
            size: Size(width, height),
          ),
        ),
      ),
    );
  }
}

class HangmanPainter extends CustomPainter {
  HangmanPainter({
    required this.stage,
    required this.figureColor,
    required this.gallowsColor,
  });

  final int stage;
  final Color figureColor;
  final Color gallowsColor;

  static const _stroke = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseY = h - 8;
    final poleX = w * 0.18;
    final topY = h * 0.12;
    final beamEndX = w * 0.62;
    final ropeX = w * 0.52;
    final ropeBottom = topY + h * 0.14;
    final headCy = ropeBottom + w * 0.09;
    final headR = w * 0.075;

    final gallowsPaint = Paint()
      ..color = gallowsColor
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final bodyPaint = Paint()
      ..color = figureColor
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Ground
    canvas.drawLine(
      Offset(poleX - 4, baseY),
      Offset(w * 0.88, baseY),
      gallowsPaint,
    );
    // Pole
    canvas.drawLine(Offset(poleX, baseY), Offset(poleX, topY), gallowsPaint);
    // Top beam
    canvas.drawLine(Offset(poleX, topY), Offset(beamEndX, topY), gallowsPaint);
    // Diagonal brace
    canvas.drawLine(
      Offset(poleX + 8, topY + 18),
      Offset(poleX + 28, topY),
      gallowsPaint,
    );
    // Rope
    canvas.drawLine(Offset(ropeX, topY), Offset(ropeX, ropeBottom), gallowsPaint);

    if (stage < 1) return;

    // Head
    canvas.drawCircle(Offset(ropeX, headCy), headR, bodyPaint);

    if (stage < 2) return;

    // Body
    final neckY = headCy + headR;
    final hipY = h * 0.72;
    canvas.drawLine(Offset(ropeX, neckY), Offset(ropeX, hipY), bodyPaint);

    if (stage < 3) return;

    // Left arm
    canvas.drawLine(
      Offset(ropeX, neckY + (hipY - neckY) * 0.22),
      Offset(ropeX - w * 0.2, neckY + (hipY - neckY) * 0.42),
      bodyPaint,
    );

    if (stage < 4) return;

    // Right arm
    canvas.drawLine(
      Offset(ropeX, neckY + (hipY - neckY) * 0.22),
      Offset(ropeX + w * 0.2, neckY + (hipY - neckY) * 0.42),
      bodyPaint,
    );

    if (stage < 5) return;

    // Left leg
    canvas.drawLine(
      Offset(ropeX, hipY),
      Offset(ropeX - w * 0.16, baseY - 4),
      bodyPaint,
    );

    if (stage < 6) return;

    // Right leg
    canvas.drawLine(
      Offset(ropeX, hipY),
      Offset(ropeX + w * 0.16, baseY - 4),
      bodyPaint,
    );
  }

  @override
  bool shouldRepaint(covariant HangmanPainter oldDelegate) {
    return oldDelegate.stage != stage ||
        oldDelegate.figureColor != figureColor ||
        oldDelegate.gallowsColor != gallowsColor;
  }
}
