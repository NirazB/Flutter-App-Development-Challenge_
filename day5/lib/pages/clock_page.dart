import 'package:flutter/material.dart';
import 'package:day4/pages/clock_widget.dart';

class ClockPage extends StatefulWidget {
  const ClockPage({super.key});

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: ClockWidget()));
  }
}
