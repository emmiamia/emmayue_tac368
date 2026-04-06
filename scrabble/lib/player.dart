// In-game UI: board, rack, controls, and chat (GameCubit and SaidCubit provided here).

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "app_theme.dart";
import "said_state.dart";
import "game_state.dart";
import "yak_state.dart";

class Player extends StatelessWidget {
  final bool iAmHost;
  const Player(this.iAmHost, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GameCubit>(
      create: (context) => GameCubit(iAmHost),
      child: BlocBuilder<GameCubit, GameState>(
        builder: (context, state) => BlocProvider<SaidCubit>(
          create: (context) => SaidCubit(),
          child: BlocBuilder<SaidCubit, SaidState>(
            builder: (context, state) => const PlayerScaffold(),
          ),
        ),
      ),
    );
  }
}

class PlayerScaffold extends StatelessWidget {
  const PlayerScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final yc = BlocProvider.of<YakCubit>(context);
    final ys = yc.state;
    final sc = BlocProvider.of<SaidCubit>(context);
    final gc = BlocProvider.of<GameCubit>(context);

    if (ys.socket != null && !ys.listened) {
      sc.listen(context);
      yc.updateListen();
      gc.onConnected(yc);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reduced Scrabble"),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: PlayerBody(),
        ),
      ),
    );
  }
}

class PlayerBody extends StatelessWidget {
  const PlayerBody({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = BlocProvider.of<GameCubit>(context);
    final gs = gc.state;
    final yc = BlocProvider.of<YakCubit>(context);
    final sc = BlocProvider.of<SaidCubit>(context);
    final ss = sc.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          gs.iAmHost ? "Role: Host" : "Role: Client",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (!gs.iAmHost) ...[
          const SizedBox(height: 10),
          const ScrabbleRulesPanel(),
        ],
        const SizedBox(height: 4),
        Text(
          gs.status,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          "My score: ${gs.myScore}    Opponent score: ${gs.oppScore}",
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          "My letters: ${gs.myRack.where((e) => e.isNotEmpty).length}    Opponent letters: ${gs.oppRackCount}",
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        const Expanded(
          flex: 6,
          child: BoardWidget(),
        ),
        const SizedBox(height: 10),
        const RackWidget(),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton(
              onPressed: (gs.gameOver || !gs.myTurn || gs.awaitingRefill || gs.placedThisTurn.isEmpty)
                  ? null
                  : () {
                      gc.endTurnLocal(yc);
                    },
              child: const Text("End Turn"),
            ),
            ElevatedButton(
              onPressed: (gs.gameOver || !gs.myTurn || gs.awaitingRefill)
                  ? null
                  : () {
                      gc.passLocal(yc);
                    },
              child: const Text("Pass"),
            ),
            ElevatedButton(
              onPressed: gs.gameOver
                  ? null
                  : () {
                      gc.resignLocal(yc);
                    },
              child: const Text("Resign"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const ChatBox(),
        const SizedBox(height: 8),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.45),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: ss.chat.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(ss.chat[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: GameCubit.boardSize,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: GameCubit.boardSide,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) => BoardSquare(index),
    );
  }
}

class BoardSquare extends StatelessWidget {
  final int index;
  const BoardSquare(this.index, {super.key});

  @override
  Widget build(BuildContext context) {
    final gc = BlocProvider.of<GameCubit>(context);
    final gs = gc.state;
    final scheme = Theme.of(context).colorScheme;

    final value = gs.board[index] == GameCubit.emptyBoard ? "" : gs.board[index];
    final canPlace = gc.canPlaceAt(index);

    return InkWell(
      onTap: canPlace
          ? () {
              gc.placeSelectedAt(index);
            }
          : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(4),
          color: canPlace
              ? scheme.primaryContainer
              : scheme.surfaceContainerLowest,
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class RackWidget extends StatelessWidget {
  const RackWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = BlocProvider.of<GameCubit>(context);
    final gs = gc.state;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Rack",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(
            7,
            (i) {
              final letter = gs.myRack[i];
              final selected = gs.selectedRackIndex == i;
              final enabled = gc.canSelectRack(i);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: enabled
                          ? () {
                              gc.selectRack(i);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selected
                            ? scheme.secondaryContainer
                            : null,
                        foregroundColor:
                            selected ? scheme.onSecondaryContainer : null,
                      ),
                      child: Text(
                        letter.isEmpty ? "-" : letter,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ChatBox extends StatefulWidget {
  const ChatBox({super.key});

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox> {
  final TextEditingController tec = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final sc = BlocProvider.of<SaidCubit>(context);
    final yc = BlocProvider.of<YakCubit>(context);

    return Row(
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
            final msg = tec.text.trim();
            if (msg.isEmpty) return;
            sc.addChat("Me: $msg");
            yc.say("CHAT $msg");
            tec.clear();
          },
          child: const Text("Send"),
        ),
      ],
    );
  }
}

class ScrabbleRulesPanel extends StatelessWidget {
  const ScrabbleRulesPanel({super.key});

  static const _rulesIntro =
      "Classic Scrabble: players take turns building words across a grid so "
      "each new word connects to letters already on the board. This app is a "
      "simplified two-player version over the network.";

  static const _bullets = [
    "Board is 15×15. You always have up to 7 letter tiles on your rack.",
    "On your turn: tap a tile on your rack, then tap an empty square to place it. "
        "You can place several tiles before ending your turn.",
    "Tap End Turn to lock in your placements and draw new tiles from the bag. "
        "Your score goes up by one point for each letter you placed that turn.",
    "Pass skips your turn without placing. Resign ends the game.",
    "There is no dictionary check in this version—play honor-system or agree on "
        "rules with your opponent. Chat is below if you need to coordinate.",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppPalette.berryCrush.withValues(alpha: 0.45), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Icon(
            Icons.menu_book_rounded,
            color: AppPalette.darkRaspberry,
            size: 28,
          ),
          title: Text(
            "Scrabble rules",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppPalette.darkRaspberry,
            ),
          ),
          subtitle: Text(
            "Tap to expand — classic basics & how this app works",
            style: TextStyle(
              fontSize: 12.5,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          children: [
            Text(
              _rulesIntro,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 12),
            ..._bullets.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "• ",
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.berryCrush,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}