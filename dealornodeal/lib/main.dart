import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => DealGameCubit()..startGame(),
      child: const DealGameApp(),
    ),
  );
}

class DealGameApp extends StatelessWidget {
  const DealGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const DealGamePage(),
    );
  }
}

class DealGamePage extends StatefulWidget {
  const DealGamePage({super.key});

  @override
  State<DealGamePage> createState() => _DealGamePageState();
}

class _DealGamePageState extends State<DealGamePage> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(RawKeyEvent event, BuildContext context) {
    if (event is! RawKeyDownEvent) return;
    final cubit = context.read<DealGameCubit>();
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.keyD) {
      cubit.acceptDeal();
      return;
    }

    if (key == LogicalKeyboardKey.keyN) {
      cubit.rejectDeal();
      return;
    }

    final numberMap = <LogicalKeyboardKey, int>{
      LogicalKeyboardKey.digit1: 1,
      LogicalKeyboardKey.digit2: 2,
      LogicalKeyboardKey.digit3: 3,
      LogicalKeyboardKey.digit4: 4,
      LogicalKeyboardKey.digit5: 5,
      LogicalKeyboardKey.digit6: 6,
      LogicalKeyboardKey.digit7: 7,
      LogicalKeyboardKey.digit8: 8,
      LogicalKeyboardKey.digit9: 9,
      LogicalKeyboardKey.digit0: 10,
      LogicalKeyboardKey.numpad1: 1,
      LogicalKeyboardKey.numpad2: 2,
      LogicalKeyboardKey.numpad3: 3,
      LogicalKeyboardKey.numpad4: 4,
      LogicalKeyboardKey.numpad5: 5,
      LogicalKeyboardKey.numpad6: 6,
      LogicalKeyboardKey.numpad7: 7,
      LogicalKeyboardKey.numpad8: 8,
      LogicalKeyboardKey.numpad9: 9,
      LogicalKeyboardKey.numpad0: 10,
    };

    final selected = numberMap[key];
    if (selected != null) {
      cubit.selectCase(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (event) => _handleKey(event, context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Deal or No Deal'),
          centerTitle: true,
        ),
        body: BlocBuilder<DealGameCubit, DealGameState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTopStatus(state),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildValuesPanel(state)),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: _buildCasesPanel(context, state)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildControls(context, state),
                  const SizedBox(height: 16),
                  _buildBottomMessage(state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopStatus(DealGameState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              state.playerCase == null
                  ? 'Pick your hold suitcase'
                  : 'Your hold suitcase: ${state.playerCase}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.offer != null && state.phase == GamePhase.offer
                  ? 'Dealer Offer: \$${formatMoney(state.offer!.round())}'
                  : 'Dealer Offer: --',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValuesPanel(DealGameState state) {
    final ordered = [...DealGameCubit.moneyValues]..sort();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Values',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: ordered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final value = ordered[index];
                  final revealed = state.revealedValues.contains(value);
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: revealed ? Colors.grey.shade400 : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(
                      '\$${formatMoney(value)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        decoration: revealed ? TextDecoration.lineThrough : null,
                        color: revealed ? Colors.black54 : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCasesPanel(BuildContext context, DealGameState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Suitcases',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: state.cases.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, index) {
                  final suitcase = state.cases[index];
                  final isPlayerCase = suitcase.id == state.playerCase;
                  final isOpened = suitcase.isOpened;
                  final canTap = context.read<DealGameCubit>().canSelectCase(suitcase.id);

                  Color color;
                  if (isPlayerCase) {
                    color = Colors.blue.shade300;
                  } else if (isOpened) {
                    color = Colors.grey.shade400;
                  } else if (canTap) {
                    color = Colors.orange.shade300;
                  } else {
                    color = Colors.brown.shade200;
                  }

                  return ElevatedButton(
                    onPressed: canTap ? () => context.read<DealGameCubit>().selectCase(suitcase.id) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: color,
                      disabledForegroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                    child: isOpened
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${suitcase.id}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '\$${formatMoney(suitcase.value)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.work, size: 28),
                              const SizedBox(height: 6),
                              Text(
                                '${
                                  suitcase.id == 10 ? 0 : suitcase.id
                                }',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              if (isPlayerCase)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'YOURS',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, DealGameState state) {
    final canDeal = state.phase == GamePhase.offer && !state.gameOver;
    final canNoDeal = state.phase == GamePhase.offer && !state.gameOver;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 180,
          height: 56,
          child: ElevatedButton(
            onPressed: canDeal ? () => context.read<DealGameCubit>().acceptDeal() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'DEAL (D)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 180,
          height: 56,
          child: ElevatedButton(
            onPressed: canNoDeal ? () => context.read<DealGameCubit>().rejectDeal() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'NO DEAL (N)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomMessage(DealGameState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          state.message,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

enum GamePhase {
  choosingPlayerCase,
  choosingOpenCase,
  offer,
  finished,
}

class SuitcaseModel {
  final int id;
  final int value;
  final bool isOpened;

  const SuitcaseModel({
    required this.id,
    required this.value,
    required this.isOpened,
  });

  SuitcaseModel copyWith({
    int? id,
    int? value,
    bool? isOpened,
  }) {
    return SuitcaseModel(
      id: id ?? this.id,
      value: value ?? this.value,
      isOpened: isOpened ?? this.isOpened,
    );
  }
}

class DealGameState {
  final List<SuitcaseModel> cases;
  final int? playerCase;
  final Set<int> revealedValues;
  final double? offer;
  final GamePhase phase;
  final String message;
  final bool gameOver;
  final int? winnings;

  const DealGameState({
    required this.cases,
    required this.playerCase,
    required this.revealedValues,
    required this.offer,
    required this.phase,
    required this.message,
    required this.gameOver,
    required this.winnings,
  });

  factory DealGameState.initial() {
    return const DealGameState(
      cases: [],
      playerCase: null,
      revealedValues: {},
      offer: null,
      phase: GamePhase.choosingPlayerCase,
      message: 'Pick your hold suitcase.',
      gameOver: false,
      winnings: null,
    );
  }

  DealGameState copyWith({
    List<SuitcaseModel>? cases,
    int? playerCase,
    Set<int>? revealedValues,
    double? offer,
    GamePhase? phase,
    String? message,
    bool? gameOver,
    int? winnings,
    bool clearOffer = false,
    bool clearWinnings = false,
  }) {
    return DealGameState(
      cases: cases ?? this.cases,
      playerCase: playerCase ?? this.playerCase,
      revealedValues: revealedValues ?? this.revealedValues,
      offer: clearOffer ? null : (offer ?? this.offer),
      phase: phase ?? this.phase,
      message: message ?? this.message,
      gameOver: gameOver ?? this.gameOver,
      winnings: clearWinnings ? null : (winnings ?? this.winnings),
    );
  }
}

class DealGameCubit extends Cubit<DealGameState> {
  DealGameCubit() : super(DealGameState.initial());

  static const List<int> moneyValues = [
    1,
    5,
    10,
    100,
    1000,
    5000,
    10000,
    100000,
    500000,
    1000000,
  ];

  void startGame() {
    final shuffled = [...moneyValues]..shuffle(Random());
    final generatedCases = List.generate(
      10,
      (index) => SuitcaseModel(
        id: index + 1,
        value: shuffled[index],
        isOpened: false,
      ),
    );

    emit(
      DealGameState.initial().copyWith(
        cases: generatedCases,
        message: 'Pick your hold suitcase.',
        phase: GamePhase.choosingPlayerCase,
        clearOffer: true,
        clearWinnings: true,
      ),
    );
  }

  bool canSelectCase(int id) {
    final suitcase = state.cases.firstWhere((c) => c.id == id);
    if (state.gameOver) return false;
    if (suitcase.isOpened) return false;

    if (state.phase == GamePhase.choosingPlayerCase) {
      return true;
    }

    if (state.phase == GamePhase.choosingOpenCase) {
      return state.playerCase != id;
    }

    return false;
  }

  void selectCase(int id) {
    if (!canSelectCase(id)) return;

    if (state.phase == GamePhase.choosingPlayerCase) {
      emit(
        state.copyWith(
          playerCase: id,
          phase: GamePhase.choosingOpenCase,
          message: 'You picked suitcase $id as your hold suitcase. Now open one suitcase.',
          clearOffer: true,
        ),
      );
      return;
    }

    if (state.phase == GamePhase.choosingOpenCase) {
      final updatedCases = state.cases.map((c) {
        if (c.id == id) {
          return c.copyWith(isOpened: true);
        }
        return c;
      }).toList();

      final openedCase = updatedCases.firstWhere((c) => c.id == id);
      final revealed = {...state.revealedValues, openedCase.value};

      if (_remainingClosedNonPlayer(updatedCases, state.playerCase!).isEmpty) {
        final playerSuitcase = updatedCases.firstWhere((c) => c.id == state.playerCase);
        emit(
          state.copyWith(
            cases: updatedCases,
            revealedValues: revealed,
            phase: GamePhase.finished,
            gameOver: true,
            winnings: playerSuitcase.value,
            message:
                'You opened suitcase $id and revealed \$${formatMoney(openedCase.value)}. No more cases remain. Your suitcase had \$${formatMoney(playerSuitcase.value)}.',
            clearOffer: true,
          ),
        );
        return;
      }

      final offer = _calculateOffer(updatedCases, state.playerCase!);

      emit(
        state.copyWith(
          cases: updatedCases,
          revealedValues: revealed,
          offer: offer,
          phase: GamePhase.offer,
          message:
              'You opened suitcase $id and revealed \$${formatMoney(openedCase.value)}. Dealer offers \$${formatMoney(offer.round())}.',
        ),
      );
    }
  }

  void acceptDeal() {
    if (state.phase != GamePhase.offer || state.offer == null || state.gameOver) return;

    emit(
      state.copyWith(
        phase: GamePhase.finished,
        gameOver: true,
        winnings: state.offer!.round(),
        message: 'DEAL! You won \$${formatMoney(state.offer!.round())}.',
      ),
    );
  }

  void rejectDeal() {
    if (state.phase != GamePhase.offer || state.gameOver) return;

    emit(
      state.copyWith(
        phase: GamePhase.choosingOpenCase,
        message: 'NO DEAL! Choose one remaining suitcase to open.',
        clearOffer: true,
      ),
    );
  }

  double _calculateOffer(List<SuitcaseModel> cases, int playerCaseId) {
    final remaining = cases.where((c) => !c.isOpened && c.id != playerCaseId).map((c) => c.value).toList();
    final playerValue = cases.firstWhere((c) => c.id == playerCaseId).value;
    final hidden = [...remaining, playerValue];
    final expectedValue = hidden.reduce((a, b) => a + b) / hidden.length;
    return expectedValue * 0.9;
  }

  List<SuitcaseModel> _remainingClosedNonPlayer(List<SuitcaseModel> cases, int playerCaseId) {
    return cases.where((c) => !c.isOpened && c.id != playerCaseId).toList();
  }
}

String formatMoney(int value) {
  final str = value.toString();
  final buffer = StringBuffer();
  int count = 0;

  for (int i = str.length - 1; i >= 0; i--) {
    buffer.write(str[i]);
    count++;
    if (count % 3 == 0 && i != 0) {
      buffer.write(',');
    }
  }

  return buffer.toString().split('').reversed.join();
}