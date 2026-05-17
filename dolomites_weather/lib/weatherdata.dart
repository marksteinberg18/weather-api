import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';

//JSON return this....
// {
//  1 "burn_times": {
//     "1": 34,
//     "2": 68,
//     "3": 103,
//     "4": 137,
//     "5": 171,
//     "6": 205
//   },
//   2"cloudiness": 88,
//   3"country": "IT",
//   4"date": 1778716800,
//   5"elevation": 1220,
//   6"hourly_uv": [0, 0, 0, 0, 0, 0, 0, 0.1, 0.4, 1.2, 1.95, 1.05, 0.85, 0.8, 1.35, 1.55, 0.9, 0.5, 0.4, 0.3, 0.1, 0, 0, 0],
//   7"lat": 46.5405,
//   8"long": 12.1357,
//   9"max_temp": 6.9,
//   10"max_uv": 1.95,
//   11"maxuv_time_local": "10:00",
//   12"place_name": "Cortina d'Ampezzo",
//   13"precipitation": 100,
//   14"sunrise_local": "05:38",
//   15"sunset_local": "20:36",
//   16"weather_icon": 80
// }

class WeatherData {
  //✔ = coming from API  @ = internally assigned
  final String placeName; //✔
  final String country; //✔
  final double lat; //✔
  final double long; //✔
  final String day; //@  based on UNIX timecode
  final String datemonth; //@ based on UNIX timecode
  final double maxTemp; //✔
  final double maxUV; //✔
  final String maxuvTimeLocal; //✔
  final String sunriseLocal; //✔
  final String sunsetLocal; //✔
  final IconData weatherIcon; //✔
  final Map<String, int> burnTimes; //✔
  final double elevation; //✔
  final String informalWeather; //@
  final Color temperatureColor; //@
  final Color uvIndexColor; //@
  final String uvAction; //@
  final String uvLabel; //@
  final int cloudiness; //✔
  final int precipitation; //✔
  final List<double> hourlyUV; //✔

  WeatherData({
    required this.placeName,
    required this.country,
    required this.lat,
    required this.long,
    required this.day,
    required this.datemonth,
    required this.maxTemp,
    required this.maxUV,
    required this.maxuvTimeLocal,
    required this.sunriseLocal,
    required this.sunsetLocal,
    required this.weatherIcon,
    required this.burnTimes,
    required this.elevation,
    required this.informalWeather,
    required this.temperatureColor,
    required this.uvIndexColor,
    required this.uvAction,
    required this.uvLabel,
    required this.cloudiness,
    required this.precipitation,
    required this.hourlyUV,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final maxTemp = (json['max_temp'] as num).toDouble();
    final int cloudiness = (json['cloudiness'] as num).toInt();
    final int precipitation = (json['precipitation'] as num).toInt();
    final double maximumUV = (json['max_uv'] as num).toDouble();
    final int dateUnix = (json['date']);
    final String location = json['place_name'];
    final int weatherIcon = json['weather_icon'];

    return WeatherData(
      placeName: location.toLowerCase(),
      //placeName: json['place_name'],
      country: json['country'],
      lat: (json['lat'] as num).toDouble(),
      long: (json['long'] as num).toDouble(),
      day: dayFinder(dateUnix),
      datemonth: datemonthFinder(dateUnix),
      maxUV: maximumUV,
      maxTemp: maxTemp,
      maxuvTimeLocal: json['maxuv_time_local'],
      sunriseLocal: json['sunrise_local'],
      sunsetLocal: json['sunset_local'],
      weatherIcon: assignWeatherIcon(weatherIcon),
      burnTimes: Map<String, int>.from(json['burn_times']),
      elevation: json['elevation'],
      informalWeather: informalWeatherFinder(maxTemp),
      temperatureColor: temperatureColorFinder(maxTemp),
      uvIndexColor: uvIndexColorFinder(maximumUV),
      uvAction: uvActionFinder(maximumUV),
      uvLabel: uvLabelFinder(maximumUV),
      cloudiness: cloudiness,
      precipitation: precipitation,
      hourlyUV: List<double>.from(json['hourly_uv']),
    );
  }
}

IconData assignWeatherIcon(int weatherCode) {
  switch (weatherCode) {
    case 0:
      return WeatherIcons.day_sunny;
    case 1:
      return WeatherIcons.day_cloudy;
    case 2:
      return WeatherIcons.day_cloudy_high;
    case 3:
      return WeatherIcons.cloudy;
    case 45:
    case 48:
      return WeatherIcons.fog;
    case 51:
    case 53:
    case 55:
      return WeatherIcons.sprinkle;
    case 56:
    case 57:
    case 66:
    case 67:
    case 77:
      return WeatherIcons.sleet;
    case 61:
    case 63:
    case 80:
    case 81:
      return WeatherIcons.raindrops;
    case 65:
    case 82:
      return WeatherIcons.rain;
    case 71:
    case 73:
    case 85:
      return WeatherIcons.snow;
    case 75:
    case 86:
      return WeatherIcons.snowflake_cold;
    case 95:
    case 96:
    case 99:
      return WeatherIcons.thunderstorm;
  }
  return WeatherIcons.na; //fallback for unrecognised code

  // WMO Weather interpretation codes (WW)
  // Code	Description
  // 0	Clear sky
  // 1, 2, 3	Mainly clear, partly cloudy, and overcast
  // 45, 48	Fog and depositing rime fog
  // 51, 53, 55	Drizzle: Light, moderate, and dense intensity
  // 56, 57	Freezing Drizzle: Light and dense intensity
  // 61, 63, 65	Rain: Slight, moderate and heavy intensity
  // 66, 67	Freezing Rain: Light and heavy intensity
  // 71, 73, 75	Snow fall: Slight, moderate, and heavy intensity
  // 77	Snow grains
  // 80, 81, 82	Rain showers: Slight, moderate, and violent

  // 85, 86	Snow showers slight and heavy
  // 95 *	Thunderstorm: Slight or moderate
  // 96, 99 *	Thunderstorm with slight and heavy hail
}

String dayFinder(int dateUnix) {
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(dateUnix * 1000);
  const days = [
    'Monday', //0
    'Tuesday', //1
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  int day = dateTime.weekday - 1;
  return days[day];
}

String datemonthFinder(int dateUnix) {
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(dateUnix * 1000);
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  int date = dateTime.day;
  String month = months[dateTime.month - 1];
  return '$date $month';
}

String uvActionFinder(double uv) {
  if (uv <= 2) return 'No protection needed. Safe to stay outside.';
  if (uv <= 5) {
    return 'Use sunscreen and sun hats. Seek shade during midday peak hours (11 am-3 pm).';
  }
  if (uv <= 7) {
    return 'Apply SPF 50+ sunscreen, wear protective clothing, and seek shade.';
  }
  if (uv <= 10) {
    return 'High risk of harm. Avoid sun exposure if possible, apply high SPF, and cover up.';
  }
  return 'Avoid being outside during midday. Maximum protection is essential.';
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
  if (temp <= 8) return 'Cold - coat zipped up';
  if (temp <= 11) return 'Chilly - light coat or layers';
  if (temp <= 14) return 'Cool - jacket weather';
  if (temp <= 17) return 'Light jacket/jumper weather';
  if (temp <= 20) return 'T-shirt with backup layer';
  if (temp <= 23) return 'T-shirt weather';
  if (temp <= 26) return 'Shorts and T-shirts';
  if (temp <= 28) return 'Hot - seeking shade';
  return 'Very hot - too warm to function';
}


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


