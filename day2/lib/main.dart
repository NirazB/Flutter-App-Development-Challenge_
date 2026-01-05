import 'package:flutter/material.dart';
import 'services/weather_api.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WeatherDetail();
  }
}

class WeatherDetail extends StatefulWidget {
  const WeatherDetail({super.key});

  @override
  State<WeatherDetail> createState() => _WeatherDetailState();
}

class _WeatherDetailState extends State<WeatherDetail> {
  Map<String, dynamic>? weatherData; //? for nullable value
  void loadWeather() async {
    final data = await WeatherApi().fetchWeatherData();
    setState(() {
      weatherData = data;
      // print("Weather Data Loaded: $weatherData");
    });
  }

  //one-time startup hook
  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Flutter Day 2 App",
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Weather App"),
          backgroundColor: const Color.fromARGB(255, 90, 214, 239),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue, Colors.lightBlueAccent],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 20),
                Text(
                  "DHARAN",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${weatherData?['time'] ?? 'Loading...'}", //display time or loading
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 30),
                Text(
                  "${weatherData?['temp'] ?? '--'}°C",
                  style: TextStyle(fontSize: 90, color: Colors.white),
                ),
                Text(
                  "${weatherData?['description'] ?? '--'}",
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    weatherInfoCard(
                      Icons.water_drop,
                      "${weatherData?['humidity'] ?? '--'}%",
                      "Humidity",
                    ),
                    weatherInfoCard(
                      Icons.air,
                      "${weatherData?['windSpeed'] ?? '--'} m/s",
                      "Wind Speed",
                    ),
                    weatherInfoCard(
                      Icons.compress,
                      "${weatherData?['pressure'] ?? '--'} hPa",
                      "Pressure",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget weatherInfoCard(IconData icon, String value, String label) {
  return Container(
    margin: const EdgeInsets.all(10.0),
    padding: const EdgeInsets.all(10.0),
    child: Column(
      children: [
        Icon(icon, color: Colors.white),
        Text(
          value,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    ),
  );
}
