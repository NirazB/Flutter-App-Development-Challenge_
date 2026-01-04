import 'package:flutter/material.dart';
import '../main.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    //default ip
    _ipController.text = "192.168.1.6";
  }

  void _connect() {
    String ip = _ipController.text.trim();
    if (ip.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage(ipAddress: ip)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connect to PC")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter PC IP Address",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "IP Address",
                hintText: "e.g. 192.168.1.6",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connect,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: const Text("Connect", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
