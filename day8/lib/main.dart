import "package:flutter/material.dart";
import './pages/esp32_page.dart';
import './pages/home_page.dart';
import './pages/dht11_temp.dart';

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
  ];
  final list = ['Home', 'ESP ', 'DHT11'];
  final List<Color> pageColors = [
    const Color.fromARGB(255, 0, 0, 0),
    Colors.blueAccent,
    Colors.orange,
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
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.blue,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.memory), label: 'ESP'),
          BottomNavigationBarItem(icon: Icon(Icons.thermostat), label: 'DHT11'),
        ],
      ),
    );
  }
}
