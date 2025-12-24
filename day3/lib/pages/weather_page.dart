import 'package:flutter/material.dart';
import 'package:day2/services/weather_api.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  Map<String, dynamic>? weatherData;

  void loadWeather() async {
    final data = await WeatherApi().fetchWeatherData();
    setState(() {
      weatherData = data;
    });
  }

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  // get icon code     from the weather code fromy
  IconData getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return Icons.wb_sunny; // clear sky day
      case '01n':
        return Icons.nights_stay; // clear sky night
      case '02n':
        return Icons.cloud; // few clouds
      case '03n':
        return Icons.cloud_queue; // scattered clouds
      case '04n':
        return Icons.cloudy_snowing; // broken clouds
      case '09n':
        return Icons.grain; // shower rain
      case '10n':
        return Icons.beach_access; // rain
      case '11n':
        return Icons.flash_on; // thunderstorm
      case '13n':
        return Icons.ac_unit; // snow
      case '50n':
        return Icons.blur_on; // mist
      default:
        return Icons.hourglass_empty; // loading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              weatherData == null
                  ? SizedBox(
                      height: 170,
                      width: 170,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 6.0,
                      ),
                    )
                  : Icon(
                      getWeatherIcon(weatherData?['icon'] ?? ''),
                      color: Colors.yellow,
                      size: 170,
                    ),
              const SizedBox(height: 10),
              Text(
                "${weatherData?['temp'] ?? '--'}°C",
                style: TextStyle(fontSize: 60, color: Colors.white),
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
