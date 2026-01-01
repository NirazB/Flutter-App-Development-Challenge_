import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EspPage extends StatefulWidget {
  const EspPage({super.key});

  @override
  State<EspPage> createState() => _EspPageState();
}

class _EspPageState extends State<EspPage> {
  late DatabaseReference _dbRef;

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref("sensor_data");
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.blueAccent),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 240, 240),
      // StreamBuilder to listen to Firebase
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            // Extracting data from firebase snapshot
            final data = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map,
            );

            bool isDetected = data['presence'] ?? false;
            double temp = (data['temperature'] ?? 0.0).toDouble();
            int uptime = data['timestamp'] ?? 0;

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(uptime, temp), //to show esp status
                  const SizedBox(height: 10),
                  _buildLedControl(isDetected), //to contrl led
                  const SizedBox(height: 10),
                  _buildPresenceIndicator(isDetected), //for Ir sensor
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  //Header UI
  Widget _buildHeader(int uptime, double temp) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 40, left: 10, right: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue],
          ),
        ),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(
                Icons.developer_board,
                size: 40,
                color: Colors.black,
              ),
              title: Text(
                "ESP32 Cloud Node",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              subtitle: Text(
                "Status: ONLINE",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Uptime", "$uptime s", Icons.timer),
                _buildStatCard("Temp", "$temp°C", Icons.thermostat),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedControl(bool isDetected) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: ListTile(
        leading: Icon(
          Icons.lightbulb,
          color: isDetected ? Colors.yellow : Colors.grey,
        ),
        title: const Text("Hardware LED Status"),
        subtitle: Text(isDetected ? "Triggered by IR" : "Standby"),
        trailing: const Icon(Icons.cloud_done, color: Colors.blue, size: 16),
      ),
    );
  }

  Widget _buildPresenceIndicator(bool isDetected) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDetected
            ? Colors.red.withAlpha(25)
            : Colors.green.withAlpha(25),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDetected ? Colors.red : Colors.green),
      ),
      child: Row(
        children: [
          Icon(
            isDetected
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            color: isDetected ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 10),
          Text(
            isDetected ? "PRESENCE DETECTED" : "NO PRESENCE",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDetected ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
