#A program that:
# Gets weather data for any city from a free API
# Stores favourite cities
# Shows current weather + 5-day forecast
# Compares weather between multiple cities
# Saves historical lookups to JSON

# Menu options:
    # View weather for a city - maximum temperature and maximum UV (and time of that)
    # Add city to favourites
    # View all favourite cities' weather
    # Compare weather between cities
    # View weather history
    # Remove favourite city
    # Quit
from flask import Flask, jsonify, request
from flask_cors import CORS    
import os
from datetime import date as Date, datetime
from zoneinfo import ZoneInfo
import requests
from timezonefinder import TimezoneFinder
from dotenv import load_dotenv

# Load environment variables
load_dotenv() #this contains the API codes

# Get the keys
OPENWEATHER_API_KEY = os.getenv('OPENWEATHER_API_KEY')
OPENUV_API_KEY = os.getenv('OPENUV_API_KEY')
BIGDATA_API_KEY = os.getenv('BIGDATA_API_KEY')

app = Flask(__name__)
CORS(app)

class Weather:
    """Initialise a Weather object with location, temperature, UV, and sun data."""
    def __init__(self,place_name:str, country:str, lat:float, long:float, date:int, max_temp:float, maxuv_score:float, maxuv_time_local:str, sunrise_local:str, sunset_local:str, weather_icon:str, burn_times: dict, elevation:float, cloudiness:int, precipitation:int): 
        self.place_name = place_name # ✔ 
        self.country = country # ✔
        self.lat = lat # ✔
        self.long = long # ✔
        self.date = date #stored as  UNIX timestamp
        self.max_temp = max_temp #from openweather
        self.max_uv = maxuv_score #from openUV ✔
        self.maxuv_time_local = maxuv_time_local #string ✔
        self.sunrise_local = sunrise_local #string ✔
        self.sunset_local = sunset_local #string  ✔
        self.weather_icon = weather_icon
        self.burn_times = burn_times
        self.elevation = elevation
        self.cloudiness = cloudiness # %
        self.precipitation = precipitation # %
        
   
        #Remember: weather icon at: http://openweathermap.org/img/w/{weather icon string e.g. 10d}.png
    
    def to_dict(self):
        """Return weather data as a dictionary for JSON serialisation."""
        return {
            "place_name" : self.place_name,
            "country" : self.country,
            "lat" : self.lat,
            "long" : self.long,
            "date" : self.date,
            "max_temp" : self.max_temp,
            "max_uv" : self.max_uv,
            "maxuv_time_local" : self.maxuv_time_local, #local time at this point
            "sunrise_local" : self.sunrise_local,
            "sunset_local" : self.sunset_local,
            "weather_icon" : self.weather_icon,
            "burn_times" : self.burn_times,
            "elevation" : self.elevation,
            "cloudiness" : self.cloudiness,
            "precipitation" : self.precipitation
        }

        
def get_weather(lat: float, long: float):  #-> Weather:
    """Get weather data for given coordinates"""

    #job 1. establish elevation of lat/long co-ordinates - important for UV index
    url = f'https://api.open-meteo.com/v1/elevation?latitude={lat}&longitude={long}'
    response = requests.get(url)
    data = response.json()
    altitude = float(data.get('elevation')[0])
    
    #job2. obtain UV and weather data
    url = 'https://api.open-meteo.com/v1/forecast'
    #lat = request.args.get('lat',51.5072)
    #long = request.args.get('long',-0.1276)
    params = {
        "latitude" : lat,
        "longitude" : long,
        "daily" : ['uv_index_max','temperature_2m_max','sunrise','sunset','weather_code','precipitation_probability_max','cloud_cover_mean'],
        "timezone" : "auto",
        "forecast_days" : 1
    }
    responses = requests.get(url, params=params)
    data = responses.json()
    uv_max_new = data['daily']['uv_index_max'][0] #3.65 on 4 May 2026    
    
    #job 3. obtain location details
    reverse_geolocationURL = 'https://api-bdc.net/data/reverse-geocode'
    params = {
        "latitude" : lat,
        "longitude" : long,
        "localityLanguage" : 'en',
        "key" : BIGDATA_API_KEY
    }
    response = requests.get(reverse_geolocationURL,params=params)
    data = response.json()
    cityName = data['city']
    countryName = data['countryCode']

    #job4. check we've got all weather object fields
    dt = datetime.fromisoformat(data['daily']['time'][0]) #2026-05-12
    date = int(dt.timestamp()) #stored as UNIX timestamp
    
    #     place_name ✔
    #     self.country ✔
    #     lat ✔
    #     long ✔
    #     date ✔ now converted to UNIX timestamp
    #     max_temp ✔ 
    #     maxuv_score ✔
    #     maxuv_time_local X - this will have to return 00:00 currently. Maybe then can refactor to have hourly UV to find the maximum time and/or display as graph ?
    #     sunrise_local ✔ (this is local time zone correct, format good 12:45)
    #     sunset_local  ✔ (this is local time zone correct, format good 12:45)
    #     weather_icon ✔ e.g. [3] description can be inferred from https://www.nodc.noaa.gov/archive/arc0021/0002199/1.1/data/0-data/HTML/WMO-CODE/WMO4677.HTM maybe ?
    #     burn_times ✔ can be calculated because we have uv max
    #     elevation ✔ obtained from open-meteo already
    #     cloudiness ✔ returned as cloud_cover_mean %
    #     precipitation ✔ NEW FIELD! returned as precipitation_probability_max % 
    uv_maximum = data['daily']['uv_index_max'][0] #3.65 on 4 May 2026
    
    #create and return a Weather object
    weather = Weather(
        place_name= cityName, #✔
        country=countryName, #✔
        lat=lat, #✔
        long=long, #✔
        date=date, #✔ - UNIX timestamp
        max_temp=data['daily']['temperature_2m_max'], #✔
        maxuv_score=uv_maximum, #✔
        maxuv_time_local=data['daily'][], #will need more work
        sunrise_local=data['daily'][],
        sunset_local=data['daily'][],
        weather_icon=data['daily'][],
        burn_times=calculate_burntimes(uv_maximum),
        elevation=altitude,
        cloudiness=data['daily'][],
        precipitation=data['daily'][])
    
    #data['daily']['temperature_2m_max']
    #data['daily']['weather_code']
    
    
def calculate_burntimes (uv_max: float) -> dict:
    """Calculate burn times in minutes for skin types 1-6 based on UV index."""
    burn_dict = {}
    for i in range (1,7):
        burn_dict[str(i)] = round((200*i) / (3*uv_max))
    return burn_dict
         
        
        
def utc_to_local(utc_str: str, lat:float, long:float) ->str:
    """Convert a UTC timestamp string to local time string using coordinates to determine timezone."""
    dt = datetime.fromisoformat(utc_str.replace("Z","+00:00"))
    tf = TimezoneFinder()
    tz_name = str(tf.timezone_at(lat=lat,lng=long))
    local_dt = dt.astimezone(ZoneInfo(tz_name))
    return local_dt.strftime("%H:%M")

          
# API Endpoints - no main() needed now

@app.route('/test')
def test():
    """Mock data return to save external API calls"""
    mock_data = {
        "place_name" : "Cobble Hill",
        "country" : "NY",
        "lat" : 123.4,
        "long" : 5678.9,
        "date" : "2026-05-02",
        "max_temp" : 36.2,
        "max_uv" : 11.32,
        "maxuv_time_local" : "13:46",
        "sunrise_local" : "06:45",
        "sunset_local" : "21:05",
        "weather_description" : "sunny",
        "weather_icon" : "10d",
        "burn_times" : calculate_burntimes(4.32),
        "elevation" : 312.3}
    print (mock_data)
    return jsonify(mock_data)

@app.route('/debug-reverse')
def debug_meteo():
    # reverse_geolocationURL = 'https://api-bdc.net/data/reverse-geocode'
    # lat = request.args.get('lat',51.5072)
    # long = request.args.get('long',-0.1276)
    # params = {
    #     "latitude" : lat,
    #     "longitude" : long,
    #     "localityLanguage" : 'en',
    #     "key" : BIGDATA_API_KEY
    # }
    # response = requests.get(reverse_geolocationURL,params=params)
    # data = response.json()
    # cityName = data['city']
    # countryName = data['countryCode']
    # return f'{cityName}, {countryName}'
    
    
    url = 'https://api.open-meteo.com/v1/forecast'
    lat = request.args.get('lat',51.5072)
    long = request.args.get('long',-0.1276)
    params = {
        "latitude" : lat,
        "longitude" : long,
        "daily" : ['uv_index_max','temperature_2m_max','sunrise','sunset','weather_code','precipitation_probability_max','cloud_cover_mean'],
        "timezone" : "auto",
        "forecast_days" : 1
    }
    responses = requests.get(url, params=params)
    data = responses.json()
    return jsonify(data)

    
#https://open-meteo.com/en/docs?hourly=&forecast_days=1&daily=uv_index_max,temperature_2m_max,sunrise,sunset,weather_code,precipitation_probability_max&timezone=auto




@app.route('/health') #remember this is not weather/health, just /health
def health():
    """Health check endpoint — returns API status."""
    return jsonify({"status" : "ok", "message": "Weather API is running"})

@app.route('/weather', methods=['GET'])
def weather_endpoint():
    """GET /weather — accepts lat and long query params, returns weather data as JSON."""
    try:
        #Get parameters from URL
        lat = request.args.get('lat')
        long = request.args.get('long')
        
        #Validate parameters
        if not lat or not long:
            return jsonify({"error" : "lat and long must be numbers"}),400
        
        #Convert to float
        try:
            lat = float(lat)
            long = float(long)
        except ValueError:
            return jsonify({"error" : "lat and long must be numbers"}), 400
        
        print(f'Incoming Latitude: {lat}')
        print(f'Incoming Longitude: {long}')
        
        
        #Validate range
        if not (-90 <= lat <= 90) or not (-180 <= long <= 180):
            return jsonify({"error": "Invalid coordinates"}),400
        
        #Get weather data
        weather = get_weather(lat,long)
        
        #Return as JSON
        #return jsonify(weather.to_dict())
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
if __name__ == '__main__':
    print('Starting Weather API')
    #print('Test it: http://localhost:5000/weather?lat=10.1632&long=76.6413')
    import os
    port = int(os.environ.get('PORT', 5000))
    print(f' Weather API using port {port}')
    app.run(host='0.0.0.0', port=port, debug=False)
    
    #London: 51.5072° N, 0.1276° W
    #https://weather-api-8bte.onrender.com/weather?lat=51.5072&long=-0.1276
    
    #Cobble Hill, New York 40.6913° N latitude and 73.9972° W longitude
    #https://weather-api-8bte.onrender.com/weather?lat=40.6913&long=-73.9972
 
# WMO Weather interpretation codes (WW)
# Code	Description
# 0	Clear sky
# 1, 2, 3	Mainly clear, partly cloudy, and overcast
# 45, 48	Fog and depositing rime fog
# 51, 53, 55	Drizzle: Light, moderate, and dense intensity
# 56, 57	Freezing Drizzle: Light and dense intensity
# 61, 63, 65	Rain: Slight, moderate and heavy intensity
# 66, 67	Freezing Rain: Light and heavy intensity
# 71, 73, 75	Snow fall: Slight, moderate, and heavy intensity
# 77	Snow grains
# 80, 81, 82	Rain showers: Slight, moderate, and violent
# 85, 86	Snow showers slight and heavy
# 95 *	Thunderstorm: Slight or moderate
# 96, 99 *	Thunderstorm with slight and heavy hail