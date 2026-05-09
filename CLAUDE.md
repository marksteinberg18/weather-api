# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Python backend
```bash
pip install -r requirements.txt   # install dependencies
python weather_api.py             # run locally on port 5000
```

Test endpoints locally:
- `http://localhost:5000/health`
- `http://localhost:5000/weather?lat=51.5072&long=-0.1276`
- `http://localhost:5000/test` (mock data, no external API calls)

### Flutter frontend (`dolomites_weather/`)
```bash
flutter pub get    # install dependencies
flutter run        # run on connected device/emulator
flutter build apk  # build Android APK
```

## Architecture

This is a two-part project:

**Backend** — `weather_api.py` is a Flask API deployed on Render at `https://weather-api-8bte.onrender.com`. It aggregates three external APIs into a single `/weather` response:
- **Open-Meteo** — elevation and UV index max value
- **OpenUV** — UV max time, sunrise, sunset (still used even though UV value now comes from Open-Meteo)
- **OpenWeatherMap** — temperature, weather description, icon, cloudiness

API keys are loaded from `.env` via `python-dotenv` as `OPENWEATHER_API_KEY` and `OPENUV_API_KEY`.

**Frontend** — `dolomites_weather/` is a Flutter app with two Dart files:
- `lib/main.dart` — single-screen UI (`MainWeatherScreen`). Gets GPS via `geolocator`, calls the Render API, displays two cards (UV index and temperature).
- `lib/weatherdata.dart` — `WeatherData` model. `fromJson()` deserialises the API response and eagerly computes all display properties (UV colour, UV label, UV action text, temperature colour, informal weather description, burn times) using standalone pure functions at the bottom of the file.

All display logic (colour thresholds, UV risk labels, informal clothing advice) lives in `weatherdata.dart`, not in the widget tree.

The Flutter app has no local state persistence — it is purely fetch-and-display on button press.

## Environment variables

`.env` (not committed) must contain:
```
OPENWEATHER_API_KEY=...
OPENUV_API_KEY=...
```
