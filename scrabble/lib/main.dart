// Host/client entry and navigation into the shared game screen.

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "app_theme.dart";
import "server_state.dart";
import "yak_state.dart";
import "player.dart";

void main() {
  runApp(ServerOrClient());
}

class ServerOrClient extends StatelessWidget {
  ServerOrClient({super.key});

  final TextEditingController tec = TextEditingController(text: "localhost");

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Scrabble Two Computer",
      theme: buildAppTheme(),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Scrabble: server or client?")),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ServerBase(),
                      ),
                    );
                  },
                  child: const Text("server / host"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ClientBase(tec.text.trim()),
                      ),
                    );
                  },
                  child: const Text("client"),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: tec,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "host ip",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ServerBase extends StatelessWidget {
  const ServerBase({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ServerCubit>(
      create: (context) => ServerCubit(),
      child: BlocBuilder<ServerCubit, ServerState>(
        builder: (context, state) {
          final sc = BlocProvider.of<ServerCubit>(context);
          final ss = sc.state;

          if (ss.server == null) {
            return const Scaffold(
              body: Center(child: Text("loading server socket...")),
            );
          }

          return BlocProvider<YakCubit>(
            create: (context) => YakCubit.server(ss.server),
            child: BlocBuilder<YakCubit, YakState>(
              builder: (context, state) {
                final yc = BlocProvider.of<YakCubit>(context);
                final ys = yc.state;

                return ys.socket == null
                    ? const Scaffold(
                        body: Center(child: Text("waiting for client...")),
                      )
                    : const Player(true);
              },
            ),
          );
        },
      ),
    );
  }
}

class ClientBase extends StatelessWidget {
  final String ip;
  const ClientBase(this.ip, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<YakCubit>(
      create: (context) => YakCubit(ip),
      child: BlocBuilder<YakCubit, YakState>(
        builder: (context, state) {
          return const Player(false);
        },
      ),
    );
  }
}