import 'package:flutter/material.dart';
import 'pages/connect_page.dart';
import 'pages/gyropage.dart';
import 'pages/touchpage.dart';

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
      home: const ConnectPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  final String ipAddress;
  const MainPage({super.key, required this.ipAddress});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  final list = ["Gyro", "Touch"];
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      Gyropage(ipAddress: widget.ipAddress),
      TouchPage(ipAddress: widget.ipAddress),
    ];
  }

  void navigateTo(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(list[currentIndex])),
      body: pages[currentIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 120,
              child: const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Center(
                  child: Text(
                    'Controller Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Change IP Address'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ConnectPage()),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: navigateTo,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.vibration), label: 'Gyro'),
          BottomNavigationBarItem(icon: Icon(Icons.touch_app), label: 'Touch'),
        ],
      ),
    );
  }
}
