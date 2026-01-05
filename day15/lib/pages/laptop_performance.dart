import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LaptopPerformancePage extends StatefulWidget {
  final String ipAddress;

  const LaptopPerformancePage({super.key, required this.ipAddress});

  @override
  State<LaptopPerformancePage> createState() => _LaptopPerformancePageState();
}

class _LaptopPerformancePageState extends State<LaptopPerformancePage> {
  late WebSocketChannel channel;
  late Stream<dynamic> stream;

  @override
  void initState() {
    super.initState();
    connect();
  }

  void connect() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('ws://${widget.ipAddress}:8766'),
      );
      stream = channel.stream.asBroadcastStream();
    } catch (e) {
      debugPrint("Error connecting: $e");
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  Text(
                    'Connection Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        connect();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue, strokeWidth: 3),
                  const SizedBox(height: 24),
                  Text(
                    "Connecting...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Make sure performance_monitor.py is running",
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            );
          }

          final data = jsonDecode(snapshot.data);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "System Status",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildCpuCard(data),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildMemoryCard(data)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildBatteryCard(data)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTempCard(data)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildFanCard(data)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildNetworkCard(data),
                const SizedBox(height: 16),
                _buildDiskCard(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCpuCard(Map<String, dynamic> data) {
    final cpuUsage = data['cpu_usage'] as num? ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withAlpha(77), width: 1),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.computer,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "CPU Usage",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                "${cpuUsage.toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: cpuUsage / 100,
              backgroundColor: Colors.blue.withAlpha(26),
              valueColor: AlwaysStoppedAnimation<Color>(
                cpuUsage > 80 ? Colors.red : Colors.blue,
              ),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(Map<String, dynamic> data) {
    final memPercent = data['memory_percent'] as num? ?? 0;
    final memTotal = (data['memory_total'] as num? ?? 0) / (1024 * 1024 * 1024);
    final memAvailable =
        (data['memory_available'] as num? ?? 0) / (1024 * 1024 * 1024);
    final memUsed = memTotal - memAvailable;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withAlpha(77), width: 1),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.memory, color: Colors.purple, size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                "Memory",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: memPercent / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.purple.withAlpha(26),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.purple,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "${memPercent.toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "${memUsed.toStringAsFixed(1)} / ${memTotal.toStringAsFixed(1)} GB",
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryCard(Map<String, dynamic> data) {
    final batteryPercent = data['battery_percent'] as num?;
    final isPlugged = data['battery_plugged'] as bool? ?? false;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withAlpha(77), width: 1),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.battery_charging_full,
                  color: Colors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Battery",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: (batteryPercent ?? 0) / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.green.withAlpha(26),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
                  ),
                ),
                if (isPlugged)
                  const Icon(Icons.bolt, color: Colors.orange, size: 40)
                else
                  Text(
                    batteryPercent != null
                        ? "${batteryPercent.toStringAsFixed(0)}%"
                        : "N/A",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              isPlugged ? "Charging" : "On Battery",
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempCard(Map<String, dynamic> data) {
    final temp = data['cpu_temp'] as num?;
    final displayTemp = temp != null ? temp.toStringAsFixed(1) : "0.0";
    final tempColor = temp != null && temp > 70 ? Colors.red : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tempColor.withAlpha(77), width: 1),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tempColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.thermostat, color: tempColor, size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                "Temp",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  temp != null ? "$displayTemp°C" : "N/A",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: tempColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "CPU Temperature",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFanCard(Map<String, dynamic> data) {
    final fanSpeed = data['fan_speed'] as num?;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyan.withAlpha(77), width: 1),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyan.withAlpha(51),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.wind_power,
                  color: Colors.cyan,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Fan",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  fanSpeed != null ? "${fanSpeed.toInt()}" : "N/A",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Fan Speed",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkCard(Map<String, dynamic> data) {
    final sent = (data['net_sent'] as num? ?? 0) / (1024 * 1024 * 1024);
    final recv = (data['net_recv'] as num? ?? 0) / (1024 * 1024 * 1024);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.withAlpha(77), width: 1),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.indigo.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.network_check,
              color: Colors.indigo,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Network",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: Colors.green[400],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${sent.toStringAsFixed(2)} GB",
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                    const SizedBox(width: 20),
                    Icon(
                      Icons.arrow_downward,
                      color: Colors.blue[400],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${recv.toStringAsFixed(2)} GB",
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiskCard(Map<String, dynamic> data) {
    final diskPercent = data['disk_percent'] as num? ?? 0;
    final diskTotal = (data['disk_total'] as num? ?? 0) / (1024 * 1024 * 1024);
    final diskUsed = (data['disk_used'] as num? ?? 0) / (1024 * 1024 * 1024);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withAlpha(77), width: 1),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storage,
                      color: Colors.amber,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Disk (C:)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                "${diskPercent.toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: diskPercent / 100,
              backgroundColor: Colors.amber.withAlpha(26),
              valueColor: AlwaysStoppedAnimation<Color>(
                diskPercent > 90 ? Colors.red : Colors.amber,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${diskUsed.toStringAsFixed(1)} / ${diskTotal.toStringAsFixed(1)} GB",
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
