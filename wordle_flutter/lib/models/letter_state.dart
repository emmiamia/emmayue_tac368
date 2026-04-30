enum LetterState {
  empty,
  filled,
  correct,
  present,
  absent,
}

int letterStatePriority(LetterState s) {
  switch (s) {
    case LetterState.correct:
      return 3;
    case LetterState.present:
      return 2;
    case LetterState.absent:
      return 1;
    case LetterState.empty:
    case LetterState.filled:
      return 0;
  }
}

LetterState mergeKeyState(LetterState current, LetterState incoming) {
  if (letterStatePriority(incoming) > letterStatePriority(current)) {
    return incoming;
  }
  return current;
}
