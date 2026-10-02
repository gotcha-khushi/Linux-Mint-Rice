#!/usr/bin/env python3
import json
import ssl
import urllib.request
import sys
import os
from datetime import datetime

# --- CHANGED: Cache file path to store the last successful weather string ---
CACHE_FILE = "/tmp/eww_weather_cache.txt"

def fetch_json(url):
    ctx = ssl._create_unverified_context()
    req = urllib.request.Request(url, headers={'User-Agent': 'curl/7.68.0'})
    with urllib.request.urlopen(req, timeout=8, context=ctx) as response:
        return json.loads(response.read().decode())

def get_aqi_status(aqi_value):
    try:
        aqi = float(aqi_value)
        if aqi <= 50: return "Good"
        elif aqi <= 100: return "Moderate"
        elif aqi <= 150: return "Unhealthy for Sensitive Groups"
        elif aqi <= 200: return "Unhealthy"
        elif aqi <= 300: return "Very Unhealthy"
        else: return "Hazardous"
    except (ValueError, TypeError):
        return "Unknown"

def get_time_indicator():
    hour = datetime.now().hour
    if 5 <= hour < 12:
        return "Morning"
    elif 12 <= hour < 17:
        return "Afternoon"
    elif 17 <= hour < 21:
        return "Evening"
    else:
        return "Night"

try:
    geo = fetch_json("http://ip-api.com/json/")
    if geo.get("status") == "fail":
        raise Exception("Location request failed")

    lat, lon = geo['lat'], geo['lon']
    weather = fetch_json(
        f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}"
        f"&current=temperature_2m,relative_humidity_2m,precipitation,weather_code"
        f"&hourly=precipitation_probability"
    )
    aqi_data = fetch_json(
        f"https://air-quality-api.open-meteo.com/v1/air-quality?latitude={lat}&longitude={lon}&current=us_aqi"
    )

    c = weather['current']
    temp = f"{float(c['temperature_2m']):.0f}°C"
    hum = f"{c['relative_humidity_2m']}%"
    rain = f"{float(c['precipitation']):.1f} mm | {int(weather['hourly']['precipitation_probability'][0])}%"
    raw_aqi = aqi_data['current']['us_aqi']

    aqi_val = f"{float(raw_aqi):.0f}"
    aqi_desc = get_aqi_status(raw_aqi)

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
    time_indicator = get_time_indicator()

    output = f"{time_indicator} {temp} {cond}   Humidity: {hum}   Rain: {rain}   AQI: {aqi_val} {aqi_desc}"

    # --- CHANGED: Write successfully fetched output to local cache file ---
    with open(CACHE_FILE, "w") as f:
        f.write(output)

    print(output)

except Exception:
    # --- CHANGED: If API fails/times out, print cached data instead of placeholders ---
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, "r") as f:
            print(f.read().strip())
    else:
        time_indicator = get_time_indicator()
        print(f"[{time_indicator}]  --°C   Weather unavailable   Humidity: --%   Rain: -- mm | --%   AQI: -- (Unknown)")