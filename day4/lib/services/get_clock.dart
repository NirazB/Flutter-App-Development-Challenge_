import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class GetClock {
  Future<Map<String, dynamic>> fetchTime({
    String zone = 'Asia/Kathmandu',
  }) async {
    final uri = Uri.https('timeapi.io', '/api/time/current/zone', {
      'timeZone': zone,
    });
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Use ?? to provide a fallback if 'time' is missing
        return data;
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timed out.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
