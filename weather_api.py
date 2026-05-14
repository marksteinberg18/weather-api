
from flask import Flask, jsonify, request
from flask_cors import CORS    
import os
import requests
from dotenv import load_dotenv
from datetime import datetime

# Load environment variables
load_dotenv() #this contains the API codes

# Get the keys
BIGDATA_API_KEY = os.getenv('BIGDATA_API_KEY')

app = Flask(__name__)
CORS(app)

class Weather:
    """Initialise a Weather object with location, temperature, UV, and sun data."""
    def __init__(self,place_name:str, country:str, lat:float, long:float, date:int, max_temp:float, maxuv_score:float, maxuv_time_local:str, sunrise_local:str, sunset_local:str, weather_icon:str, burn_times: dict, elevation:float, cloudiness:int, precipitation:int, hourly_uv:list): 
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
        self.hourly_uv = hourly_uv 
        
   
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
            "precipitation" : self.precipitation,
            "hourly_uv" : self.hourly_uv
            
        }

        
def get_weather(lat: float, long: float)  -> Weather:
    """Get weather data for given coordinates"""

    #job 1. establish elevation of lat/long co-ordinates - important for UV index
    url = f'https://api.open-meteo.com/v1/elevation?latitude={lat}&longitude={long}'
    response = requests.get(url)
    data_elevation = response.json()
    altitude = float(data_elevation.get('elevation')[0])
    
    #job2. obtain UV and weather data
    url = 'https://api.open-meteo.com/v1/forecast'
    #lat = request.args.get('lat',51.5072)
    #long = request.args.get('long',-0.1276)
    params = {
        "latitude" : lat,
        "longitude" : long,
        "daily" : ['uv_index_max','temperature_2m_max','sunrise','sunset','weather_code','precipitation_probability_max','cloud_cover_mean'],
        "timezone" : "auto",
        "forecast_days" : 1,
        "hourly" : ['uv_index']
    }
    responses = requests.get(url, params=params)
    data_meteo = responses.json()
    
    #job 3. obtain location details
    reverse_geolocationURL = 'https://api-bdc.net/data/reverse-geocode'
    params = {
        "latitude" : lat,
        "longitude" : long,
        "localityLanguage" : 'en',
        "key" : BIGDATA_API_KEY
    }
    response = requests.get(reverse_geolocationURL,params=params)
    data_geolocation = response.json()
    cityName = data_geolocation['city']
    countryName = data_geolocation['countryCode']

    #job4. check we've got all weather object fields
    dt = datetime.fromisoformat(data_meteo['daily']['time'][0]) #2026-05-12
    date = int(dt.timestamp()) #stored as UNIX timestamp
    
    #     place_name ✔
    #     self.country ✔
    #     lat ✔
    #     long ✔
    #     date ✔ now converted to UNIX timestamp
    #     max_temp ✔ 
    #     maxuv_score ✔
    #     sunrise_local ✔ (this is local time zone correct, format good 12:45)
    #     sunset_local  ✔ (this is local time zone correct, format good 12:45)
    #     weather_icon ✔ e.g. [3] description can be inferred from https://www.nodc.noaa.gov/archive/arc0021/0002199/1.1/data/0-data/HTML/WMO-CODE/WMO4677.HTM maybe ?
    #     burn_times ✔ can be calculated because we have uv max
    #     elevation ✔ obtained from open-meteo already
    #     cloudiness ✔ returned as cloud_cover_mean %
    #     precipitation ✔ NEW FIELD! returned as precipitation_probability_max % 
    #     hourly_uv ✔ LIST
    
    uv_maximum = data_meteo['daily']['uv_index_max'][0] #3.65 on 4 May 2026
    hourly_uv = data_meteo['hourly']['uv_index']
    indexOfMaxUV = hourly_uv.index(max(hourly_uv))
    
    #create and return a Weather object
    weather = Weather(
        place_name= cityName, #✔
        country=countryName, #✔
        lat=lat, #✔
        long=long, #✔
        date=date, #✔ - UNIX timestamp
        max_temp=data_meteo['daily']['temperature_2m_max'][0], #✔
        maxuv_score=uv_maximum, #✔
        maxuv_time_local=f"{indexOfMaxUV:02d}:00",
        sunrise_local=data_meteo['daily']['sunrise'][0][-5:],
        sunset_local=data_meteo['daily']['sunset'][0][-5:],
        weather_icon=data_meteo['daily']['weather_code'][0],
        burn_times=calculate_burntimes(uv_maximum),
        elevation=altitude,
        cloudiness=data_meteo['daily']['cloud_cover_mean'][0],
        precipitation=data_meteo['daily']['precipitation_probability_max'][0],
        hourly_uv=hourly_uv
        )
    return weather
    
    
def calculate_burntimes (uv_max: float) -> dict:
    """Calculate burn times in minutes for skin types 1-6 based on UV index."""
    burn_dict = {}
    for i in range (1,7):
        burn_dict[str(i)] = round((200*i) / (3*uv_max))
    return burn_dict
         

          
# API Endpoints - no main() needed now

    
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

#https://pub.dev/packages/weather_icons/versions/3.0.0