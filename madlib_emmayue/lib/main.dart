// Emma Yue - Lab10 Madlib (Version 1)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => MadlibCubit(),
      child: MadlibApp(),
    ),
  );
}

// demo of a simple page
class MadlibApp extends StatelessWidget {
  MadlibApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Lab10 Madlib Emma Yue",
      home: MadlibHome(),
    );
  }
}

class MadlibHome extends StatefulWidget {
  @override
  State<MadlibHome> createState() => MadlibHomeState();
}

class MadlibHomeState extends State<MadlibHome> {
  final TextEditingController tec = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MadlibCubit, MadlibState>(
      builder: (context, curr) {
        final question = curr.question[curr.index];

        return Scaffold(
          appBar: AppBar(title: const Text("Madlib Emma Yue")),
          body: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                "Fill in words, then press NEXT.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),

              // Prompt
              Text(
                "Blank #${curr.index}: $question",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Container(
                height: 50,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(width: 2),
                ),
                child: TextField(
                  controller: tec,
                  style: const TextStyle(fontSize: 30),
                ),
              ),

              const SizedBox(height: 10),

              // Barrett-style button to "copy" the entry into state
              FloatingActionButton(
                onPressed: () {
                  context.read<MadlibCubit>().submit(tec.text);
                  tec.clear();
                },
                child: const Text("next"),
              ),

              const SizedBox(height: 16),

              // Show answers so far
              TextWithBorder(
                "Answers: ${_answersPreview(curr.answers)}",
                height: 70,
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => context.read<MadlibCubit>().go(),
                    child: const Text("GO"),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      tec.clear();
                      context.read<MadlibCubit>().reset();
                    },
                    child: const Text("RESET"),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Story output
              if (curr.story.isNotEmpty) ...[
                const Text(
                  "Your story:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextWithBorder(curr.story, height: 160),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _answersPreview(List<String> answers) {
    final parts = <String>[];
    for (int i = 0; i < answers.length; i++) {
      final v = answers[i].trim().isEmpty ? "(blank)" : answers[i].trim();
      parts.add("[$i]=$v");
    }
    return parts.join(", ");
  }
}


class MadlibState extends Equatable {
  final List<String> question;   
  final List<String> answers;   
  final int index;              
  final String story;           

  const MadlibState({
    required this.question,
    required this.answers,
    required this.index,
    required this.story,
  });

  static MadlibState initial() {
    const question = [
      "Choose a place (noun):",
      "Choose an animal (noun):",
      "Enter a number:",
      "Name a thing (plural noun):",
    ];

    return MadlibState(
      question: question,
      answers: ["", "", "", ""],
      index: 0,
      story: "",
    );
  }

  MadlibState copyWith({
    List<String>? question,
    List<String>? answers,
    int? index,
    String? story,
  }) {
    return MadlibState(
      question: question ?? this.question,
      answers: answers ?? this.answers,
      index: index ?? this.index,
      story: story ?? this.story,
    );
  }

  @override
  List<Object?> get props => [question, answers, index, story];
}

class MadlibCubit extends Cubit<MadlibState> {
  MadlibCubit() : super(MadlibState.initial());

  void submit(String input) {
    final updated = List<String>.from(state.answers);
    updated[state.index] = input.trim();

    int next = state.index + 1;
    if (next >= updated.length) next = 0; 

    emit(state.copyWith(
      answers: updated,
      index: next,
      story: "", 
    ));
  }

  void reset() {
    emit(MadlibState.initial());
  }

  void go() {
    final filled = <String>[];
    for (int i = 0; i < state.answers.length; i++) {
      final v = state.answers[i].trim();
      filled.add(v.isEmpty ? "(blank)" : v);
    }

    final place = filled[0];
    final animal = filled[1];
    final number = filled[2];
    final thing = filled[3];

    final story =
        "When I was in $place, I bought a pet $animal.\n"
        "I traded $number $thing to get the $animal.";

    emit(state.copyWith(story: story));
  }
}

class TextWithBorder extends StatelessWidget {
  final String s;
  final double height;

  const TextWithBorder(this.s, {super.key, this.height = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: 300,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: const Color(0xff0000ff)),
      ),
      child: SingleChildScrollView(
        child: Text(s, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}