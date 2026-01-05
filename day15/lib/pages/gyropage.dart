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
  bool isGyroActive = false;

  // Sensor data
  double gx = 0.0, gy = 0.0, gz = 0.0;

  // Throttling
  int _lastSendTime = 0;
  final int _sendIntervalMs = 20; // Send data every ~20ms (50fps)

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  @override
  void dispose() {
    // Set gyro inactive first
    isGyroActive = false;

    _sendStopMessageSync();

    _gyroSubscription?.cancel();
    reconnectTimer?.cancel();

    Future.delayed(const Duration(milliseconds: 150), () {
      channel?.sink.close();
    });
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
    if (channel == null || !isConnected || !isGyroActive) return;

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

  void _toggleGyroInput() {
    setState(() {
      isGyroActive = !isGyroActive;
    });

    if (isGyroActive) {
      _startGyroListening();
    } else {
      _gyroSubscription?.cancel();
      _gyroSubscription = null;
      _sendStopMessage();
    }
  }

  void _sendStopMessage() {
    if (channel == null || !isConnected) return;

    try {
      final data = jsonEncode({'action': 'stop'});
      channel!.sink.add(data);
    } catch (e) {
      debugPrint('Error sending stop message: $e');
    }
  }

  void _sendStopMessageSync() {
    // Send stop message without connectivity checks (for dispose)
    if (channel == null) return;

    try {
      final data = jsonEncode({'action': 'stop'});
      channel!.sink.add(data);
      print('Stop message sent on dispose');
    } catch (e) {
      debugPrint('Error sending stop message on dispose: $e');
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
            ElevatedButton.icon(
              onPressed: _toggleGyroInput,
              icon: Icon(isGyroActive ? Icons.pause : Icons.play_arrow),
              label: Text(
                isGyroActive ? 'Stop Gyro Input' : 'Start Gyro Input',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isGyroActive ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
            const SizedBox(height: 20),
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
