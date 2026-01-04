import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:convert';

class TouchPage extends StatefulWidget {
  final String ipAddress;
  const TouchPage({super.key, required this.ipAddress});

  @override
  State<TouchPage> createState() => _TouchPageState();
}

class _TouchPageState extends State<TouchPage> {
  WebSocketChannel? channel;
  String connectionStatus = "Connecting...";
  bool isConnected = false;
  Timer? reconnectTimer;

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  @override
  void dispose() {
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
        (data) {},
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

  void _onPanUpdate(DragUpdateDetails details) {
    if (channel == null || !isConnected) return;

    try {
      final data = jsonEncode({
        'action': 'move',
        'dx': details.delta.dx,
        'dy': details.delta.dy,
      });
      channel!.sink.add(data);
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              connectionStatus,
              style: TextStyle(
                color: connectionStatus == "Connected"
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Center(
                  child: Text(
                    "Touch Area",
                    style: TextStyle(color: Colors.grey, fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40, top: 20),
            child: Row(
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
          ),
        ],
      ),
    );
  }
}
