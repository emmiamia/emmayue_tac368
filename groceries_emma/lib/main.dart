// groceries _Emma Yue
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const GroceryApp());
}

class Grocery {
  static const String _key = 'grocery_items_v1';

  Future<List<String>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> saveItems(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items));
  }
}

sealed class GroceryEvent extends Equatable {
  const GroceryEvent();
  @override
  List<Object?> get props => [];
}

class GroceryLoad extends GroceryEvent {
  const GroceryLoad();
}

class GroceryAdd extends GroceryEvent {
  final String item;
  const GroceryAdd(this.item);

  @override
  List<Object?> get props => [item];
}

class GroceryDeleteRequested extends GroceryEvent {
  final int index;
  const GroceryDeleteRequested(this.index);

  @override
  List<Object?> get props => [index];
}

class GroceryClearRequested extends GroceryEvent {
  const GroceryClearRequested();
}

class GroceryState extends Equatable {
  final bool isLoading;
  final List<String> items;
  final String? errorMessage;

  const GroceryState({
    required this.isLoading,
    required this.items,
    this.errorMessage,
  });

  factory GroceryState.initial() => const GroceryState(
        isLoading: true,
        items: <String>[],
        errorMessage: null,
      );

  GroceryState copyWith({
    bool? isLoading,
    List<String>? items,
    String? errorMessage,
  }) {
    return GroceryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, errorMessage];
}

class GroceryBloc extends Bloc<GroceryEvent, GroceryState> {
  final Grocery repo;

  GroceryBloc({required this.repo}) : super(GroceryState.initial()) {
    on<GroceryLoad>(_onLoad);
    on<GroceryAdd>(_onAdd);
    on<GroceryDeleteRequested>(_onDelete);
    on<GroceryClearRequested>(_onClear);
  }

  Future<void> _onLoad(
    GroceryLoad event,
    Emitter<GroceryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final items = await repo.loadItems();
      emit(state.copyWith(isLoading: false, items: items));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load: $e',
      ));
    }
  }

  Future<void> _onAdd(
    GroceryAdd event,
    Emitter<GroceryState> emit,
  ) async {
    final trimmed = event.item.trim();
    if (trimmed.isEmpty) return;

    final updated = List<String>.from(state.items)..add(trimmed);
    emit(state.copyWith(items: updated, errorMessage: null));

    // Auto-save after each change
    await repo.saveItems(updated);
  }

  Future<void> _onDelete(
    GroceryDeleteRequested event,
    Emitter<GroceryState> emit,
  ) async {
    if (event.index < 0 || event.index >= state.items.length) return;

    final updated = List<String>.from(state.items)..removeAt(event.index);
    emit(state.copyWith(items: updated, errorMessage: null));

    await repo.saveItems(updated);
  }

  Future<void> _onClear(
    GroceryClearRequested event,
    Emitter<GroceryState> emit,
  ) async {
    const updated = <String>[];
    emit(state.copyWith(items: updated, errorMessage: null));
    await repo.saveItems(updated);
  }
}

class GroceryApp extends StatelessWidget {
  const GroceryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groceries',
      theme: ThemeData(useMaterial3: true),
      home: RepositoryProvider(
        create: (_) => Grocery(),
        child: BlocProvider(
          create: (context) => GroceryBloc(
            repo: context.read<Grocery>(),
          )..add(const GroceryLoad()),
          child: const GroceryPage(),
        ),
      ),
    );
  }
}

class GroceryPage extends StatefulWidget {
  const GroceryPage({super.key});

  @override
  State<GroceryPage> createState() => _GroceryPageState();
}

class _GroceryPageState extends State<GroceryPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    context.read<GroceryBloc>().add(GroceryAdd(_controller.text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groceries'),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            onPressed: () => context.read<GroceryBloc>().add(const GroceryClearRequested()),
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: BlocBuilder<GroceryBloc, GroceryState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          labelText: 'Add grocery item',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _add,
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: state.items.isEmpty
                    ? const Center(child: Text('No items yet. Add one above!'))
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final item = state.items[index];

                          return Dismissible(
                            key: ValueKey('$item-$index'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              color: Colors.red,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) {
                              context.read<GroceryBloc>().add(GroceryDeleteRequested(index));
                            },
                            child: ListTile(
                              title: Text(item),
                              trailing: IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.close),
                                onPressed: () => context.read<GroceryBloc>().add(
                                      GroceryDeleteRequested(index),
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
