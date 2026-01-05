import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class LaptopControlPage extends StatefulWidget {
  final String ipAddress;
  const LaptopControlPage({super.key, required this.ipAddress});

  @override
  State<LaptopControlPage> createState() => _LaptopControlPageState();
}

class _LaptopControlPageState extends State<LaptopControlPage> {
  double _brightness = 50;
  double _volume = 50;
  bool _isDarkMode = false;
  bool _isWifiOn = true;
  bool _isBluetoothOn = true;
  bool _isAirplaneModeOn = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final socket = await Socket.connect(widget.ipAddress, 2000);
      socket.write(jsonEncode({"action": "get_status"}));

      socket.listen((List<int> data) {
        final response = String.fromCharCodes(data);
        try {
          final json = jsonDecode(response);
          if (mounted) {
            setState(() {
              _volume = (json['volume'] as num).toDouble().clamp(0.0, 100.0);
              _brightness = (json['brightness'] as num).toDouble().clamp(
                0.0,
                100.0,
              );
              _isDarkMode = json['isDarkMode'] ?? false;
              _isWifiOn = json['isWifiOn'] ?? true;
              _isBluetoothOn = json['isBluetoothOn'] ?? true;
              _isAirplaneModeOn = json['isAirplaneModeOn'] ?? false;
            });
          }
        } catch (e) {
          debugPrint("Error parsing status: $e");
        }
        socket.destroy();
      });
    } catch (e) {
      debugPrint("Error fetching status: $e");
    }
  }

  Future<void> sendCommand(String action, dynamic value) async {
    try {
      final socket = await Socket.connect(widget.ipAddress, 2000);
      socket.write(jsonEncode({"action": action, "value": value}));
      await socket.flush();
      await socket.close();
    } catch (e) {
      debugPrint("Error sending command: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text("Brightness: ${_brightness.round()}%"),
          Slider(
            value: _brightness,
            max: 100,
            onChanged: (val) => setState(() => _brightness = val),
            onChangeEnd: (val) =>
                sendCommand('brightness', val.round()), // Only sends once!
          ),
          const Divider(),
          Text("Volume: ${_volume.round()}%"),
          Slider(
            value: _volume,
            max: 100,
            onChanged: (val) => setState(() => _volume = val),
            onChangeEnd: (val) =>
                sendCommand('volume', val.round()), // Much more stable
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Dark Mode"),
            secondary: const Icon(Icons.dark_mode),
            value: _isDarkMode,
            onChanged: (val) {
              setState(() => _isDarkMode = val);
              sendCommand('darkmode', val ? 'dark' : 'light');
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Wi-Fi"),
            secondary: const Icon(Icons.wifi),
            value: _isWifiOn,
            onChanged: (val) {
              setState(() => _isWifiOn = val);
              sendCommand('wifi', val);
            },
          ),
          SwitchListTile(
            title: const Text("Bluetooth"),
            secondary: const Icon(Icons.bluetooth),
            value: _isBluetoothOn,
            onChanged: (val) {
              setState(() => _isBluetoothOn = val);
              sendCommand('bluetooth', val);
            },
          ),
          SwitchListTile(
            title: const Text("Airplane Mode"),
            secondary: const Icon(Icons.airplanemode_active),
            value: _isAirplaneModeOn,
            onChanged: (val) {
              setState(() => _isAirplaneModeOn = val);
              sendCommand('airplane_mode', val);
              // Optimistically update others
              if (val) {
                setState(() {
                  _isWifiOn = false;
                  _isBluetoothOn = false;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
