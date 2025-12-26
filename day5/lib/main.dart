import 'package:day5/pages/home_page.dart';
import 'package:day5/pages/map_page.dart';
import 'package:flutter/material.dart';
import './pages/weather_page.dart';
import './pages/clock_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Day 5',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainPage(),
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

  void navigator(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  final list = ['Home', 'Weather', 'Clock', 'Map'];

  final List<Color> colors = [
    Color.fromARGB(255, 235, 235, 235),
    Colors.blue.shade100,
    Color.fromARGB(255, 29, 32, 34),
    Colors.green.shade100,
  ];
  final List<Color> textColors = [
    Color.fromARGB(255, 0, 0, 0),
    Color.fromARGB(255, 255, 255, 255),
    Color.fromARGB(255, 255, 255, 255),
    Color.fromARGB(255, 0, 0, 0),
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(onTabChange: navigator),
      GetWeather(),
      ClockPage(),
      MapPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            list[selectedIndex],
            style: TextStyle(color: textColors[selectedIndex], fontSize: 24),
          ),
        ),
        backgroundColor: colors[selectedIndex],
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colors[selectedIndex],
        selectedItemColor: textColors[selectedIndex],
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: navigator,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Weather'),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Clock',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }
}
