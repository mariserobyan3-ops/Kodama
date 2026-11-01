FOREST MAP KIT  v2.0  -  Tiny Realms
Top-down pixel-art style forest in layers: base ground tiles, ground overlays,
259 separate objects sorted by kind, and a random map generator that
builds a map from them: one base tile + one overlay + objects placed on top.

CONTENTS
  Random Map Generator.html   the tool (open it in Chrome, Edge or Firefox)
  tiles/                      4 base ground tiles, 1254 x 1254 px, opaque (grass and earth only)
  overlays/                   29 ground overlays, 1254 x 1254 px, transparent PNG: leaf litter,
                              earth patches, flower fields, ponds, a clearing - what makes
                              one map's ground different from the next
  objects/                    transparent PNG objects, one folder per kind:
  objects/big-rock/           6
  objects/bone/              12
  objects/branch/            12
  objects/broadleaf-tree/    13
  objects/bush/              20
  objects/camp/              12
  objects/cluster/            3
  objects/dead-tree/         22
  objects/fern-grass/         5
  objects/giant-mushroom/    17
  objects/landmark/           7
  objects/log/               18
  objects/mushroom/          15
  objects/pine/              15
  objects/reed/              15
  objects/rock/              14
  objects/stake/             22
  objects/stump/             24
  objects/totem/              7
  data/kit.json               foot point and collision of every object, no-go areas
                              (water, mounds, a fence) and water masks of every overlay
  MAP_FORMAT.md               the exported map.json / world.json format, for your own
                              importer (HTML, Godot, Unity)
  examples/html/              forest-map-runtime.js (canvas runtime: layers, depth sort,
                              collision, edge travel) + example.html + a sample 2 x 2 world.
                              Serve the ForestMapKit folder over http and open
                              examples/html/example.html; arrows / WASD walk, C shows collision.

EDITIONS
  The kit comes as three downloads with the same art and generator:
  - HTML:  this folder; use the generator, the JSON export and examples/html in any
           engine of your own.
  - Godot: a ready Godot 4 project with this folder inside it and the importer addon
           enabled (Project > Tools > "Forest Map Kit: Import map or world..."), with a
           sample world and a placeholder hero: open, press Play.
  - Unity: a ready Unity project with this folder inside Assets/ and the importer
           compiled from Assets/ForestMapKit/importers/unity (Tools > Forest Map Kit >
           Import map or world...), with a sample world and a placeholder hero.
  Your own maps go the same way in every edition: generate and export in the tool,
  then import.

  A ground = any tile + any overlay (4 x 29 = 116 different grounds). The
  overlays of this version carry no roads.

HOW TO USE THE GENERATOR
  1. Double-click "Random Map Generator.html".
  2. Click "Open kit folder" and pick this ForestMapKit folder. Your browser asks
     to allow reading it; nothing is uploaded, everything stays on your computer.
  3. Choose a base tile and an overlay (or Random for either), a theme and a
     density, then click Generate. Every click makes a new map. Each map has a
     seed number: type a seed and press Enter to rebuild exactly that map.
  4. Export: the full map as PNG, the object layer alone as transparent PNG,
     a JSON list of every object (file, position, foot point, collision) to rebuild
     the map in your engine with proper depth sorting, and a collision mask PNG.
     The JSON names the tile and the overlay the map was built on.

  The generator places trees, rocks, bushes, ferns, reeds, mushrooms, logs, stumps,
  branches, stakes, bones and totems. The camp/, cluster/ and landmark/ folders
  (tent, crates, fire pit, mixed groups, cliffs, caves, a rune stone) are extras
  for placing by hand.

WORLD GRID (the "World grid" tab)
  Build a world of maps: a grid of 3x3, 5x5, 7x7, 9x9 or any size up to 15x15, one
  generated map per cell (A1 is the top-left). When the player walks off a map's
  edge, your game loads the neighbour cell and puts the player at the same place
  on its opposite edge (leave east at y -> enter the east neighbour at x = 0, same y).
  - Click a cell: Generate here / Put current map here / Edit / Regenerate / Lock /
    Clear. Drag a cell onto another to swap them. "Fill empty cells" fills the rest.
  - Roads must go on across edges. Dots on the cells show each road end: green =
    joined, yellow = the neighbour has no road there, red = leads out of the world.
    "Auto-match roads" picks grounds (for unlocked cells) so every road joins.
    Where a road meets an edge, the generator keeps the edge free of objects.
  - The outer border is a wall unless "Roads may leave the world" is ticked.
  - "Walk test": walk a marker with arrows / WASD, blocked like in a game, and walk
    off an edge into the next map. Esc stops.
  - "Save project" keeps a small .world.json (every cell's recipe: same seed, same
    map) - the tool also remembers the last world in this browser.
  - "Export world (.zip)": world.json (grid, neighbours N/E/S/W of every cell, road
    ends) + overview.png + cells/<A1>/map.json, map.png, objects.png, collision.png.

  Edge travel in your game (pseudo code):
    if player.x >= 1254: cell = world.cells[cell].neighbours.E; player.x -= 1254
    if player.x <  0:    cell = ...neighbours.W;              player.x += 1254
    (same for y with S / N); a null neighbour is a wall: keep the player inside.

COLLISION (ready made, the same data as the game the art comes from)
  data/kit.json gives every object a "collision" entry, in the PNG's own pixels:
    kind    "standing"  trees, pines, tall rocks, tall stumps, posts, caves, fallen logs:
                        blocks; an actor whose feet are above (smaller y than) sortY is
                        drawn behind it, below it in front
            "ground"    low stumps, low rocks, fire pits: blocks; always drawn under actors
            "none"      bushes, grass, reeds, mushrooms, small rocks: walk through
    shape   what it is treated as: pine, broadleaf-tree, rock, log, cave, cliff, stump...
    feet    the polygon the object stands on (what blocks movement), not its picture;
            a cave or a fallen log blocks its whole body, not only its base
    sortY   the depth-sort line; "strips" (cliffs, caves, fallen logs): [x, width, sortY]
            per vertical strip, so a long wall or log sorts piece by piece
    parts   extra blocking polygons inside a group picture (the logs and rocks lying at
            the feet of a tree group): they block but do not sort
  Grounds with ponds or a stream carry a "water" mask (run lengths per row, 4 px per
  mask pixel) - water blocks too. The generator never places objects on each other's
  feet or in water. Export gives each placed object its feet (and parts) in map pixels,
  and "Collision mask PNG" (1254 x 1254, white = blocked) for any engine.

ADD YOUR OWN ART
  Drop more PNGs into any objects/<kind>/ folder, an opaque 1254 x 1254 picture into
  tiles/, or a transparent 1254 x 1254 picture into overlays/, and open the folder
  again: the tool uses them too. The foot point of a new object is the bottom
  centre of its pixels; its collision is guessed (an oval at its foot, marked
  "auto") - check it with "Show collision". Roads painted in an overlay (orange-
  brown earth bands reaching an edge) are found by the tool and kept free.

SCALE
  Art is drawn for a top-down RPG where a person is about 63 px tall
  (37 px per metre). Objects keep their real size; do not scale them separately.

Objects in the same scene sort by their foot point (larger y is drawn later).
The artwork was created with generative AI tools and then selected and edited
by the author; see LICENSE.txt.
