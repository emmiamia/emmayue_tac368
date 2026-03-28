import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "said_state.dart";
import "game_state.dart";
import "yak_state.dart";

class Player extends StatelessWidget {
  final bool iStart;
  Player(this.iStart, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GameCubit>(
      create: (context) => GameCubit(iStart),
      child: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) => BlocProvider<SaidCubit>(
          create: (context) => SaidCubit(),
          child: BlocBuilder<SaidCubit, SaidState>(
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: Text("Tic Tac Toe")),
              body: Player2(),
            ),
          ),
        ),
      ),
    );
  }
}

class Player2 extends StatelessWidget {
  const Player2({super.key});

  @override
  Widget build(BuildContext context) {
    YakCubit yc = BlocProvider.of<YakCubit>(context);
    YakState ys = yc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);

    if (ys.socket != null && !ys.listened) {
      sc.listen(context);
      yc.updateListen();
    }
    return Player3();
  }
}

class Player3 extends StatelessWidget {
  Player3({super.key});

  final TextEditingController tec = TextEditingController();

  @override
  Widget build(BuildContext context) {
    GameCubit gc = BlocProvider.of<GameCubit>(context);
    GameState gs = gc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);
    SaidState ss = sc.state;
    YakCubit yc = BlocProvider.of<YakCubit>(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text("You are ${gs.myMark}", style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(gs.status, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 12),
          Row(children: [Sq(0), Sq(1), Sq(2)]),
          Row(children: [Sq(3), Sq(4), Sq(5)]),
          Row(children: [Sq(6), Sq(7), Sq(8)]),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: gs.gameOver
                    ? null
                    : () {
                        gc.resignLocal();
                        yc.say("RESIGN");
                      },
                child: const Text("Resign"),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: gs.gameOver || !gs.myTurn
                    ? null
                    : () {
                        gc.passLocal();
                        yc.say("PASS");
                      },
                child: const Text("Pass"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: tec,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Chat",
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  String msg = tec.text.trim();
                  if (msg.isEmpty) return;
                  sc.addChat("Me: $msg");
                  yc.say("CHAT $msg");
                  tec.clear();
                },
                child: const Text("Send"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: ss.chat.length,
              itemBuilder: (context, index) {
                return Text(ss.chat[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Sq extends StatelessWidget {
  final int sn;
  const Sq(this.sn, {super.key});

  @override
  Widget build(BuildContext context) {
    GameCubit gc = BlocProvider.of<GameCubit>(context);
    GameState gs = gc.state;
    YakCubit yc = BlocProvider.of<YakCubit>(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 90,
          child: ElevatedButton(
            onPressed: (!gc.canPlay(sn))
                ? null
                : () {
                    bool ok = gc.localPlay(sn);
                    if (ok) {
                      yc.say("MOVE $sn");
                    }
                  },
            child: Text(
              gs.board[sn],
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      ),
    );
  }
}