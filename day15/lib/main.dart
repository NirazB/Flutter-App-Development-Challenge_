import 'package:flutter/material.dart';
import 'dart:io';
import 'pages/connect_page.dart';
import 'pages/gyropage.dart';
import 'pages/touchpage.dart';
import 'pages/mobile.dart';
import 'pages/laptop_control_page.dart';
import 'pages/laptop_performance.dart';
import 'pages/file_transfer_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flux Vision Remote',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
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

  final List<String> titles = [
    "Touchpad",
    "Gyro",
    "Vision",
    "Laptop Control",
    "Performance",
    "File Transfer",
  ];

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      TouchPage(ipAddress: widget.ipAddress),
      Gyropage(ipAddress: widget.ipAddress),
      MobilePage(ipAddress: widget.ipAddress),
      LaptopControlPage(ipAddress: widget.ipAddress),
      LaptopPerformancePage(ipAddress: widget.ipAddress),
      FileTransferScreen(ipAddress: widget.ipAddress),
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
      appBar: AppBar(
        centerTitle: true,
        title: Text(titles[currentIndex]),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: IndexedStack(index: currentIndex, children: pages),
      // Sidebar Navigation
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E293B)),
              accountName: const Text("Flux Vision System"),
              accountEmail: Text("Server: ${widget.ipAddress}"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.router, color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: const Text('Change IP Address'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ConnectPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.touch_app),
              title: const Text("Touchpad"),
              onTap: () {
                setState(() {
                  currentIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.vibration),
              title: const Text("Gyro"),
              onTap: () {
                setState(() {
                  currentIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text("Vision"),
              onTap: () {
                setState(() {
                  currentIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.laptop),
              title: const Text("Laptop Control"),
              onTap: () {
                setState(() {
                  currentIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text("Performance"),
              onTap: () {
                setState(() {
                  currentIndex = 4;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text("File Transfer"),
              onTap: () {
                setState(() {
                  currentIndex = 5;
                });
                Navigator.pop(context);
              },
            ),

            const Spacer(),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "v1.0.2 - Finale Edition",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
      // Bottom Bar Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: navigateTo,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.touch_app), label: 'Touch'),
          BottomNavigationBarItem(icon: Icon(Icons.vibration), label: 'Gyro'),
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam),
            label: 'Detection',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.laptop), label: 'Laptop'),
          BottomNavigationBarItem(
            icon: Icon(Icons.speed),
            label: 'Performance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_upload),
            label: 'Files',
          ),
        ],
      ),
    );
  }
}
