import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'weatherdata.dart';
import 'package:auto_size_text/auto_size_text.dart';

void main() {
  runApp(const UVWeatherApp());
}

const _white = Colors.white;

class UVWeatherApp extends StatelessWidget {
  const UVWeatherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather & UV',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        //textTheme: GoogleFonts.elMessiriTextTheme(),
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
  final hour = DateTime.now().hour;
  String get _greeting => hour < 12 ? 'Good morning!' : 'Good afternoon!';
  String _status = 'Press button to update.';
  String _location = '-';

  WeatherData? _weatherData;
  //Map<String, dynamic>? _weatherData;
  bool _loading = false;

  //change 'test' to 'weather' when going for live data
  final String apiUrl = 'https://weather-api-8bte.onrender.com/weather';
  Future<void> _getWeather() async {
    setState(() {
      _loading = true;
      _status = 'Getting location';
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
      setState(() => _status = 'Getting GPS coordinates');
      Position position = await Geolocator.getCurrentPosition();

      //Step 3: call the weather API on Render with the co-ordinates..
      setState(() => _status = 'Fetching weather data');

      //Build the URL
      final url = Uri.parse(
        '$apiUrl?lat=${position.latitude}&long=${position.longitude}',
      ); //not used for testing

      final response = await http.get(url);
      //final response = await http.get(
      //Uri.parse(apiUrl),
      //); //test data without lat/long data

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherData = WeatherData.fromJson(data);
          _location = '${_weatherData!.placeName}, ${_weatherData!.country}';
          _status = 'Stay safe in the sun.';
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
    final _screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              Image.asset(
                'assets/images/vibrantmountain.png',
                width: double.infinity,
                height: _screenHeight,
                fit: BoxFit.cover,
              ),
              Positioned(
                left: 7,
                right: 0,
                top: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Colors.white, size: 22),
                        Expanded(
                          child: Center(
                            child: AutoSizeText(
                              _location,
                              minFontSize: 12,
                              maxFontSize: 18,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _screenHeight * 0.01),
                    Text(
                      _greeting,
                      style: TextStyle(
                        fontSize: 25,
                        color: _white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _status,
                      style: TextStyle(fontSize: 20, color: _white),
                    ),
                    SizedBox(height: _screenHeight * 0.02),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        height: _screenHeight * 0.30,
                        child: Row(
                          children: [
                            Expanded(
                              child: Card(
                                margin: EdgeInsets.zero,
                                color:
                                    _weatherData?.uvIndexColor.withValues(
                                      alpha: 0.15,
                                    ) ??
                                    _white,
                                elevation: 4,
                                child: Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "MAX UV INDEX",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            _weatherData == null
                                                ? ''
                                                : _weatherData!.maxUV
                                                    .round()
                                                    .toString(),
                                            style: GoogleFonts.bebasNeue(
                                              fontSize: 70,
                                              fontWeight: FontWeight.w900,
                                              color:
                                                  _weatherData?.uvIndexColor ??
                                                  Colors.black,
                                            ),
                                          ),
                                          Text("  gauge "),
                                        ],
                                      ),
                                      Text(
                                        _weatherData == null
                                            ? ''
                                            : _weatherData!.uvLabel,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                          color:
                                              _weatherData?.uvIndexColor ??
                                              Colors.black,
                                        ),
                                      ),
                                      Text(
                                        _weatherData == null
                                            ? ''
                                            : _weatherData!.uvAction,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Card(
                                margin: EdgeInsets.zero,
                                color:
                                    _weatherData?.temperatureColor.withValues(
                                      alpha: 0.15,
                                    ) ??
                                    _white,
                                elevation: 4,
                                child: Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "MAX TEMP",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          _weatherData == null
                                              ? Text('')
                                              : AutoSizeText.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          _weatherData!.maxTemp
                                                              .toInt()
                                                              .toString(),
                                                      style: GoogleFonts.bebasNeue(
                                                        fontSize: 50,
                                                        color:
                                                            _weatherData
                                                                ?.temperatureColor ??
                                                            Colors.black,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        letterSpacing: -1,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: '°C',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color:
                                                            _weatherData
                                                                ?.temperatureColor ??
                                                            Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                minFontSize: 20,
                                              ),
                                          Text("  gauge "),
                                        ],
                                      ),
                                      _weatherData == null
                                          ? Text('')
                                          : RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text:
                                                      _weatherData!
                                                          .weatherDescription,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text:
                                                      ' (${_weatherData!.cloudiness.toString()}%)',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      Row(
                                        children: [
                                          _weatherData == null
                                              ? Icon(
                                                Icons.flutter_dash,
                                                size: 20,
                                              )
                                              : Image.network(
                                                'https://openweathermap.org/payload/api/media/file/${_weatherData?.weatherIcon}.png',
                                                width: 50,
                                                height: 40,
                                              ),
                                          _weatherData == null
                                              ? Text('')
                                              : Expanded(
                                                child: Text(
                                                  _weatherData!.informalWeather,
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    //letterSpacing: 1,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
