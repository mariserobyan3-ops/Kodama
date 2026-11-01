# Forest Map Kit — Godot 4 edition

A ready Godot 4 project: the kit (`ForestMapKit/`: tiles, overlays, objects, the Random Map Generator, data) is already inside it, the importer addon is enabled, and a sample 2 × 2 world with a placeholder hero is wired up.

## Open and play
1. Godot 4.2 or newer → Project Manager → **Import** → pick `project.godot` in this folder → Edit. Wait for the pictures to import (a few hundred PNGs, one time).
2. Press Play. The first run builds `res://forest_maps/sample/` from `ForestMapKit/examples/html/sample/world.json` with the addon, then loads it. Arrows / WASD walk; walk off an edge to enter the next map; the outer edges are walls.

## Make your own maps
1. Open `ForestMapKit/Random Map Generator.html` in a browser (Chrome, Edge, Firefox), click **Open kit folder** and pick `ForestMapKit`. Generate a map, or build a world on the **World grid** tab, and export (**Object list JSON** or **Export world (.zip)**).
2. Put the exported files inside this project **under `ForestMapKit/`** (for example `ForestMapKit/exports/my_world/`, unzipped). The importer finds the kit's pictures by looking upward for the folder with `tiles/`.
3. Project → Tools → **Forest Map Kit: Import map or world…**, pick `map.json` or `world.json`. Scenes appear in `res://forest_maps/`: `<name>.tscn` for one map, or `<world>/World.tscn` + `Cell<A1>.tscn`… for a world.
4. For a world: add `World.tscn` to your scene, add your player (a `CharacterBody2D` whose position is its **feet**) as a **child of World**, set World's **Player Path** to it and its **Start Cell**. `Main.gd` shows exactly this.

## What you get
```
Map (Node2D, Y-sort, nearest filter)
  Ground/Tile, Ground/Overlay    the two ground layers, Sprite2D at (0, 0)
  Under/…                        lying objects (logs, stumps, low rocks): always under actors
  Objects/…                      standing objects; node position = (x, sortY), the picture hangs from it,
                                 long objects (caves, fallen logs, cliffs) are split into slices
  Blockers (StaticBody2D)        CollisionPolygon2D per blocking polygon (collision layer 1)
  Water (StaticBody2D)           CollisionPolygon2D per pond / stream outline (collision layer 1)
```
- Units: 1 unit = 1 map pixel. A person is about 63 px tall (37 px per metre). Do not scale the sprites.
- Your actors sort with the map's objects when they share a Y-sorted parent (World is one): behind a tree when their feet are above the tree's sort line, in front when below.
- Change the collision layers of `Blockers` / `Water` if your game uses layers (for example water on layer 2 so arrows fly over it).

## Files to read
`Main.gd` (import once, instance World, add the player as its child), `Player.tscn` / `Player.gd` (a CharacterBody2D with its position at its feet and a Camera2D), `addons/forest_map_kit/` (`importer.gd`, `forest_world.gd`, `plugin.gd`), `ForestMapKit/MAP_FORMAT.md` (the exported file format), `ForestMapKit/README.txt` (the art and the generator).

Call `ForestMapKitImporter.import_any(json_path, "res://forest_maps")` from your own tool script to batch imports.
