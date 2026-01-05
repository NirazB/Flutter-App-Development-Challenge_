import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'dart:convert';

class FileTransferScreen extends StatefulWidget {
  final String ipAddress;
  const FileTransferScreen({super.key, required this.ipAddress});

  @override
  State<FileTransferScreen> createState() => _FileTransferScreenState();
}

class _FileTransferScreenState extends State<FileTransferScreen> {
  // final TextEditingController _ipController = TextEditingController();

  List<String> _serverFiles = [];
  bool _isConnected = false;
  bool _isLoading = false;
  socket_io.Socket? _socket;
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _socket?.dispose();
    // _ipController.dispose();
    super.dispose();
  }

  Future<void> _connectToServer() async {
    final ip = widget.ipAddress;
    if (ip.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter Server IP')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = 'http://${widget.ipAddress}:5000';
      // Test connection with a simple GET
      final response = await http.get(Uri.parse('$url/files'));
      if (response.statusCode == 200) {
        _serverUrl = url;
        setState(() {
          _isConnected = true;
          _isLoading = false;
        });

        _updateFileList(json.decode(response.body));
        _initSocket(url);

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Connected to Server!')));
      } else {
        throw Exception('Failed to connect');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
    }
  }

  void _initSocket(String url) {
    _socket = socket_io.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      debugPrint('Socket Connected');
    });

    _socket!.on('file_added', (data) {
      if (data is Map && data.containsKey('filename')) {
        _fetchFiles(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New file available: ${data['filename']}')),
        );
      }
    });
  }

  Future<void> _fetchFiles() async {
    if (_serverUrl == null) return;
    try {
      final response = await http.get(Uri.parse('$_serverUrl/files'));
      if (response.statusCode == 200) {
        _updateFileList(json.decode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching files: $e');
    }
  }

  void _updateFileList(List<dynamic> files) {
    setState(() {
      _serverFiles = files.cast<String>();
    });
  }

  Future<void> _pickAndUploadFile() async {
    if (_serverUrl == null) return;

    // Check storage permissions first
    // Note: On Android 13+, use photos/audio/video permissions or manage external storage
    // For simplicity, we try requesting minimal needed or rely on file_picker caching

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      _uploadFile(file);
    }
  }

  Future<void> _uploadFile(File file) async {
    setState(() => _isLoading = true);
    try {
      String filename = file.path.split('/').last;
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl/upload'),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: filename,
        ),
      );

      var res = await request.send();
      if (res.statusCode == 201 || res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload Successful')));
        _fetchFiles();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload Failed')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadFile(String filename) async {
    if (_serverUrl == null) return;

    // Request permission to save
    if (!await _requestPermission(Permission.storage)) {
      // On Android 13+, this might always be false for 'storage' but true for others
      // Just proceed and catch error if it fails
    }

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      String savePath = '${dir.path}/$filename';

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Downloading $filename...')));

      final dio = Dio();
      await dio.download(
        '$_serverUrl/download/$filename',
        savePath,
        onReceiveProgress: (received, total) {
          // Optional: Show progress
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved to $savePath')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) return true;
    final result = await permission.request();
    return result == PermissionStatus.granted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isConnected) ...[
              const SizedBox(height: 40),
              const Icon(Icons.wifi_tethering, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              TextField(
                // controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'Enter Laptop IP Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.computer),
                  hintText: 'e.g., 192.168.1.10',
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: widget.ipAddress),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _connectToServer,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Connect'),
              ),
            ] else ...[
              // Connected View
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Connected to Server')),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _fetchFiles,
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () {
                        setState(() => _isConnected = false);
                        _socket?.disconnect();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _serverFiles.isEmpty
                    ? const Center(child: Text('No files shared yet'))
                    : ListView.separated(
                        itemCount: _serverFiles.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final file = _serverFiles[index];
                          return ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(file),
                            trailing: IconButton(
                              icon: const Icon(Icons.download),
                              color: Theme.of(context).colorScheme.secondary,
                              onPressed: () => _downloadFile(file),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: _isConnected
          ? FloatingActionButton.extended(
              onPressed: _pickAndUploadFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
            )
          : null,
    );
  }
}
