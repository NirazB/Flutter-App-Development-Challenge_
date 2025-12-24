import 'package:flutter/material.dart';
import 'pages/weather_page.dart';
import './pages/home_page.dart';
import './pages/counter_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: "Flutter Day 3 App", home: const MainPage());
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;
  void navigateBar(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  final List<Widget> pages = [
    const HomePage(),
    const WeatherPage(),
    const CounterPage(),
  ];

  final titles = ["Home Page", "Weather Page", "Counter Page"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            titles[selectedIndex],
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.deepPurple,
        selectedIconTheme: IconThemeData(color: Colors.white, size: 30),
        unselectedIconTheme: IconThemeData(color: Colors.white70, size: 24),
        currentIndex: selectedIndex,
        onTap: navigateBar,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_cloudy),
            label: "Weather",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.numbers), label: "Counter"),
        ],
      ),
    );
  }
}
