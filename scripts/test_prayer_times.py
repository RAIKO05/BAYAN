import math
from datetime import datetime

lat = 33.5731
lng = -7.5898
now = datetime.now()
day_of_year = now.timetuple().tm_yday

gamma = 2 * math.pi / 365.25 * (day_of_year - 1)
eqtime = 229.18 * (0.000075 + 0.001868 * math.cos(gamma) - 0.032077 * math.sin(gamma) - 0.014615 * math.cos(2*gamma) - 0.040849 * math.sin(2*gamma))
decl = 0.006918 - 0.399912 * math.cos(gamma) + 0.070257 * math.sin(gamma) - 0.006758 * math.cos(2*gamma) + 0.000907 * math.sin(2*gamma)

tz = 1.0 # Morocco is UTC+1 (GMT+1)
solar_noon = (720.0 - 4.0 * lng - eqtime) / 60.0 + (tz - 0.0) # local noon

def hour_angle(alpha, lat, decl):
    lat_r = math.radians(lat)
    cos_h = (math.sin(math.radians(alpha)) - math.sin(lat_r) * math.sin(decl)) / (math.cos(lat_r) * math.cos(decl))
    cos_h = max(-1.0, min(1.0, cos_h))
    return math.degrees(math.acos(cos_h))

ha_fajr = hour_angle(-19.0, lat, decl)
ha_sunset = hour_angle(-0.833, lat, decl)

asr_alt = math.degrees(math.atan(1.0 / (1.0 + math.tan(abs(math.radians(lat) - decl)))))
ha_asr = hour_angle(asr_alt, lat, decl)

ha_isha = hour_angle(-17.0, lat, decl)

fajr = (solar_noon - ha_fajr / 15.0) % 24
dhuhr = (solar_noon + 5.0 / 60.0) % 24
asr = (solar_noon + ha_asr / 15.0) % 24
maghrib = (solar_noon + ha_sunset / 15.0 + 2.0 / 60.0) % 24
isha = (solar_noon + ha_isha / 15.0) % 24

def fmt(h):
    hours = int(h)
    mins = int((h - hours) * 60)
    return f"{hours:02d}:{mins:02d}"

print(f"Moroccan Habous: Fajr: {fmt(fajr)}, Dhuhr: {fmt(dhuhr)}, Asr: {fmt(asr)}, Maghrib: {fmt(maghrib)}, Isha: {fmt(isha)}")
