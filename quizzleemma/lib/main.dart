//Emma Yue
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quizzle',
      home: BlocProvider(
        create: (_) => QuizBloc(const QuizRepository()),
        child: const HomePage(),
      ),
    );
  }
}

enum QuizMode { fillIn, multipleChoice }

class QA {
  final String q;
  final String a;
  const QA(this.q, this.a);
}

class QuizFile {
  final String label;
  final String assetPath;
  const QuizFile(this.label, this.assetPath);
}

const List<QuizFile> kQuizFiles = [
  QuizFile('State Capitals', 'assets/StateCapitals.txt'),
  QuizFile('Elements', 'assets/Elements.txt'),
];

class QuizRepository {
  const QuizRepository();

  Future<QuizData> loadFromAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final headerParts = _splitCommaLine(lines.first);
    final askName = headerParts[0].trim();
    final answerName = headerParts[1].trim();

    final items = <QA>[];
    for (int i = 1; i < lines.length; i++) {
      final parts = _splitCommaLine(lines[i]);
      if (parts.length < 2) continue;
      final q = parts[0].trim();
      final a = parts[1].trim();
      if (q.isNotEmpty && a.isNotEmpty) items.add(QA(q, a));
    }

    return QuizData(
      askName: askName,
      answerName: answerName,
      items: items,
    );
  }

  List<String> _splitCommaLine(String line) {
    return line.split(',');
  }
}

class QuizData {
  final String askName;
  final String answerName;
  final List<QA> items;

  const QuizData({
    required this.askName,
    required this.answerName,
    required this.items,
  });
}

//BLoc
abstract class QuizEvent {}

class SelectFile extends QuizEvent {
  final QuizFile file;
  SelectFile(this.file);
}

class SelectMode extends QuizEvent {
  final QuizMode mode;
  SelectMode(this.mode);
}

class StartQuiz extends QuizEvent {}

class AnswerTextChanged extends QuizEvent {
  final String text;
  AnswerTextChanged(this.text);
}

class ChooseOption extends QuizEvent {
  final String option;
  ChooseOption(this.option);
}

class CheckAnswer extends QuizEvent {}

class NextQuestion extends QuizEvent {}

class Restart extends QuizEvent {}

enum QuizStatus { idle, loading, inQuiz, error }

class QuizState {
  final QuizStatus status;

  final QuizFile selectedFile;
  final QuizMode mode;

  final QuizData? data;

  final List<QA> order;
  final int index;

  final int correct;
  final int attempted;

  final String answerText;
  final String? chosenOption;

  final bool checked;
  final bool? wasCorrect;
  final String? feedback;

  final List<String> mcOptions;

  final String? errorMessage;

  const QuizState({
    required this.status,
    required this.selectedFile,
    required this.mode,
    required this.data,
    required this.order,
    required this.index,
    required this.correct,
    required this.attempted,
    required this.answerText,
    required this.chosenOption,
    required this.checked,
    required this.wasCorrect,
    required this.feedback,
    required this.mcOptions,
    required this.errorMessage,
  });

  factory QuizState.initial() => QuizState(
        status: QuizStatus.idle,
        selectedFile: kQuizFiles.first,
        mode: QuizMode.fillIn,
        data: null,
        order: const [],
        index: 0,
        correct: 0,
        attempted: 0,
        answerText: '',
        chosenOption: null,
        checked: false,
        wasCorrect: null,
        feedback: null,
        mcOptions: const [],
        errorMessage: null,
      );

  QuizState copyWith({
    QuizStatus? status,
    QuizFile? selectedFile,
    QuizMode? mode,
    QuizData? data,
    List<QA>? order,
    int? index,
    int? correct,
    int? attempted,
    String? answerText,
    String? chosenOption,
    bool? checked,
    bool? wasCorrect,
    String? feedback,
    List<String>? mcOptions,
    String? errorMessage,
  }) {
    return QuizState(
      status: status ?? this.status,
      selectedFile: selectedFile ?? this.selectedFile,
      mode: mode ?? this.mode,
      data: data ?? this.data,
      order: order ?? this.order,
      index: index ?? this.index,
      correct: correct ?? this.correct,
      attempted: attempted ?? this.attempted,
      answerText: answerText ?? this.answerText,
      chosenOption: chosenOption ?? this.chosenOption,
      checked: checked ?? this.checked,
      wasCorrect: wasCorrect ?? this.wasCorrect,
      feedback: feedback ?? this.feedback,
      mcOptions: mcOptions ?? this.mcOptions,
      errorMessage: errorMessage,
    );
  }
}

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final QuizRepository repo;
  final Random _rng = Random();

  QuizBloc(this.repo) : super(QuizState.initial()) {
    on<SelectFile>((e, emit) {
      emit(state.copyWith(selectedFile: e.file));
    });

    on<SelectMode>((e, emit) {
      emit(state.copyWith(mode: e.mode));
    });

    on<StartQuiz>(_onStartQuiz);

    on<AnswerTextChanged>((e, emit) {
      emit(state.copyWith(answerText: e.text));
    });

    on<ChooseOption>((e, emit) {
      emit(state.copyWith(chosenOption: e.option));
    });

    on<CheckAnswer>(_onCheckAnswer);

    on<NextQuestion>(_onNextQuestion);

    on<Restart>((e, emit) {
      emit(QuizState.initial());
    });
  }

  Future<void> _onStartQuiz(StartQuiz event, Emitter<QuizState> emit) async {
    emit(state.copyWith(status: QuizStatus.loading, errorMessage: null));
    try {
      final data = await repo.loadFromAsset(state.selectedFile.assetPath);
      final shuffled = List<QA>.from(data.items)..shuffle(_rng);

      emit(
        state.copyWith(
          status: QuizStatus.inQuiz,
          data: data,
          order: shuffled,
          index: 0,
          correct: 0,
          attempted: 0,
          answerText: '',
          chosenOption: null,
          checked: false,
          wasCorrect: null,
          feedback: null,
          mcOptions: _buildMcOptions(data, shuffled.first),
        ),
      );
    } catch (e) {
      emit(state.copyWith(
        status: QuizStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onCheckAnswer(CheckAnswer event, Emitter<QuizState> emit) {
    if (state.status != QuizStatus.inQuiz) return;
    if (state.data == null || state.order.isEmpty) return;
    if (state.checked) return;

    final current = state.order[state.index];
    final correctAnswer = current.a;

    String userAnswer;
    if (state.mode == QuizMode.fillIn) {
      userAnswer = state.answerText.trim();
    } else {
      userAnswer = (state.chosenOption ?? '').trim();
    }

    final isCorrect = _normalize(userAnswer) == _normalize(correctAnswer);

    final newAttempted = state.attempted + 1;
    final newCorrect = state.correct + (isCorrect ? 1 : 0);

    final fb = isCorrect
        ? '✅ Correct!'
        : '❌ Wrong. Correct answer: $correctAnswer';

    emit(state.copyWith(
      checked: true,
      wasCorrect: isCorrect,
      feedback: fb,
      attempted: newAttempted,
      correct: newCorrect,
    ));
  }

  void _onNextQuestion(NextQuestion event, Emitter<QuizState> emit) {
    if (state.status != QuizStatus.inQuiz) return;
    if (!state.checked) return; 
    if (state.data == null || state.order.isEmpty) return;

    final nextIndex = state.index + 1;
    if (nextIndex >= state.order.length) {
      final reshuffled = List<QA>.from(state.order)..shuffle(_rng);
      emit(state.copyWith(
        order: reshuffled,
        index: 0,
        answerText: '',
        chosenOption: null,
        checked: false,
        wasCorrect: null,
        feedback: null,
        mcOptions: _buildMcOptions(state.data!, reshuffled.first),
      ));
      return;
    }

    final next = state.order[nextIndex];
    emit(state.copyWith(
      index: nextIndex,
      answerText: '',
      chosenOption: null,
      checked: false,
      wasCorrect: null,
      feedback: null,
      mcOptions: _buildMcOptions(state.data!, next),
    ));
  }

  String _normalize(String s) => s.trim().toLowerCase();

  List<String> _buildMcOptions(QuizData data, QA current) {
    final allAnswers = data.items.map((x) => x.a).toList();
    final correct = current.a;

    final options = <String>{correct};
    while (options.length < 4 && options.length < allAnswers.length) {
      options.add(allAnswers[_rng.nextInt(allAnswers.length)]);
    }

    final list = options.toList()..shuffle(_rng);
    return list;
  }
}

// interface
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuizBloc, QuizState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Quizzle')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose a quiz file:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButton<QuizFile>(
                  value: state.selectedFile,
                  isExpanded: true,
                  items: kQuizFiles
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.label),
                          ))
                      .toList(),
                  onChanged: (f) {
                    if (f != null) {
                      context.read<QuizBloc>().add(SelectFile(f));
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choose format:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                RadioListTile<QuizMode>(
                  title: const Text('Fill in the blank'),
                  value: QuizMode.fillIn,
                  groupValue: state.mode,
                  onChanged: (m) {
                    if (m != null) context.read<QuizBloc>().add(SelectMode(m));
                  },
                ),
                RadioListTile<QuizMode>(
                  title: const Text('Multiple choice'),
                  value: QuizMode.multipleChoice,
                  groupValue: state.mode,
                  onChanged: (m) {
                    if (m != null) context.read<QuizBloc>().add(SelectMode(m));
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: state.status == QuizStatus.loading
                      ? null
                      : () {
                          context.read<QuizBloc>().add(StartQuiz());
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<QuizBloc>(),
                                child: const QuizPage(),
                              ),
                            ),
                          );
                        },
                  child: const Text('Start'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuizBloc, QuizState>(
      builder: (context, state) {
        if (state.status == QuizStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == QuizStatus.error) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quizzle')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    state.errorMessage ?? 'Unknown error',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.status != QuizStatus.inQuiz ||
            state.data == null ||
            state.order.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quizzle')),
            body: const Center(child: Text('No quiz loaded.')),
          );
        }

        final data = state.data!;
        final current = state.order[state.index];
        final qLabel = data.askName;
        final aLabel = data.answerName;

        return Scaffold(
          appBar: AppBar(
            title: Text('Quizzle - ${state.selectedFile.label}'),
            actions: [
              IconButton(
                tooltip: 'Restart',
                onPressed: () {
                  context.read<QuizBloc>().add(Restart());
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Score: ${state.correct} / ${state.attempted}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Question ${state.index + 1} of ${state.order.length}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 18),
                Text(
                  '$qLabel:',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  current.q,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your $aLabel:',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (state.mode == QuizMode.fillIn) ...[
                  TextField(
                    enabled: !state.checked,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type your answer here',
                    ),
                    onChanged: (t) =>
                        context.read<QuizBloc>().add(AnswerTextChanged(t)),
                  ),
                ] else ...[
                  ...state.mcOptions.map((opt) {
                    return RadioListTile<String>(
                      title: Text(opt),
                      value: opt,
                      groupValue: state.chosenOption,
                      onChanged: state.checked
                          ? null
                          : (v) {
                              if (v != null) {
                                context.read<QuizBloc>().add(ChooseOption(v));
                              }
                            },
                    );
                  }),
                ],
                const SizedBox(height: 16),
                if (state.feedback != null) ...[
                  Text(
                    state.feedback!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: state.wasCorrect == true
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: state.checked
                            ? null
                            : () => context.read<QuizBloc>().add(CheckAnswer()),
                        child: const Text('Check Answer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: state.checked
                            ? () => context.read<QuizBloc>().add(NextQuestion())
                            : null,
                        child: const Text('Next Question'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}