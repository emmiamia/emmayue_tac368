// Reads newline-delimited messages from the socket and routes CHAT vs game lines.

import "dart:async";
import "dart:convert";
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
    final next = List<String>.from(state.chat);
    next.add(s);
    emit(SaidState(next));
  }

  void listen(BuildContext bc) {
    final yc = BlocProvider.of<YakCubit>(bc);
    final ys = yc.state;
    final gc = BlocProvider.of<GameCubit>(bc);

    ys.socket!
        .transform(utf8.decoder as StreamTransformer<Uint8List, dynamic>)
        .transform(const LineSplitter())
        .listen(
      (message) {
        final text = message.trim();
        if (text.isEmpty) return;

        if (text.startsWith("CHAT ")) {
          addChat("Opponent: ${text.substring(5)}");
        } else {
          gc.handle(text, yc);
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