import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/services.dart';

class ServoPage extends StatefulWidget {
  const ServoPage({super.key});

  @override
  State<ServoPage> createState() => _ServoPageState();
}

class _ServoPageState extends State<ServoPage> {
  final String espIp = "http://192.168.43.197";
  double servoAngle = 0.0;

  Future<void> setServoAngle(double angle) async {
    try {
      final int val = angle.toInt();
      final response = await http.get(Uri.parse("$espIp/servo?angle=$val"));
      if (response.statusCode == 200) {
        debugPrint("Servo moved to $val");
      }
    } catch (e) {
      debugPrint("Error setting servo angle: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: (servoAngle * 3.14159 / 180), //degrees to Radians
              child: Icon(Icons.navigation, size: 100, color: Colors.blue),
            ),

            Text(
              "${servoAngle.toInt()}°",
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),

            Slider(
              value: servoAngle,
              min: 0,
              max: 180,
              divisions: 180,
              label: servoAngle.round().toString(),
              onChanged: (value) {
                HapticFeedback.lightImpact();
                setState(() {
                  servoAngle = value;
                });
              },
              onChangeEnd: (value) => setServoAngle(value),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() => servoAngle = 0);
                    setServoAngle(0);
                  },
                  child: Text("Min"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => servoAngle = 90);
                    setServoAngle(90);
                  },
                  child: Text("Center"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => servoAngle = 180);
                    setServoAngle(180);
                  },
                  child: Text("Max"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
