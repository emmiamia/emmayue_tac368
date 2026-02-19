// move_state.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'coords.dart';
import 'chess_state.dart';

class MoveState {
  Coords? fromHere;
  MoveState(this.fromHere);
}

class MoveCubit extends Cubit<MoveState> {
  MoveCubit() : super(MoveState(null));

  void mouseDown(Coords here, ChessCubit cc) {

    if (state.fromHere == null) {
      emit(MoveState(here));
      return;
    }

    if (state.fromHere == here) {
      emit(MoveState(null));
      return;
    }

    cc.update(state.fromHere!, here);

    emit(MoveState(null));
  }
}
 