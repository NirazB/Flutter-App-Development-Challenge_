import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Flutter Demo', home: CounterWidget());
  }
}

class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
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
      appBar: AppBar(
        title: const Text("Flutter Demo Page"),
        backgroundColor: Colors.blue,
      ),
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
