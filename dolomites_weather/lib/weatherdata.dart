import 'package:flutter/material.dart';

class WeatherData {
  final String placeName;
  final String country;
  final double lat;
  final double long;
  final String date;
  final double maxTemp;
  final double maxUV;
  final String maxuvTimeLocal;
  final String sunriseLocal;
  final String sunsetLocal;
  final String weatherDescription;
  final String weatherIcon;
  final Map<String, int> burnTimes;
  final double elevation;
  final String informalWeather;
  final Color temperatureColor;
  final Color uvIndexColor;
  final String uvAction;
  final String uvLabel;

  WeatherData({
    required this.placeName,
    required this.country,
    required this.lat,
    required this.long,
    required this.date,
    required this.maxTemp,
    required this.maxUV,
    required this.maxuvTimeLocal,
    required this.sunriseLocal,
    required this.sunsetLocal,
    required this.weatherDescription,
    required this.weatherIcon,
    required this.burnTimes,
    required this.elevation,
    required this.informalWeather,
    required this.temperatureColor,
    required this.uvIndexColor,
    required this.uvAction,
    required this.uvLabel,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final maxTemp = (json['max_temp'] as num).toDouble();
    final maxUV = (json['max_uv'] as num).toDouble();
    return WeatherData(
      placeName: json['place_name'],
      country: json['country'],
      lat: (json['lat'] as num).toDouble(),
      long: (json['long'] as num).toDouble(),
      date: json['date'],
      maxUV: maxUV,
      maxTemp: maxTemp,
      maxuvTimeLocal: json['maxuv_time_local'],
      sunriseLocal: json['sunrise_local'],
      sunsetLocal: json['sunset_local'],
      weatherDescription: json['weather_description'],
      weatherIcon: json['weather_icon'],
      burnTimes: Map<String, int>.from(json['burn_times']),
      elevation: json['elevation'],
      informalWeather: informalWeatherFinder(maxTemp),
      temperatureColor: temperatureColorFinder(maxTemp),
      uvIndexColor: uvIndexColorFinder(maxUV),
      uvAction: uvActionFinder(maxUV),
      uvLabel: uvLabelFinder(maxUV),
    );
  }
}

String uvActionFinder(double uv) {
  if (uv <= 2) return 'No protection needed. Safe to stay outside.';
  if (uv <= 5) {
    return 'Use sunscreen and sun hats. Seek shade during midday peak hours (11 am-3 pm)';
  }
  if (uv <= 7) {
    return 'Apply SPF 50+ sunscreen, wear protective clothing, and seek shade';
  }
  if (uv <= 10) {
    return 'High risk of harm. Avoid sun exposure if possible, apply high SPF, and cover up';
  }
  return 'Avoid being outside during midday. Maximum protection is essential';
}

String uvLabelFinder(double uv) {
  if (uv <= 2) return 'LOW';
  if (uv <= 5) return 'MODERATE';
  if (uv <= 7) return 'HIGH';
  if (uv <= 10) return 'VERY HIGH';
  return 'EXTREME';
}

Color uvIndexColorFinder(double uv) {
  if (uv <= 2) return Color(0xFF4CAF50);
  if (uv <= 5) return Color(0xFFFFEE58);
  if (uv <= 7) return Color(0xFFFF9800);
  if (uv <= 10) return Color(0xFFF44336);
  return Color(0xFF9C27B0);
}

Color temperatureColorFinder(double temp) {
  if (temp <= 2) return Color(0xFF1565C0);
  if (temp <= 5) return Color(0xFF1E88E5);
  if (temp <= 8) return Color(0xFF42A5F5);
  if (temp <= 11) return Color(0xFF80DEEA);
  if (temp <= 14) return Color(0xFF26C6DA);
  if (temp <= 17) return Color(0xFF66BB6A);
  if (temp <= 20) return Color(0xFFD4E157);
  if (temp <= 23) return Color(0xFFFFEE58);
  if (temp <= 26) return Color(0xFFFFA726);
  if (temp <= 28) return Color(0xFFFF7043);
  return Color(0xFFE53935);
}

String informalWeatherFinder(double temp) {
  if (temp <= 2) return 'Freezing! Coat, gloves, hat';
  if (temp <= 5) return 'Thick winter coat zipped up';
  if (temp <= 8) return 'Cold - coat firmly on';
  if (temp <= 11) return 'Chilly - light coat or layers';
  if (temp <= 14) return 'Cool - jacket weather';
  if (temp <= 17) return 'Light jacket/jumper weather';
  if (temp <= 20) return 'T-shirt with backup layer';
  if (temp <= 23) return 'T-shirt weather';
  if (temp <= 26) return 'Shorts and T-shirts';
  if (temp <= 28) return 'Hot - seeking shade';
  return 'Very hot - too warm to function';
}

///String informalWeather(double temp) {
//}

// 0–2 °C — Freezing – big coat, gloves, regret
// 3–5 °C — Winter insulated coat weather
// 6–8 °C — Cold – coat firmly on
// 9–11 °C — Chilly – light coat or layers
// 12–14 °C — Cool – jacket weather
// 15–17 °C — Light jacket / jumper weather
// 18–20 °C — T-shirt with a backup layer
// 21–23 °C — T-shirt weather
// 24–26 °C — Shorts and T-shirt weather
// 27–28 °C — Hot – seeking shade
// 29–30 °C — Very hot – too warm to function properly


//JSON return this....
//   {
//   "burn_times": {
//     "1": 15,
//     "2": 31,
//     "3": 46,
//     "4": 62,
//     "5": 77,
//     "6": 93
//   },
//   "country": "Sam's new home",
//   "date": "2026-05-02",
//   "elevation": 312.3,
//   "lat": 123,
//   "long": 456,
//   "max_temp": 21.2,
//   "max_uv": 4.32,
//   "maxuv_time_local": "13:46",
//   "place_name": "Cobble Hill",
//   "sunrise_local": "06:45",
//   "sunset_local": "21:05",
//   "weather_description": "sunny",
//   "weather_icon": "10d"
// }