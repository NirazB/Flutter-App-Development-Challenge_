import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:http/http.dart" as http;
import "dart:async";
import 'dart:convert';

class EspPage extends StatefulWidget {
  const EspPage({super.key});

  @override
  State<EspPage> createState() => _EspPageState();
}

class _EspPageState extends State<EspPage> {
  Timer? timer;
  bool isLedOn = false;
  String status = 'OFFLINE';
  int uptime = 0;
  String deviceName = '';
  double temperature = 0.0;
  double humidity = 0.0;
  final String espIp = "http://192.168.43.197";

  Future<void> fetchEspData() async {
    final response = await http.get(Uri.parse(espIp));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      setState(() {
        status = data['status'];
        uptime = data['uptime_seconds'];
        deviceName = data['device_name'];
      });
    }
  }

  Future<void> toggleLed(bool value) async {
    String path = value ? "/on" : "/off";
    try {
      final response = await http.get(Uri.parse(espIp + path));
      if (response.statusCode == 200) {
        setState(() {
          isLedOn = value;
        });
      }
    } catch (e) {
      // Handle error if needed
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.blueAccent),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  bool isDetected = false;
  String doorStatus = "CLOSED";
  Future<void> fetchIRStatus() async {
    final response = await http.get(Uri.parse('$espIp/ir'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        isDetected = data['presence'] ?? false;
        isLedOn = data['led'] ?? false;
        doorStatus = isDetected ? "OPEN" : "CLOSED";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      fetchEspData();
      fetchIRStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              height: 250,
              margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlue],
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      size: 40,
                      Icons.developer_board,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                    title: Text(
                      status == "ONLINE" ? deviceName : "Unavailable",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    subtitle: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ), // Base style
                        children: [
                          TextSpan(
                            text: "Status: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: status.toUpperCase(),
                            style: TextStyle(
                              color: status == "ONLINE"
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard("Uptime", "$uptime s", Icons.timer),
                      _buildStatCard(
                        "Signal",
                        status == "ONLINE" ? "Strong" : "None",
                        Icons.wifi,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Card(
            margin: EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: isLedOn
                      ? [Colors.white, const Color.fromARGB(255, 255, 247, 0)]
                      : [Colors.white, Colors.blue.shade50],
                ),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.lightbulb,
                  color: isLedOn ? Colors.yellow : Colors.grey,
                ),
                title: Text("LED Control"),
                trailing: Switch(
                  value: isLedOn,
                  onChanged: (bool value) {
                    HapticFeedback.mediumImpact();
                    toggleLed(value);
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(20),
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
                SizedBox(width: 10),
                Text(
                  isDetected ? "PRESENCE DETECTED" : "NO PRESENCE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDetected ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              leading: Icon(
                isDetected ? Icons.meeting_room : Icons.door_front_door,
                color: isDetected ? Colors.red : Colors.green,
              ),
              title: Text("Door Status"),
              subtitle: Text(
                doorStatus,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDetected ? Colors.red : Colors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
