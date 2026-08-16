#!/usr/bin/env bash
# Downloads input data: TfC GTFS feeds (road transport + metro), OSM network
# (Overpass), MapLibre GL. Everything is cached — re-running only fetches what
# is missing.
#
# Cairo quirk: TWO feeds from the Transport for Cairo GeoNode portal, served as
# stable document URLs (each download is a zip that CONTAINS the actual GTFS zip):
#   doc 88 — road transport (formal CTA/Mwasalat buses + paratransit, all route_type 3,
#            modes are separated by AGENCY, not route_type; fieldwork 2019–2023)
#   doc 87 — Cairo Metro lines M1 + M2
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/gtfs data/gtfs-metro data/osm web/vendor

# A downloaded extract is only accepted if it PARSES and carries a plausible
# number of elements. `grep -q '"elements"'` — the guard this family used
# everywhere — passes on a truncated response too: Brașov's roads arrived as a
# 65 kB fragment that still contained the string, was taken for complete, and
# silently skipped the city (16.08.2026).
# The minimum differs by extract: a road network runs to tens of thousands of
# ways, a metro network to a few hundred, so the caller passes its own floor
# rather than sharing one.
# A rejected file is deleted rather than left behind — the `[ ! -f … ]` gates
# below only ask whether the file exists, so a fragment on disk would be taken
# for a finished download on the next run.
ok_json () { # $1=file  $2=minimum element count
  python3 - "$1" "$2" <<'PYEOF' 2>/dev/null
import json, sys
try:
    sys.exit(0 if len(json.load(open(sys.argv[1])).get("elements", [])) >= int(sys.argv[2]) else 1)
except Exception:
    sys.exit(1)
PYEOF
}

# 1) GTFS — road transport (nested zip: gtfs_gcr_bronze.zip inside)
if [ ! -f data/gtfs/routes.txt ]; then
  echo "== TfC GTFS (road transport) =="
  curl -fL --retry 3 --max-time 600 -o data/tfc_road.zip \
    "https://data.transportforcairo.com/documents/88/download"
  unzip -o data/tfc_road.zip -d data/gtfs
  inner=$(ls data/gtfs/*.zip 2>/dev/null | head -1 || true)
  if [ -n "$inner" ]; then unzip -o "$inner" -d data/gtfs && rm -f "$inner"; fi
fi

# 1b) GTFS — metro (nested zip as well)
if [ ! -f data/gtfs-metro/routes.txt ]; then
  echo "== TfC GTFS (metro) =="
  curl -fL --retry 3 --max-time 600 -o data/tfc_metro.zip \
    "https://data.transportforcairo.com/documents/87/download"
  unzip -o data/tfc_metro.zip -d data/gtfs-metro
  inner=$(ls data/gtfs-metro/*.zip 2>/dev/null | head -1 || true)
  if [ -n "$inner" ]; then unzip -o "$inner" -d data/gtfs-metro && rm -f "$inner"; fi
fi

# 2) OSM — roadways over the whole road-transport network (GTFS stops extent
#    29.745–30.295 N, 30.877–31.755 E plus margin: 6th of October in the west,
#    10th of Ramadan / New Administrative Capital reach in the east)
if [ ! -f data/osm/cairo.json ]; then
  echo "== Overpass (roads) =="
  Q='[out:json][timeout:900];way(29.70,30.82,30.35,31.81)["highway"~"^(motorway|trunk|primary|secondary|tertiary|unclassified|residential|living_street|service|busway|construction|motorway_link|trunk_link|primary_link|secondary_link|tertiary_link)$"];out geom;'
  ok=0
  for EP in "https://overpass-api.de/api/interpreter" \
            "https://maps.mail.ru/osm/tools/overpass/api/interpreter" \
            "https://overpass.kumi.systems/api/interpreter"; do
    echo "-- $EP"
    if curl -fsS --max-time 900 -o data/osm/cairo.json --data-urlencode "data=$Q" "$EP" \
       && ok_json "data/osm/cairo.json" 2000; then
      ok=1; break
    fi
  done
  [ "$ok" = 1 ] || { rm -f data/osm/cairo.json; echo "Overpass: all mirrors failed" >&2; exit 1; }
fi

# 2b) OSM — metro rails (separate network: Cairo Metro is railway=subway on the
#     surface sections too; include light_rail for safety). Bbox = metro feed
#     stops extent (M1 Helwan–New El-Marg, M2 Shobra–El Mounib) plus margin.
if [ ! -f data/osm/cairo-metro.json ]; then
  echo "== Overpass (metro rails) =="
  QT='[out:json][timeout:300];way(29.80,31.10,30.22,31.42)["railway"~"^(subway|light_rail|rail)$"];out geom;'
  ok=0
  for EP in "https://overpass-api.de/api/interpreter" \
            "https://maps.mail.ru/osm/tools/overpass/api/interpreter" \
            "https://overpass.kumi.systems/api/interpreter"; do
    echo "-- $EP"
    if curl -fsS --max-time 300 -o data/osm/cairo-metro.json --data-urlencode "data=$QT" "$EP" \
       && ok_json "data/osm/cairo-metro.json" 40; then
      ok=1; break
    fi
  done
  [ "$ok" = 1 ] || { rm -f data/osm/cairo-metro.json; echo "Overpass (metro): all mirrors failed" >&2; exit 1; }
fi

# 3) MapLibre GL (vendored, no CDN at runtime)
if [ ! -f web/vendor/maplibre-gl.js ]; then
  echo "== MapLibre GL =="
  curl -fL --retry 3 -o web/vendor/maplibre-gl.js  https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.js
  curl -fL --retry 3 -o web/vendor/maplibre-gl.css https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.css
fi

echo "OK — data ready:"
du -sh data/tfc_road.zip data/tfc_metro.zip data/osm/cairo.json data/osm/cairo-metro.json 2>/dev/null || true
