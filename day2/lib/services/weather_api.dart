import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; //for date formatting
import 'package:day2/env/env.dart';

class WeatherApi {
  // final String apiKey = String.fromEnvironment('API_KEY');
  final String apiKey = Env.apiKey; //API key from openweathermap

  //Future returns Map(strings and dynamic values(int, string, etc) after some time)
  Future<Map<String, dynamic>> fetchWeatherData() async {
    final uri = Uri.https('api.openweathermap.org', '/data/2.5/forecast', {
      'lat': '26.794386',
      'lon': '87.281731',
      'appid': apiKey,
      'units': 'metric',
    }); //dharan's latitude and longitude

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load weather data: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final listData = (data['list'] as List).first as Map<String, dynamic>;
    final dateTime = DateTime.parse(
      listData['dt_txt'],
    ); //i get time ,"dt_txt":"2025-XX-XX 09:00:00"

    return {
      'temp': listData['main']['temp'],
      'description': listData['weather'][0]['description'],
      'windSpeed': listData['wind']['speed'],
      'pressure': listData['main']['pressure'],
      'humidity': listData['main']['humidity'],
      'icon': listData['weather'][0]['icon'],
      'time': DateFormat('EEEE, d MMMM').format(
        dateTime,
      ), //time formatting by  intl : Day(Tuesday), Date(23) Month(June)"
    };
  }
}

//for testing if API is working
// Future<void> main() async {
//   try {
//     final data = await WeatherApi().fetchWeatherData();
//     print(jsonEncode(data)); //JSON
//   } catch (e) {
//     print('Error: $e');
//   }
// }
