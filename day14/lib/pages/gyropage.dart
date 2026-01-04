import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Gyropage extends StatefulWidget {
  final String ipAddress;
  const Gyropage({super.key, required this.ipAddress});

  @override
  State<Gyropage> createState() => _GyropageState();
}

class _GyropageState extends State<Gyropage> {
  WebSocketChannel? channel;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  Timer? reconnectTimer;

  String connectionStatus = "Connecting...";
  bool isConnected = false;

  // Sensor data
  double gx = 0.0, gy = 0.0, gz = 0.0;

  // Throttling
  int _lastSendTime = 0;
  final int _sendIntervalMs = 20; // Send data every ~20ms (50fps)

  @override
  void initState() {
    super.initState();
    _connectToServer();
    _startGyroListening();
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    reconnectTimer?.cancel();
    channel?.sink.close();
    super.dispose();
  }

  void _connectToServer() {
    if (isConnected) return;

    setState(() {
      connectionStatus = "Connecting...";
    });

    try {
      channel = WebSocketChannel.connect(
        Uri.parse('ws://${widget.ipAddress}:8765'),
      );

      channel!.stream.listen(
        (data) {
          // Handle incoming data if needed
        },
        onError: (error) => _handleDisconnect(),
        onDone: () => _handleDisconnect(),
      );

      // Assume connected until proven otherwise by an error
      setState(() {
        connectionStatus = "Connected";
        isConnected = true;
      });
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (!mounted) return;

    setState(() {
      connectionStatus = "Disconnected";
      isConnected = false;
    });
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    reconnectTimer?.cancel();
    reconnectTimer = Timer(const Duration(seconds: 3), _connectToServer);
  }

  void _startGyroListening() {
    _gyroSubscription = gyroscopeEventStream().listen((event) {
      if (!mounted) return;

      setState(() {
        gx = event.x;
        gy = event.y;
        gz = event.z;
      });

      _sendGyroData();
    });
  }

  void _sendGyroData() {
    if (channel == null || !isConnected) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSendTime < _sendIntervalMs) return;

    try {
      final data = jsonEncode({'gx': gx, 'gy': gy, 'gz': gz});
      channel!.sink.add(data);
      _lastSendTime = now;
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _sendClick(String button) {
    if (channel == null || !isConnected) return;

    try {
      final data = jsonEncode({'action': 'click', 'button': button});
      channel!.sink.add(data);
    } catch (e) {
      _handleDisconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Gyroscope",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              connectionStatus,
              style: TextStyle(
                fontSize: 14,
                color:
                    connectionStatus.contains("Error") ||
                        connectionStatus == "Disconnected"
                    ? Colors.red
                    : connectionStatus == "Connected"
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "X: ${gx.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Y: ${gy.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Z: ${gz.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _sendClick('left'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                  ),
                  child: const Text(
                    'Left Click',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _sendClick('right'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                  ),
                  child: const Text(
                    'Right Click',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
