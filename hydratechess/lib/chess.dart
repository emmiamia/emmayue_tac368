import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'chess_state.dart';
import 'move_state.dart';
import 'coords.dart';

class Chess extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "chess",
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ChessCubit>(create: (_) => ChessCubit()),
          BlocProvider<MoveCubit>(create: (_) => MoveCubit()),
        ],
        child: Chess1(),
      ),
    );
  }
}

class Chess1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ChessCubit, ChessState>(
          builder: (_, cs) {
            final who = (cs.turnCount % 2 == 0) ? "White" : "Black";
            return Text("chess | turnCount=${cs.turnCount} | turn=$who");
          },
        ),
      ),
      body: Center(child: drawBoard(context)),
    );
  }

  Widget drawBoard(BuildContext context) {
    final cs = context.watch<ChessCubit>().state;

    final List<Widget> rows = [];

    for (int row = 7; row >= 0; row--) {
      final List<Widget> squares = [];
      for (int col = 0; col < 8; col++) {
        squares.add(Square(Coords(col, row), cs.board[col][row]));
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: squares));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

class Square extends StatelessWidget {
  final Coords here;
  final String letter;
  final bool light;

  Square(this.here, this.letter) : light = ((here.r + here.c) % 2 == 1);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoveCubit, MoveState>(
      builder: (context, moveState) {
        final mc = context.read<MoveCubit>();
        final cc = context.read<ChessCubit>();

        final bool isSelected = moveState.fromHere == here;

        return GestureDetector(
          onTap: () {
            mc.mouseDown(here, cc);
          },
          child: Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.yellow
                  : (light ? Colors.white : Colors.grey),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.black,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              letter,
              style: const TextStyle(fontSize: 30),
            ),
          ),
        );
      },
    );
  }
}
