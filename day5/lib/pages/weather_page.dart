import 'package:flutter/material.dart';
import 'package:day3/pages/weather_page.dart';

class GetWeather extends StatefulWidget {
  const GetWeather({super.key});

  @override
  State<GetWeather> createState() => _GetWeatherState();
}

class _GetWeatherState extends State<GetWeather> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: WeatherPage()));
  }
}
