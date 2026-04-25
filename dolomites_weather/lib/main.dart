import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      ),
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
  Map<String,dynamic> ? _weatherData;
  bool _loading = false;

  final String apiUrl = 'https://weather-api-8bte.onrender.com/weather';
  Future<void> _getWeather() async {
    setState(() {
      _loading = true;
      _status = 'Getting location....';
    });
    try {
      //Step 1: do we have location permission?
      LocationPermission permission = await Geolocator.checkPermission();
      //If permission denies, ask the user:
      if (permission==LocationPermission.denied) {
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
      final url = Uri.parse('$apiUrl?lat=${position.latitude}&long=${position.longitude}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherData = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather & UV')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_status),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (_weatherData != null)
              Text(_weatherData.toString()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _getWeather,
        child: const Icon(Icons.cloud_download),
      ),
    );
  }
}



