class WeatherData {
  final String placeName;
  final String country;
  final double lat;
  final double long;
  final String date;
  final double maxTemp;
  final double maxUv;
  final String maxuvTimeLocal;
  final String sunriseLocal;
  final String sunsetLocal;
  final String weatherDescription;
  final String weatherIcon;
  final Map<String, int> burnTimes;
  final double elevation;

  WeatherData({
    required this.placeName,
    required this.country,
    required this.lat,
    required this.long,
    required this.date,
    required this.maxTemp,
    required this.maxUv,
    required this.maxuvTimeLocal,
    required this.sunriseLocal,
    required this.sunsetLocal,
    required this.weatherDescription,
    required this.weatherIcon,
    required this.burnTimes,
    required this.elevation,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      placeName: json['place_name'],
      country: json['country'],
      lat: (json['lat'] as num).toDouble(),
      long: (json['long'] as num).toDouble(),
      date: json['date'],
      maxUv: json['max_uv'],
      maxTemp: json['max_temp'],
      maxuvTimeLocal: json['maxuv_time_local'],
      sunriseLocal: json['sunrise_local'],
      sunsetLocal: json['sunset_local'],
      weatherDescription: json['weather_description'],
      weatherIcon: json['weather_icon'],
      burnTimes: Map<String, int>.from(json['burn_times']),
      elevation: json['elevation'],
    );
  }
}


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