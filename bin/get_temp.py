#!/usr/bin/env python3

import requests
import sys
import os
import time
import pprint

lighting = ""
cloud = ""
rain = ""
heavy_rain = ""
moon = ""
sun = ""
smog = ""

def convert_f(temp):
    return (temp * 9/5) + 32

def convert_weather(s):
    tokens = s.split('_')
    fixed = list()
    for t in tokens:
        f = t[0].upper() + t[1:]
        fixed.append(f)
    return ' '.join(fixed)

def request_weather(station_code):
    r = requests.get("https://api.weather.gov/stations/{}/observations/latest".format(sys.argv[1]))
    j = r.json()
    temp = j['properties']['temperature']['value']
    # pprint.pprint(j['properties'])
    # try:
    #     weather = j['properties']['presentWeather'][0]['weather']
    # except:
    #     weather = "clear"
    weather = j['properties']['textDescription']
    temp = convert_f(temp)
    return (convert_weather(weather), round(temp, 1))


def in_time(script_file):
    try:
        t = os.path.getmtime(time_file)
        elapsed = time.time() - t
        if elapsed/60 > 10:
            return False
        else:
            return True
    except FileNotFoundError as e:
        return False
    

def update_file(time_file, t):
    f = open(time_file, "w")
    f.write(t[0]+ " " + str(t[1]) + "F")
    try:
        os.utime(time_file)
    finally:
        f.close()

if len(sys.argv) != 2:
    print("Usage {} <ICAO code>".format(sys.argv[0]))
    exit(1)


time_file = os.path.join("/tmp/", ".get_temp")

if in_time(time_file):
    f = open(time_file).read()
    print(f)
else:
    t = request_weather(sys.argv[1])
    print("{} {}F".format(t[0], t[1]))
    update_file(time_file, t)
