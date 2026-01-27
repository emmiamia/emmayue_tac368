// Dice.dart

// Emma Yue

import "package:flutter/material.dart";
import 'dart:math';

void main() // 23
{
  runApp(Yahtzee());
}

class Yahtzee extends StatelessWidget
{
  const Yahtzee({super.key});

  @override
  Widget build( BuildContext context )
  { return const MaterialApp
    ( title: "Yahtzee",
      home: YahtzeeHome(),
    );
  }
}

class YahtzeeHome extends StatefulWidget
{
  const YahtzeeHome({super.key});

  @override
  State<YahtzeeHome> createState() => YahtzeeHomeState();
}
    
class YahtzeeHomeState extends State<YahtzeeHome>
{
  final Random rand = Random();

  List<int> dice = [1, 1, 1, 1, 1];
  List<bool> held = [false, false, false, false, false];
  void rollDice() {
    setState(() {
      for (int i = 0; i < 5; i++) {
        if (!held[i]) {
          dice[i] = rand.nextInt(6) + 1;
        }
      }
    });
  }

  void flipHold(int i) {
    setState(() {
      held[i] = !held[i];
    });
  }

  String face(int v) {
    const f = [1, 2, 3, 4, 5, 6];
    return f[v-1].toString();
  }
  
  @override
  Widget build( BuildContext context )
  { return Scaffold
    ( appBar: AppBar(title: const Text("yahtzee")),
      body: Column
      ( children:
        [ const Text
          ( "YAHTZEE", 
            style: TextStyle
            ( fontSize: 35,
              color: Colors.orange,
            ) 
          ),
          const SizedBox(height: 12),

          const Text
          ( "Press ROLL. Tap HOLD to keep dice.",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ), 
          ),
          const SizedBox(height: 18),

          Container(
            decoration: BoxDecoration(
              color: Colors.pink,
              border: Border.all(width: 8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // dice row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return Container(
                      margin: const EdgeInsets.all(6),
                      width: 45,
                      height: 45,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        // ONLY modifying purpose: held dice look different
                        color: held[i] ? Colors.grey : Colors.white,
                        border: Border.all(width: 2),
                      ),
                      child: Text(
                        face(dice[i]),
                        style: const TextStyle(fontSize: 22),
                      ),
                    );
                  }),
                ),

                // hold buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return TextButton(
                      onPressed: () => flipHold(i),
                      child: Text(held[i] ? "FREE" : "HOLD"),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          GestureDetector(
            onTap: rollDice,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(width: 1),
              ),
              height: 100,
              width: 100,
              child: Stack(
                children: [
                  const Positioned(
                    left: 18,
                    top: 38,
                    child: Text(
                      "ROLL",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // keep your dot, just as decoration
                  Positioned(
                    left: 80,
                    top: 70,
                    child: Container(
                      height: 10,
                      width: 10,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]
      ),
    );
  }
}

