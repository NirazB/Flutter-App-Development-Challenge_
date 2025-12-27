import 'package:flutter/material.dart';
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
  String status = 'OFFLINE';
  int uptime = 0;
  String deviceName = '';
  Future<void> fetchEspData() async {
    final String espIp = "http://192.168.43.197";

    try {
      final response = await http.get(Uri.parse(espIp));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          status = data['status'];
          uptime = data['uptime_seconds'];
          deviceName = data['device_name'];
        });
      } else {
        setState(() {
          status = 'Failed to load data from ESP';
        });
      }
    } catch (e) {
      setState(() {
        status = 'Error: $e';
      });
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
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => fetchEspData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 280,
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
                leading: Icon(Icons.developer_board, color: Colors.blue),
                title: Text(deviceName),
                subtitle: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ), // Base style
                    children: [
                      TextSpan(text: "Status: "),
                      TextSpan(
                        text: status.toUpperCase(),
                        style: TextStyle(
                          color: status == "ONLINE" ? Colors.green : Colors.red,
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
                  _buildStatCard("Signal", "Strong", Icons.wifi),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
