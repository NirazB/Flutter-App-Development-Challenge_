import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Dht11Temp extends StatefulWidget {
  const Dht11Temp({super.key});

  @override
  State<Dht11Temp> createState() => _Dht11TempState();
}

class _Dht11TempState extends State<Dht11Temp> {
  double temperature = 0.0;
  double humidity = 0.0;
  final String espIp = "http://192.168.43.197";

  Future<void> fetchDHTdata() async {
    try {
      final response = await http.get(Uri.parse("$espIp/dht"));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          temperature = double.parse(
            (data['temperature'] as num).toStringAsFixed(2),
          );
          humidity = double.parse((data['humidity'] as num).toStringAsFixed(2));
        });
      }
    } catch (e) {
      debugPrint("Error fetching DHT data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SensorDashboard(
                temperature: temperature,
                humidity: humidity,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchDHTdata,
              child: Text('Fetch DHT11 Data'),
            ),
          ],
        ),
      ),
    );
  }
}

class SensorDashboard extends StatelessWidget {
  final double temperature;
  final double humidity;

  const SensorDashboard({
    super.key,
    required this.temperature,
    required this.humidity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Temperature Gauge
        Expanded(
          child: SfRadialGauge(
            title: GaugeTitle(
              text: 'Temperature (°C)',
              textStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: 50,
                ranges: <GaugeRange>[
                  GaugeRange(startValue: 0, endValue: 20, color: Colors.blue),
                  GaugeRange(startValue: 20, endValue: 30, color: Colors.green),
                  GaugeRange(startValue: 30, endValue: 50, color: Colors.red),
                ],
                pointers: <GaugePointer>[
                  NeedlePointer(value: temperature, enableAnimation: true),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    widget: Text(
                      '$temperature°C',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    angle: 90,
                    positionFactor: 0.85,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Humidity Gauge
        Expanded(
          child: SfRadialGauge(
            title: GaugeTitle(
              text: 'Humidity (%)',
              textStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: 100,
                pointers: <GaugePointer>[
                  RangePointer(
                    value: humidity,
                    width: 0.2,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: Colors.blueAccent,
                  ),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    widget: Text(
                      '$humidity%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    angle: 90,
                    positionFactor: 0.85,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
