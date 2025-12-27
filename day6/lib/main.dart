import 'package:flutter/material.dart';
import './pages/homepage.dart';
import './pages/esp_page.dart';

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
  int _selectedIndex = 0;
  void naviagtionBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final list = ['Home', 'ESP'];
  final List<Widget> pages = [
    Homepage(),
    EspPage(),
    Center(child: Text('About Page')),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: Text(list[_selectedIndex]))),
      body: Center(child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: naviagtionBar,
        currentIndex: _selectedIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.memory), label: 'ESP'),
        ],
      ),
    );
  }
}
