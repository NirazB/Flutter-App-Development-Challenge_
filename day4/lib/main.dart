import 'package:flutter/material.dart';
import './pages/clock_widget.dart';
import './pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Day 4 App', home: const MainPage());
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

  final List<Widget> pages = [const HomePage(), const ClockWidget()];

  final list = ['Home', 'Clock'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            '${list[selectedIndex]} Page',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 29, 32, 34),
      ),
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 29, 32, 34),
        unselectedItemColor: const Color.fromARGB(179, 150, 147, 147),
        selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        currentIndex: selectedIndex,
        onTap: navigateBar,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 25),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time, size: 25),
            label: 'Clock',
          ),
        ],
      ),
    );
  }
}
