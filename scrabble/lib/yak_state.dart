// Wraps the peer TCP socket and sends one line at a time with say().

import "dart:io";
import "package:flutter_bloc/flutter_bloc.dart";

class YakState {
  final Socket? socket;
  final bool listened;

  YakState(this.socket, this.listened);
}

class YakCubit extends Cubit<YakState> {
  YakCubit(String ip) : super(YakState(null, false)) {
    connectClient(ip);
  }

  Future<void> connectClient(String ip) async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      final serv = await Socket.connect(ip, 9203);
      updateSocket(serv);
    } catch (e) {
      print("Client: Failed to connect to $ip:9203 - $e");
    }
  }

  YakCubit.server(ServerSocket? ss) : super(YakState(null, false)) {
    if (ss != null) {
      connectServer(ss);
    }
  }

  Future<void> connectServer(ServerSocket ss) async {
    ss.listen((client) {
      updateSocket(client);
    });
  }

  void updateSocket(Socket s) {
    emit(YakState(s, false));
  }

  void updateListen() {
    emit(YakState(state.socket, true));
  }

  void say(String msg) {
    if (state.socket != null) {
      state.socket!.write("$msg\n");
    }
  }
}