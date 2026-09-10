#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/api"

LAT="15.5"
LON="50.5"
WEATHER_URL="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,relative_humidity_2m,wind_speed_10m,wind_direction_10m,pressure_msl,precipitation,weather_code&hourly=temperature_2m,wind_speed_10m,wind_direction_10m,precipitation_probability,pressure_msl&forecast_days=7&timezone=auto&wind_speed_unit=ms"
MARINE_URL="https://marine-api.open-meteo.com/v1/marine?latitude=${LAT}&longitude=${LON}&current=wave_height,wave_direction,wave_period,sea_surface_temperature&hourly=wave_height,wave_direction,wave_period,sea_surface_temperature&forecast_days=7&timezone=auto"

weather="$(curl --fail --retry 3 --retry-delay 2 --silent --show-error "$WEATHER_URL")"
marine="$(curl --fail --retry 3 --retry-delay 2 --silent --show-error "$MARINE_URL")"

node - "$ROOT/api/live.json" "$weather" "$marine" <<'NODE'
const fs = require('fs');
const [,, output, weatherText, marineText] = process.argv;
const weather = JSON.parse(weatherText);
const marine = JSON.parse(marineText);
const payload = {
  updated_at: new Date().toISOString(),
  source: {
    weather: 'https://open-meteo.com/en/docs',
    marine: 'https://open-meteo.com/en/docs/marine-weather-api'
  },
  location: { latitude: 15.5, longitude: 50.5, timezone: weather.timezone },
  weather,
  marine
};
const tmp = `${output}.tmp`;
fs.writeFileSync(tmp, JSON.stringify(payload, null, 2) + '\n');
fs.renameSync(tmp, output);
NODE

echo "Updated $ROOT/api/live.json"
