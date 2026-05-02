import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'weatherdata.dart';

void main() {
  runApp(const UVWeatherApp());
}

class UVWeatherApp extends StatelessWidget {
  const UVWeatherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather & UV',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      debugShowCheckedModeBanner: false,
      home: const MainWeatherScreen(),
    );
  }
}

class MainWeatherScreen extends StatefulWidget {
  const MainWeatherScreen({super.key});
  @override
  State<MainWeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<MainWeatherScreen> {
  String _status = 'Press button to get weather and UV burn times';
  //String _placeName = 'Loading'
  //String _country = 'Loading'
  String _location = 'Loading';

  WeatherData? _weatherData;
  //Map<String, dynamic>? _weatherData;
  bool _loading = false;

  //change 'test' to 'weather' when going for live data
  final String apiUrl = 'https://weather-api-8bte.onrender.com/test';
  Future<void> _getWeather() async {
    setState(() {
      _loading = true;
      _status = 'Getting location....';
    });
    try {
      //Step 1: do we have location permission?
      LocationPermission permission = await Geolocator.checkPermission();
      //If permission denies, ask the user:
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        //if they still deny, stop here:
        if (permission == LocationPermission.denied) {
          setState(() {
            _status = 'Location permission denied';
            _loading = false;
          });
          return; //Exit as permission denied
        }
      }
      //Step 2: get the phone's current GPS coordinates
      setState(() => _status = 'Getting GPS coordinates...');
      Position position = await Geolocator.getCurrentPosition();

      //Step 3: call the weather API on Render with the co-ordinates..
      setState(() => _status = 'Fetching weather and UV data...');

      //Build the URL
      final url = Uri.parse(
        '$apiUrl?lat=${position.latitude}&long=${position.longitude}',
      ); //not used for testing

      //final response = await http.get(url);
      final response = await http.get(
        Uri.parse(apiUrl),
      ); //test data without lat/long data

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherData = WeatherData.fromJson(data);
          _location = '${_weatherData!.placeName}, ${_weatherData!.country}';
          _status = 'Data received!';
          _loading = false;
        });
      } else {
        setState(() {
          _status = 'API error: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _loading = false;
      });
    }
  }

  //basic UI will develop this...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //   appBar: AppBar(
      //     backgroundColor: const Color(0xFF2EA8E8),
      //     centerTitle: true,
      //     leading: const Icon(Icons.settings, color: Colors.white),
      //     title: const Text(
      //       'Here!',
      //       style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      //     ),
      //   ),
      body: Column(
        children: [
          Stack(
            children: [
              Image.asset(
                'assets/images/vibrantmountain.png',
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.cover,
              ),
              Positioned(
                left: 10,
                top: 40,
                child: Column(
                  //crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _location,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'sett',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _getWeather,
        child: const Icon(Icons.update),
      ),
    );
  }
}

//   body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(_status),
//               const SizedBox(height: 16),
//               if (_loading) const CircularProgressIndicator(),
//               if (_weatherData != null) Text(_weatherData.toString()),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _loading ? null : _getWeather,
//         child: const Icon(Icons.cloud_download),
//       ),
