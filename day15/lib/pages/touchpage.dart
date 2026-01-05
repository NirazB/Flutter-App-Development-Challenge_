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
  Timer? _throttleTimer;
  double _accumulatedDx = 0;
  double _accumulatedDy = 0;

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  @override
  void dispose() {
    reconnectTimer?.cancel();
    _throttleTimer?.cancel();
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

  void _onPanStart(DragStartDetails details) {
    _accumulatedDx = 0;
    _accumulatedDy = 0;
    _throttleTimer?.cancel();
    _throttleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _sendMoveCommand();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _accumulatedDx += details.delta.dx;
    _accumulatedDy += details.delta.dy;
  }

  void _onPanEnd(DragEndDetails details) => _stopSending();

  void _onPanCancel() => _stopSending();

  void _stopSending() {
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _sendMoveCommand();
  }

  void _sendMoveCommand() {
    if (channel == null || !isConnected) return;

    if (_accumulatedDx == 0 && _accumulatedDy == 0) return;

    try {
      final data = jsonEncode({
        'action': 'move',
        'dx': _accumulatedDx,
        'dy': _accumulatedDy,
      });
      channel!.sink.add(data);
      _accumulatedDx = 0;
      _accumulatedDy = 0;
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
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onPanCancel: _onPanCancel,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 54, 54, 54),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Center(
                  child: Text(
                    "Touch Area",
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 24,
                    ),
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
