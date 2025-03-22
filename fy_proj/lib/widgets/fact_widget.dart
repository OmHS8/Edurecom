import 'package:flutter/material.dart';
// import 'dart:math';

class FactOfTheDay extends StatefulWidget {
  @override
  _FactOfTheDayState createState() => _FactOfTheDayState();
}

class _FactOfTheDayState extends State<FactOfTheDay> {
  final List<String> facts = [
    "Honey never spoils. Archaeologists have found pots of honey in ancient Egyptian tombs that are over 3000 years old and still edible!",
    "Octopuses have three hearts and blue blood.",
    "Bananas are berries, but strawberries are not!",
    "There are more stars in the universe than grains of sand on Earth.",
    "Wombat poop is cube-shaped to prevent it from rolling away.",
    "A day on Venus is longer than a year on Venus.",
  ];

  late String factOfTheDay;

  @override
  void initState() {
    super.initState();
    // factOfTheDay = facts[Random().nextInt(facts.length)];
    factOfTheDay = "In CPU scheduling, turn around time is arrival time subtracted from completion time";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.yellow, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Fact of the Day",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      factOfTheDay,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
