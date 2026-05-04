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

app = Flask(__name__)
CORS(app)

# class Location:
#     def __init__ (self,place:str, country:str, state:str, lat:float, long:float,):
#         self.place = place
#         self.country = country
#         self.state = state
#         self.lat = lat
#         self.long = long
    
#     def __str__(self):
#         state_str = f", {self.state} " if self.state else ""
#         return(f"Location:\t{self.place}, {self.country} {state_str}is at {self.lat},{self.long}")

class Weather:
    """Initialise a Weather object with location, temperature, UV, and sun data."""
    def __init__(self,place_name:str, country:str, lat:float, long:float, date:str, max_temp:float, maxuv_score:float, maxuv_time_local:str, sunrise_local:str, sunset_local:str, weather_description:str, weather_icon:str, burn_times: dict, elevation:float, cloudiness:int): 
        self.place_name = place_name # ✔ 
        self.country = country # ✔
        self.lat = lat # ✔
        self.long = long # ✔
        self.date = Date.fromisoformat(date) #will need to convert UNIX timestamp to YYYY--MM-DD
        self.max_temp = max_temp #from openweather
        self.max_uv = maxuv_score #from openUV ✔
        self.maxuv_time_local = maxuv_time_local #string ✔
        self.sunrise_local = sunrise_local #string ✔
        self.sunset_local = sunset_local #string  ✔
        self.weather_description = weather_description
        self.weather_icon = weather_icon
        self.burn_times = burn_times
        self.elevation = elevation
        self.cloudiness = cloudiness
        
   
        #Remember: weather icon at: http://openweathermap.org/img/w/{weather icon string e.g. 10d}.png
    
    def to_dict(self):
        """Return weather data as a dictionary for JSON serialisation."""
        return {
            "place_name" : self.place_name,
            "country" : self.country,
            "lat" : self.lat,
            "long" : self.long,
            "date" : str(self.date),
            "max_temp" : self.max_temp,
            "max_uv" : self.max_uv,
            "maxuv_time_local" : self.maxuv_time_local, #local time at this point
            "sunrise_local" : self.sunrise_local,
            "sunset_local" : self.sunset_local,
            "weather_description" : self.weather_description,
            "weather_icon" : self.weather_icon,
            "burn_times" : self.burn_times,
            "elevation" : self.elevation,
            "cloudiness" : self.cloudiness
        }

        
def get_weather(lat: float, long: float) -> Weather:
    """Get weather data for given coordinates"""

    #job 1. establish elevation of lat/long co-ordinates - important for UV index
    url = f'https://api.open-meteo.com/v1/elevation?latitude={lat}&longitude={long}'
    response = requests.get(url)
    data = response.json()
    altitude = float(data.get('elevation')[0])
    
    #job2. obtain UV data
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude" : lat,
        "longitude" : long,
        "daily" : ["uv_index_max"]
    }
    responses = requests.get(url, params=params)
    data = responses.json()
    uv_max_new = data['daily']['uv_index_max'][0] #3.65 on 4 May 2026
    
#     url = "https://api.open-meteo.com/v1/forecast"
# params = {
# 	"latitude": 52.52,
# 	"longitude": 13.41,
# 	"daily": ["uv_index_max", "uv_index_clear_sky_max"],
# 	"hourly": "temperature_2m",
# }
# responses = openmeteo.weather_api(url, params = params)
    
    
    
    #job 2. obtain UV data  
    openuv_url = 'https://api.openuv.io/api/v1/uv?'
    openuv_headers = {'x-access-token': OPENUV_API_KEY}
    openuv_params = {
        'lat':lat,
        'lng':long,
        'alt' : altitude,
        #'dt': '' - ISA time not used
        }
    response = requests.get(openuv_url, headers=openuv_headers, params=openuv_params)
    data = response.json()
    uv_max = uv_max_new #<we're getting this from open meteo now, formerly: data.get('result').get('uv_max')
    uv_max_time_utc = data.get('result').get('uv_max_time') # 2026-04-06T09:53:00.669Z
    sunrise_utc = data['result']['sun_info']['sun_times']['sunrise']
    sunset_utc = data['result']['sun_info']['sun_times']['sunset']
    #print(f'UV max: {uv_max}')
    #print(f'UTC UV max_time: {uv_max_time_utc}') #
    
    #job 3. obtain weather data
    url = f"https://api.openweathermap.org/data/2.5/weather"
    #docs:
    #https://openweathermap.org/api/current?collection=current_forecast
    params = {
        "lat" : lat,
        "lon" : long,
        "appid" : OPENWEATHER_API_KEY,
        "units" : "metric"
    }
    response = requests.get(url,params=params)
    data = response.json()
    #temp_min = data['main']['temp_min']
    temp_max = data['main']['temp_max']    
    weather_description  = data['weather'][0]['description']
    weather_icon = data['weather'][0]['icon']
    cloudiness = data.get('clouds', {}).get('all',0)
     
    #job 4. convert the timestamps to local time
    uvmaxtime_local = utc_to_local(uv_max_time_utc,lat,long)
    sunrise_local = utc_to_local(sunrise_utc,lat,long)
    sunset_local = utc_to_local(sunset_utc,lat,long)
                                    
    
    #create and return a Weather object
    today = datetime.now().strftime('%Y-%m-%d')
    
    weather = Weather(
        place_name= data.get('name','Unknown'),
        country=data.get('sys', {}).get('country','Unknown'),
        lat=lat,
        long=long,
        date=today,
        max_temp=temp_max,
        maxuv_score=uv_max,
        maxuv_time_local=uvmaxtime_local,
        sunrise_local=sunrise_local,
        sunset_local=sunset_local,
        weather_description=weather_description,
        weather_icon=weather_icon,
        burn_times=calculate_burntimes(uv_max),
        elevation=altitude,
        cloudiness=cloudiness)
    return weather  
    
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
        return jsonify(weather.to_dict())
    
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
 

