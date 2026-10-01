#!/usr/bin/env python3
import json, ssl, urllib.request

def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "ConkyWeather/1.0"})
    with urllib.request.urlopen(req, timeout=8, context=ssl._create_unverified_context()) as response:
        return json.load(response)

conditions = {
    0: "Clear", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
    45: "Fog", 48: "Rime fog", 51: "Light drizzle", 53: "Drizzle",
    55: "Heavy drizzle", 61: "Light rain", 63: "Rain", 65: "Heavy rain",
    71: "Light snow", 73: "Snow", 75: "Heavy snow",
    80: "Rain showers", 81: "Rain showers", 82: "Heavy showers", 95: "Thunderstorm",
}

try:
    geo = fetch_json("http://ip-api.com/json/")
    weather = fetch_json(f"https://api.open-meteo.com/v1/forecast?latitude={geo['lat']}&longitude={geo['lon']}&current=temperature_2m,relative_humidity_2m,precipitation,weather_code&hourly=precipitation_probability")
    air = fetch_json(f"https://air-quality-api.open-meteo.com/v1/air-quality?latitude={geo['lat']}&longitude={geo['lon']}&current=us_aqi")

    c = weather["current"]
    temp = f"{float(c['temperature_2m']):.0f}${{voffset -4}}${{font Sans:size=16}}°${{font}}${{voffset 4}}C"
    cond = conditions.get(c['weather_code'], "Weather")
    hum = f"{float(c['relative_humidity_2m']):.0f}%"
    rain = f"{float(c['precipitation']):.1f} mm | {int(weather['hourly']['precipitation_probability'][0])}%"
    aqi = f"{float(air['current']['us_aqi']):.0f}"

    print(f"{temp}   {cond}  |  Humidity: {hum}  |  Rain: {rain}  |  AQI: {aqi}")
except:
    print(f"--${{voffset -4}}${{font Sans:size=16}}°${{font}}${{voffset 4}}C   Weather unavailable  |  Humidity: --%  |  Rain: -- mm | --%  |  AQI: --")