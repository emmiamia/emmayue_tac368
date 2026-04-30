import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import 'shake_row.dart';
import 'tile_widget.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({
    super.key,
    required this.gameplay,
    required this.shakeVersion,
    required this.shakeRow,
  });

  final GameplayModel gameplay;
  final int shakeVersion;
  final int shakeRow;

  @override
  Widget build(BuildContext context) {
    final cols = gameplay.secretWord.length;
    return AspectRatio(
      aspectRatio: cols / 6,
      child: Column(
        children: List.generate(6, (row) {
          final token = row == shakeRow ? shakeVersion : 0;
          return Expanded(
            child: ShakeRow(
              shakeToken: token,
              child: Row(
                children: List.generate(cols, (col) {
                  return Expanded(
                    child: TileWidget(
                      key: ValueKey('tile-$row-$col'),
                      tile: gameplay.board[row][col],
                      col: col,
                    ),
                  );
                }),
              ),
            ),
          );
        }),
      ),
    );
  }
}
