import "dart:typed_data";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "yak_state.dart";
import "game_state.dart";

class SaidState {
  final List<String> chat;

  SaidState(this.chat);
}

class SaidCubit extends Cubit<SaidState> {
  SaidCubit() : super(SaidState(["Connected."]));

  void addChat(String s) {
    List<String> next = List<String>.from(state.chat);
    next.add(s);
    emit(SaidState(next));
  }

  void listen(BuildContext bc) {
    YakCubit yc = BlocProvider.of<YakCubit>(bc);
    YakState ys = yc.state;
    GameCubit gc = BlocProvider.of<GameCubit>(bc);

    ys.socket!.listen(
      (Uint8List data) async {
        final message = String.fromCharCodes(data).trim();

        if (message.startsWith("CHAT ")) {
          addChat("Opponent: ${message.substring(5)}");
        } else {
          gc.handle(message);
        }
      },
      onError: (error) {
        addChat("Connection error");
        ys.socket!.close();
      },
      onDone: () {
        addChat("Connection closed");
      },
    );
  }
}