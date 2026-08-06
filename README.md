# cairo-bus-map

Interactive web map of public transport in the Greater Cairo Region in the
visual logic of a classic printed network map: **354 formal bus lines, 639
paratransit routes and the Cairo Metro (M1 · M2)** drawn exactly along roadways
and rail (own HMM/Viterbi map matching on an OSM graph), line numbers written
parallel to every street they use, labeled stops, true roundabout arcs.

Seventh city of the family, alongside
[krakow-bus-map](https://github.com/Miqell24/krakow-bus-map),
[poznan-bus-map](https://github.com/Miqell24/poznan-bus-map),
[gzm-bus-map](https://github.com/Miqell24/gzm-bus-map),
[trojmiasto-bus-map](https://github.com/Miqell24/trojmiasto-bus-map),
[athens-bus-map](https://github.com/Miqell24/athens-bus-map) and
[thessaloniki-bus-map](https://github.com/Miqell24/thessaloniki-bus-map) — same
pipeline and same visual system, different city and feeds. The most routes of
the family, and the first with a mapped paratransit network.

## Data

Two GTFS feeds by **[Transport for Cairo (TfC)](https://transportforcairo.com/)**,
published on their [open data portal](https://data.transportforcairo.com/)
(fieldwork 2019–2023, road feed updated 2025-10):

- **Road transport** (document 88) — 1011 routes, all `route_type` 3. Agencies
  separate the worlds: CTA buses & minibuses, Mwasalat Misr and Green Bus are
  the *formal* network (navy); microbuses (P_O_14), tomnayas (P_B_8),
  cooperative minibuses (COOP) and boxes (BOX) are *paratransit* (amber, own
  toggle; shared corridors get a dashed amber overlay).
- **Cairo Metro** (document 87) — lines M1 and M2 with shapes, matched onto the
  OSM `railway=subway/rail` graph (M3 is not in the feed).

### Line codes

Hundreds of paratransit routes share one GTFS short name ("Microbus"), so the
pipeline re-keys lines: CTA routes keep their number (`1145`), CTA minibuses get
an `m` suffix (`112m`, avoiding the 13 CTA/CTA_M number collisions), Mwasalat
Misr / Green Bus keep their branded codes (`NA13`, `G1`), and paratransit
routes get compact per-agency codes assigned in `route_id` order — `X…`
microbus, `T…` tomnaya, `C…` cooperative minibus, `B…` box. The codes are this
map's invention (the routes have no public numbers) and are stable for a given
feed version.

## Features

- TfC GTFS matched onto the OSM road and rail network of Greater Cairo
  (2.0 M graph nodes, 310 k ways — 6th of October to 10th of Ramadan).
- KMK-style rendering: one stroke per roadway, aggregated line numbers rotated
  parallel to streets, half-disc stops turned to their side of the street,
  termini with boxed line badges that fuse into one complex when they would
  collide at the current zoom. Corridor labels cap at 12 line codes (+N tail) —
  some Cairo corridors carry over 100 routes.
- "Paper map" recolor of the base map: warm districts, green parks, real-blue
  water, pale-yellow motorways.
- Panel with independent toggles for the formal, paratransit and metro
  networks, and a clickable line list (click a line to see its route with all
  stops).
- Three PNG exports: current view (WYSIWYG), selected area (poster-grade), and
  the whole network as one print-quality poster.
- GTFS shapes.txt quality report (`npm run report` → `data/gtfs-gaps-report.md`).

## Requirements

- Node.js 20+ (no npm dependencies — everything is hand-rolled)
- `curl`, `unzip`, `python3` for the download step

## Usage

```bash
pipeline/download.sh                                  # TfC GTFS ×2 + Overpass OSM + MapLibre
node --max-old-space-size=8192 pipeline/build.mjs --all --tram all   # full build (~15 min)
node pipeline/serve.mjs 8133                          # http://localhost:8133
```

`build.mjs` accepts single lines for quick iterations: `node pipeline/build.mjs
1145 X101 --tram M1`.

## Live

**https://miqell24.github.io/cairo-bus-map/** — GitHub Pages from `main:/docs`.
