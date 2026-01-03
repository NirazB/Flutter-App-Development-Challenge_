import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

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

  Future<void> toggleLed(bool value) async {
    try {
      await _dbRef.update({"led_manual": value});
      HapticFeedback.lightImpact(); // Tactile feedback for the user
    } catch (e) {
      debugPrint("Error sending command: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 240, 240),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            // Data extraction
            final rawData = snapshot.data!.snapshot.value;
            final data = Map<String, dynamic>.from(rawData as Map);

            bool isDetected = data['presence'] ?? false;
            bool ledManual = data['led_manual'] ?? false; // Remote state
            double temp = (data['temperature'] ?? 0.0).toDouble();
            int uptime = data['timestamp'] ?? 0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(uptime, temp),
                  const SizedBox(height: 15),

                  _buildLedControl(isDetected, ledManual),

                  const SizedBox(height: 15),
                  _buildPresenceIndicator(isDetected),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(
                Icons.developer_board,
                size: 40,
                color: Colors.white,
              ),
              title: Text(
                "ESP32 Cloud Node",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                "Status: ONLINE",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.white24),
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: Colors.white.withAlpha(25),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLedControl(bool isDetected, bool ledManual) {
    bool isActuallyOn = ledManual || isDetected;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.lightbulb,
              color: isActuallyOn ? Colors.amber : Colors.grey,
              size: 30,
            ),
            title: const Text(
              "Remote LED Override",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              ledManual ? "Manual: ON" : "Manual: OFF (Auto Mode)",
            ),
            trailing: Switch(
              value: ledManual,
              activeColor: Colors.blueAccent,
              onChanged: (bool value) => toggleLed(value),
            ),
          ),
          if (isDetected && !ledManual)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                "Note: Physical IR Sensor is forcing LED ON",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPresenceIndicator(bool isDetected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDetected
            ? Colors.red.withAlpha(25)
            : Colors.green.withAlpha(25),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDetected ? Colors.red : Colors.green,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDetected
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            color: isDetected ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 15),
          Text(
            isDetected ? "PRESENCE DETECTED" : "NO PRESENCE",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDetected ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
