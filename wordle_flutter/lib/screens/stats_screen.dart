import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../services/storage_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.storage});

  final StorageService storage;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<_StatsSnapshot> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<_StatsSnapshot> _fetch() async {
    final dist = await widget.storage.guessDistribution;
    final played = await widget.storage.gamesPlayed;
    final won = await widget.storage.gamesWon;
    final streak = await widget.storage.currentStreak;
    final best = await widget.storage.bestStreak;
    final history = await widget.storage.guessHistory;
    return _StatsSnapshot(
      distribution: dist,
      gamesPlayed: played,
      gamesWon: won,
      currentStreak: streak,
      bestStreak: best,
      history: history,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statisticsTitle)),
      body: FutureBuilder<_StatsSnapshot>(
        future: _load,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snap.data!;
          final winRate = s.gamesPlayed == 0 ? 0.0 : s.gamesWon / s.gamesPlayed;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  _StatTile(label: l10n.statsPlayed, value: '${s.gamesPlayed}'),
                  _StatTile(label: l10n.statsWinPercent, value: '${(winRate * 100).round()}'),
                  _StatTile(label: l10n.statsStreak, value: '${s.currentStreak}'),
                  _StatTile(label: l10n.statsBest, value: '${s.bestStreak}'),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                l10n.guessDistribution,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...List.generate(6, (i) {
                final guesses = i + 1;
                final count = s.distribution[i];
                final maxVal = s.distribution.reduce((a, b) => a > b ? a : b);
                final frac = maxVal == 0 ? 0.0 : count / maxVal;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 24, child: Text('$guesses')),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: frac.clamp(0.0, 1.0),
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 32),
              Text(
                l10n.recentGames,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (s.history.isEmpty)
                Text(
                  '—',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                )
              else
                ...s.history.take(12).map((e) {
                  final outcome = e.won ? l10n.historyWin : l10n.historyLoss;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('$outcome · ${l10n.historyAttempts(e.attempts)}'),
                    subtitle: Text('${e.date} · ${e.guesses.join(", ")}'),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _StatsSnapshot {
  _StatsSnapshot({
    required this.distribution,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.currentStreak,
    required this.bestStreak,
    required this.history,
  });

  final List<int> distribution;
  final int gamesPlayed;
  final int gamesWon;
  final int currentStreak;
  final int bestStreak;
  final List<GuessHistoryEntry> history;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
