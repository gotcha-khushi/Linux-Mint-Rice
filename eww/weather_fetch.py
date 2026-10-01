#!/usr/bin/env python3
import json
import ssl
import urllib.request
import sys

def fetch_json(url):
    ctx = ssl._create_unverified_context()
    # Use a curl User-Agent to trick servers into accepting the request
    req = urllib.request.Request(url, headers={'User-Agent': 'curl/7.68.0'})
    with urllib.request.urlopen(req, timeout=8, context=ctx) as response:
        return json.loads(response.read().decode())
    
def get_aqi_status(aqi):
    try:
        aqi = int(aqi)
        if aqi <= 50:
            return "Good"
        elif aqi <= 100:
            return "Moderate"
        elif aqi <= 150:
            return "Unhealthy for Sensitive Groups"
        elif aqi <= 200:
            return "Unhealthy"
        elif aqi <= 300:
            return "Very Unhealthy"
        else:
            return "Hazardous"
    except (ValueError, TypeError):
        return "Unknown"
    
try:
    # Use the original ip-api.com service from your Conky config
    geo = fetch_json("http://ip-api.com/json/")

    if geo.get("status") == "fail":
        raise Exception(f"Location API blocked the request: {geo.get('message')}")

    # ip-api.com uses 'lat' and 'lon' instead of 'latitude' and 'longitude'
    lat = geo['lat']
    lon = geo['lon']

    weather = fetch_json(
        f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}"
        f"&current=temperature_2m,relative_humidity_2m,precipitation,weather_code"
        f"&hourly=precipitation_probability"
    )

    aqi_data = fetch_json(
        f"https://air-quality-api.open-meteo.com/v1/air-quality?latitude={lat}&longitude={lon}"
        f"&current=us_aqi"
    )

    c = weather['current']
    temp = f"{float(c['temperature_2m']):.0f}°C"
    hum = f"{c['relative_humidity_2m']}%"
    rain = f"{float(c['precipitation']):.1f} mm | {int(weather['hourly']['precipitation_probability'][0])}%"
    raw_aqi = aqi_data['current']['us_aqi']

    aqi_val= f"{float(raw_aqi):.0f}"
    aqi_desc= get_aqi_status(raw_aqi)

    wcode = c['weather_code']
    conditions = {
        0: "Clear sky", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
        45: "Fog", 48: "Depositing rime fog", 51: "Light drizzle", 53: "Moderate drizzle",
        55: "Dense drizzle", 61: "Slight rain", 63: "Moderate rain", 65: "Heavy rain",
        71: "Slight snow", 73: "Moderate snow", 75: "Heavy snow", 77: "Snow grains",
        80: "Slight rain showers", 81: "Moderate rain showers", 82: "Violent rain showers",
        85: "Slight snow showers", 86: "Heavy snow showers", 95: "Thunderstorm"
    }
    cond = conditions.get(wcode, "Weather")

    print(f"{temp} {cond}   Humidity: {hum}   Rain: {rain}   AQI: {aqi_val} {aqi_desc}")

except Exception as e:
    # Prints the empty fallback for the widget to read
    print("--°C   Weather unavailable  |  Humidity: --%  |  Rain: -- mm | --%  |  AQI: --")
    # Prints the actual failure reason to the terminal for debugging
    print(f"Error details: {e}", file=sys.stderr)