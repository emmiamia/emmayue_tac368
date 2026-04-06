// Binds the listening server socket on port 9203.

import "dart:io";
import "package:flutter_bloc/flutter_bloc.dart";

class ServerState {
  final ServerSocket? server;
  ServerState(this.server);
}

class ServerCubit extends Cubit<ServerState> {
  ServerCubit() : super(ServerState(null)) {
    connect();
  }

  Future<void> connect() async {
    await Future.delayed(const Duration(seconds: 1));
    final s = await ServerSocket.bind("0.0.0.0", 9203);
    emit(ServerState(s));
  }
}