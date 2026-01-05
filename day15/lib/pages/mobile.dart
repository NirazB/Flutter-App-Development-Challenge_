import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:image/image.dart' as img;

class MobilePage extends StatefulWidget {
  final String ipAddress;
  const MobilePage({super.key, required this.ipAddress});

  @override
  State<MobilePage> createState() => _MobilePageState();
}

class _MobilePageState extends State<MobilePage> {
  CameraController? _controller;
  IO.Socket? _socket;
  bool _isStreaming = false;
  String _status = 'Disconnected';
  bool _isProcessingFrame = false;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _connectSocket();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras[0],
      ResolutionPreset
          .medium, // Change to 'low' for faster speed, 'high' for best quality
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFocusMode(FocusMode.locked);
      await _controller!.setExposureMode(ExposureMode.auto);

      // Disable zoom - set to minimum zoom level
      final minZoom = await _controller!.getMinZoomLevel();
      await _controller!.setZoomLevel(minZoom);

      if (mounted) setState(() {});
    } catch (e) {
      print("Camera Init Error: $e");
    }
  }

  void _connectSocket() {
    _socket = IO.io(
      'http://${widget.ipAddress}:5000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    // _socket!.io.options?['secure'] = true;
    // _socket!.io.options?['rejectUnauthorized'] = false;

    _socket!.onConnect((_) => setState(() => _status = 'Connected'));
    _socket!.onDisconnect((_) => setState(() => _status = 'Disconnected'));

    _socket!.connect();
  }

  void _toggleStream() {
    if (_socket == null || !_socket!.connected) return;
    setState(() => _isStreaming = !_isStreaming);
    if (_isStreaming) {
      _startImageStream();
    } else {
      try {
        _controller?.stopImageStream();
      } catch (_) {}
    }
  }

  Future<void> _startImageStream() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    await _controller!.startImageStream((CameraImage image) {
      if (!_isStreaming || _isProcessingFrame || !_socket!.connected) return;

      // Throttle to 15 FPS by skipping frames
      _frameCount++;
      if (_frameCount % 2 != 0) return; // Send every 2nd frame

      _isProcessingFrame = true;
      _convertAndSendImage(image);
    });
  }

  void _convertAndSendImage(CameraImage image) {
    try {
      final bytes = _convertYUV420ToJPEG(image);

      _socket!.emit(
        'video_frame',
        "data:image/jpeg;base64,${base64Encode(bytes)}",
      );
    } catch (e) {
      print("Conversion error: $e");
    } finally {
      _isProcessingFrame = false;
    }
  }

  Uint8List _convertYUV420ToJPEG(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    // Get Y, U, V planes
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    // Create image object
    final imgLib = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yPlane.bytesPerRow + x;
        final int uvIndex =
            (y ~/ 2) * uPlane.bytesPerRow +
            (x ~/ 2) * (uPlane.bytesPerPixel ?? 1);

        if (yIndex >= yPlane.bytes.length || uvIndex >= uPlane.bytes.length) {
          continue;
        }

        final int yValue = yPlane.bytes[yIndex];
        final int uValue = uPlane.bytes[uvIndex];
        final int vValue = vPlane.bytes[uvIndex];

        // YUV to RGB conversion
        final int r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final int g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .clamp(0, 255)
                .toInt();
        final int b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        imgLib.setPixelRgb(x, y, r, g, b);
      }
    }

    // Rotate image 90 degrees clockwise to fix orientation
    final rotated = img.copyRotate(imgLib, angle: 90);

    // Encode to JPEG - adjust quality: 40 (fast/low), 75 (balanced), 90 (slow/high)
    return Uint8List.fromList(img.encodeJpg(rotated, quality: 75));
  }

  @override
  void dispose() {
    _isStreaming = false;
    _controller?.dispose();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStatusHeader(),
          const SizedBox(height: 20),
          Expanded(child: _buildCameraPreview()),
          const SizedBox(height: 20),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Target: ${widget.ipAddress}",
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            _status,
            style: TextStyle(
              color: _status == 'Connected'
                  ? Colors.greenAccent
                  : Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator()),
          if (_isStreaming)
            Positioned(
              top: 15,
              left: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  "LIVE",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _toggleStream,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isStreaming ? Colors.redAccent : Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
        label: Text(_isStreaming ? "STOP STREAM" : "START STREAM"),
      ),
    );
  }
}
