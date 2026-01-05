import "package:flutter/material.dart";
// import 'package:day8/pages/esp32_page.dart';
import 'package:day10/pages/esp32_page.dart';
import 'package:day8/pages/home_page.dart';
import 'package:day8/pages/dht11_temp.dart';
import 'package:day9/pages/servo.dart';
import 'package:day10/pages/ir_sensor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;
  final List<Widget> pages = [
    const Homepage(),
    const EspPage(),
    const Dht11Temp(),
    const ServoPage(),
    const IrSensor(),
  ];
  final list = ['Home', 'ESP ', 'DHT11', 'Servo', 'IR'];
  final List<Color> pageColors = [
    const Color.fromARGB(255, 0, 0, 0),
    Colors.blueAccent,
    Colors.orange,
    Colors.deepPurple,
    Colors.red,
  ];
  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            list[selectedIndex],
            style: TextStyle(color: pageColors[selectedIndex]),
          ),
        ),
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.blue,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.memory), label: 'ESP'),
          BottomNavigationBarItem(icon: Icon(Icons.thermostat), label: 'DHT11'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_remote),
            label: 'Servo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.sensor_door), label: 'IR'),
        ],
      ),
    );
  }
}
