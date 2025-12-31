import "package:flutter/material.dart";
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class IrSensor extends StatefulWidget {
  const IrSensor({super.key});

  @override
  State<IrSensor> createState() => IrSensorState();
}

class IrSensorState extends State<IrSensor> {
  final String espIp = "http://192.168.43.197"; // Replace with your ESP32 IP
  bool isDetected = false;

  Timer? timer;

  Future<bool> fetchIRStatus() async {
    try {
      final response = await http.get(Uri.parse('$espIp/ir'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['presence'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(milliseconds: 500), (Timer t) async {
      bool status = await fetchIRStatus();
      setState(() {
        isDetected = status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
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
      ),
    );
  }
}
