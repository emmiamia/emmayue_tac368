//Emma Yue
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => CalcBloc(),
      child: const ConverterApp(),
    ),
  );
}

enum ConvertChoice { ctof, ftoc, kgtolb, lbtokg }

class NumPressed {
  final String num;
  NumPressed(this.num);
}

class DecimalPressed {}

class ToggleNegativePressed {}

class OperationPressed {
  final ConvertChoice choice;
  OperationPressed(this.choice);
}

@immutable
class CalcState {
  final String input;
  final String output;

  const CalcState({
    required this.input,
    required this.output,
  });

  CalcState copyWith({
    String? input,
    String? output,
  }) {
    return CalcState(
      input: input ?? this.input,
      output: output ?? this.output,
    );
  }

  static const initial = CalcState(input: '', output: '');
}

class CalcBloc extends Bloc<Object, CalcState> {
  CalcBloc() : super(CalcState.initial) {
    on<NumPressed>(_onNum);
    on<DecimalPressed>(_onDecimal);
    on<ToggleNegativePressed>(_onToggleNegative);
    on<OperationPressed>(_onOperation);
  }

  void _onNum(NumPressed e, Emitter<CalcState> emit) {
    final current = state.input;

    if (current == '0') {
      emit(state.copyWith(input: e.num));
      return;
    }
    if (current == '-0') {
      emit(state.copyWith(input: '-${e.num}'));
      return;
    }

    emit(state.copyWith(input: current + e.num));
  }

  void _onDecimal(DecimalPressed e, Emitter<CalcState> emit) {
    final current = state.input;

    if (current.isEmpty) {
      emit(state.copyWith(input: '0.'));
      return;
    }
    if (current == '-') {
      emit(state.copyWith(input: '-0.'));
      return;
    }
    if (current.contains('.')) return;

    emit(state.copyWith(input: current + '.'));
  }

  void _onToggleNegative(ToggleNegativePressed e, Emitter<CalcState> emit) {
    final current = state.input;

    if (current.isEmpty) {
      emit(state.copyWith(input: '-'));
      return;
    }

    if (current.startsWith('-')) {
      emit(state.copyWith(input: current.substring(1)));
    } else {
      emit(state.copyWith(input: '-$current'));
    }
  }

  void _onOperation(OperationPressed e, Emitter<CalcState> emit) {
    final raw = state.input.trim();

    if (raw.isEmpty || raw == '-') {
      emit(state.copyWith(output: 'Enter a number'));
      return;
    }

    final value = double.tryParse(raw);
    if (value == null) {
      emit(state.copyWith(output: 'Invalid'));
      return;
    }

    final result = _convert(value, e.choice);
    final formatted = _formatNumber(result);

    emit(state.copyWith(input: '', output: formatted));
  }

  double _convert(double x, ConvertChoice op) {
    switch (op) {
      case ConvertChoice.ctof:
        return (x * (9.0 / 5.0)) + 32.0;
      case ConvertChoice.ftoc:
        return (x - 32.0) * (5.0 / 9.0);
      case ConvertChoice.kgtolb:
        return x / 0.45359237;
      case ConvertChoice.lbtokg:
        return x * 0.45359237;
    }
  }

  String _formatNumber(double x) => x.toStringAsFixed(4);
}

class ConverterApp extends StatelessWidget {
  const ConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Converter',
      debugShowCheckedModeBanner: false,
      home: ConverterScreen(),
    );
  }
}

class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF7F2F6);
    const border = Color(0xFF2C2C2C);
    const btnFill = Color(0xFFE6DDF6);
    const btnText = Color(0xFF5B3FA6);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: border, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 2),
                    const Text(
                      'Converter',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<CalcBloc, CalcState>(
                      builder: (context, state) {
                        return Row(
                          children: [
                            Expanded(
                              child: _DisplayBox(
                                text: state.input,
                                borderColor: border,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DisplayBox(
                                text: state.output,
                                borderColor: border,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final w = constraints.maxWidth;
                              final buttonSize = (w - 20) / 3;
                              final keypadHeight = buttonSize * 4 + 30;
                              return SizedBox(
                                width: double.infinity,
                                height: keypadHeight,
                                child: _KeypadGrid(
                                  borderColor: border,
                                  fillColor: btnFill,
                                  textColor: btnText,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _OpButton(
                                label: 'C-F',
                                borderColor: border,
                                fillColor: btnFill,
                                textColor: btnText,
                                onTap: () => context.read<CalcBloc>().add(
                                      OperationPressed(ConvertChoice.ctof),
                                    ),
                              ),
                              const SizedBox(height: 10),
                              _OpButton(
                                label: 'F-C',
                                borderColor: border,
                                fillColor: btnFill,
                                textColor: btnText,
                                onTap: () => context.read<CalcBloc>().add(
                                      OperationPressed(ConvertChoice.ftoc),
                                    ),
                              ),
                              const SizedBox(height: 10),
                              _OpButton(
                                label: 'Kg-Lb',
                                borderColor: border,
                                fillColor: btnFill,
                                textColor: btnText,
                                onTap: () => context.read<CalcBloc>().add(
                                      OperationPressed(ConvertChoice.kgtolb),
                                    ),
                              ),
                              const SizedBox(height: 10),
                              _OpButton(
                                label: 'Lb-Kg',
                                borderColor: border,
                                fillColor: btnFill,
                                textColor: btnText,
                                onTap: () => context.read<CalcBloc>().add(
                                      OperationPressed(ConvertChoice.lbtokg),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DisplayBox extends StatelessWidget {
  final String text;
  final Color borderColor;

  const _DisplayBox({
    required this.text,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Text(
        text.isEmpty ? ' ' : text,
        style: const TextStyle(fontSize: 22),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _KeypadGrid extends StatelessWidget {
  final Color borderColor;
  final Color fillColor;
  final Color textColor;

  const _KeypadGrid({
    required this.borderColor,
    required this.fillColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _keyRow(context, const ['7', '8', '9'])),
        const SizedBox(height: 10),
        Expanded(child: _keyRow(context, const ['4', '5', '6'])),
        const SizedBox(height: 10),
        Expanded(child: _keyRow(context, const ['1', '2', '3'])),
        const SizedBox(height: 10),
        Expanded(child: _keyRow(context, const ['.', '0', '-'])),
      ],
    );
  }

  Widget _keyRow(BuildContext context, List<String> row) {
    return Row(
      children: [
        for (int i = 0; i < row.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == row.length - 1 ? 0 : 10),
              child: _KeyButton(
                label: row[i],
                borderColor: borderColor,
                fillColor: fillColor,
                textColor: textColor,
                onTap: () {
                  final bloc = context.read<CalcBloc>();
                  final k = row[i];
                  if (k == '.') {
                    bloc.add(DecimalPressed());
                  } else if (k == '-') {
                    bloc.add(ToggleNegativePressed());
                  } else {
                    bloc.add(NumPressed(k));
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final Color borderColor;
  final Color fillColor;
  final Color textColor;
  final VoidCallback onTap;

  const _KeyButton({
    required this.label,
    required this.borderColor,
    required this.fillColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fillColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _OpButton extends StatelessWidget {
  final String label;
  final Color borderColor;
  final Color fillColor;
  final Color textColor;
  final VoidCallback onTap;

  const _OpButton({
    required this.label,
    required this.borderColor,
    required this.fillColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: Material(
        color: fillColor,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}