import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const LightsOutApp());
}

class LightsOutApp extends StatelessWidget {
  const LightsOutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lights Out',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: BlocProvider(
        create: (_) => LightsBloc(),
        child: const LightsOutPage(),
      ),
    );
  }
}

class LightsState {
  final List<bool> lights; // true = ON, false = OFF

  const LightsState({required this.lights});

  bool get hasWon => lights.every((x) => x == false);

  LightsState copyWith({List<bool>? lights}) {
    return LightsState(lights: lights ?? this.lights);
  }
}


abstract class LightsEvent {}

class NewGame extends LightsEvent {
  final int count;
  NewGame(this.count);
}

class ToggleLight extends LightsEvent {
  final int index;
  ToggleLight(this.index);
}

class IncreaseLights extends LightsEvent {}

class DecreaseLights extends LightsEvent {}


class LightsBloc extends Bloc<LightsEvent, LightsState> {
  final Random _rng = Random();

  static const int minLights = 3;
  static const int maxLights = 30;

  LightsBloc() : super(const LightsState(lights: [])) {
    on<NewGame>(_onNewGame);
    on<ToggleLight>(_onToggle);
    on<IncreaseLights>(_onIncrease);
    on<DecreaseLights>(_onDecrease);

    add(NewGame(9));
  }

  List<bool> _randomLights(int n) {
    return List<bool>.generate(n, (_) => _rng.nextBool());
  }

  void _onNewGame(NewGame event, Emitter<LightsState> emit) {
    emit(LightsState(lights: _randomLights(event.count)));
  }

  void _onToggle(ToggleLight event, Emitter<LightsState> emit) {
    final old = state.lights;
    final n = old.length;
    final i = event.index;

    if (i < 0 || i >= n) return;

    final next = List<bool>.from(old);

    void flip(int idx) {
      if (idx >= 0 && idx < n) {
        next[idx] = !next[idx];
      }
    }

    flip(i - 1);
    flip(i);
    flip(i + 1);

    emit(state.copyWith(lights: next));
  }

  void _onIncrease(IncreaseLights event, Emitter<LightsState> emit) {
    final n = state.lights.length;
    if (n >= maxLights) return;
    emit(LightsState(lights: _randomLights(n + 1)));
  }

  void _onDecrease(DecreaseLights event, Emitter<LightsState> emit) {
    final n = state.lights.length;
    if (n <= minLights) return;
    emit(LightsState(lights: _randomLights(n - 1)));
  }
}


class LightsOutPage extends StatelessWidget {
  const LightsOutPage({super.key});

  Color _lightColor(bool isOn) =>
      isOn ? Colors.yellow : Colors.brown;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LightsBloc>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lights Out'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<LightsBloc, LightsState>(
          builder: (context, state) {
            final lights = state.lights;

            return Column(
              children: [
                const Text(
                  'Tap a light to flip it and its neighbors.\n'
                  'Goal: turn ALL lights off.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Row of lights (wraps if many)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: List.generate(lights.length, (i) {
                    return GestureDetector(
                      onTap: () => bloc.add(ToggleLight(i)),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _lightColor(lights[i]),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black12),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 3,
                              offset: Offset(0, 2),
                              color: Colors.black12,
                            )
                          ],
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // Win message
                AnimatedOpacity(
                  opacity: state.hasWon ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: const Text(
                    '🎉 You win! All lights are out.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const Spacer(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => bloc.add(DecreaseLights()),
                      icon: const Icon(Icons.remove),
                      label: const Text('Fewer'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => bloc.add(IncreaseLights()),
                      icon: const Icon(Icons.add),
                      label: const Text('More'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // New game (same size)
                OutlinedButton(
                  onPressed: () =>
                      bloc.add(NewGame(lights.length)),
                  child: Text('New Game (${lights.length} lights)'),
                ),

                const SizedBox(height: 8),
                Text(
                  'Lights: ${lights.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
