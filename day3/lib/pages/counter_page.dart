import 'package:flutter/material.dart';
import 'dart:math';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int counter = 0;
  Color bg = Colors.white;
  Color fbg = Colors.black;
  void incrementCounter() {
    setState(() {
      final r = Random();
      counter++;
      bg = bg == Colors.white
          ? Color.fromARGB(255, r.nextInt(256), r.nextInt(256), r.nextInt(256))
          : Colors.white;
      fbg = fbg == Colors.black ? Colors.white : Colors.black;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: incrementCounter,
              child: const Text("Increment Counter"),
            ),
            ElevatedButton(
              child: Container(
                margin: const EdgeInsets.all(10.0),
                child: const Text("Reset Counter"),
              ),
              onPressed: () {
                setState(() {
                  counter = 0;
                  bg = Colors.white;
                  fbg = Colors.black;
                });
              },
              // child: const Text("Reset Counter"),
            ),
            Text(
              'Counter Value: $counter',
              style: TextStyle(fontSize: 16, color: fbg),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: Container(
          height: 500.0,
          color: const Color.fromARGB(255, 0, 0, 0),
          child: Center(
            child: Text(
              "This is Drawer",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
