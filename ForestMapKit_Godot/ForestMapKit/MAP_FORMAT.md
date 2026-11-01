# Forest Map Kit — map file format (version 2)

One format for every importer (HTML/JS, Godot, Unity). A single map is one `*.json` file; a world export is a `.zip` with `world.json` plus `cells/<A1>/map.json` per cell, every `map.json` in this same format. All numbers are **map pixels** with the origin at the **top-left**, y growing **down**. A person is about 63 px tall (`pixelsPerMetre` = 37). The pictures the file names live in the kit folder (`tiles/`, `overlays/`, `objects/`); copy that folder into your project and resolve the paths against it.

## map.json

```
{
  "format": "forest-map-kit-map", "version": 2, "generator": "Forest Map Kit 2.0",
  "cell": "A1",                      // only inside a world export
  "seed": "817407", "theme": "pond",
  "size": [1254, 1254], "pixelsPerMetre": 37,
  "ground": { "tile": "tiles/forest_tile_03_winding-earth.png", "overlay": "overlays/forest_overlay_16.png" },
  "roadsAtEdges": { "N": [], "E": [], "S": [[627, 110]], "W": [] },
  "water": { "polygons": [[[x, y], ...], ...], "mask": { "scale": 4, "n": 313, "rows": [...] } } | null,
  "noGo": [{ "kind": "mound", "cx": 527, "cy": 627, "rx": 339, "ry": 201 }, ...],
  "objects": [ { ...see below... }, ... ]
}
```

### Drawing the ground
Draw `ground.tile` at (0, 0), then `ground.overlay` on top of it at (0, 0). Both are 1254 × 1254; the overlay is transparent where the tile shows through. That is the whole ground: there is no pre-composed picture.

### Objects (listed in drawing order)
```
{
  "file": "objects/pine/pine_004.png", "folder": "pine", "shape": "pine",
  "x": 812, "y": 103, "w": 170, "h": 300,          // top-left of the picture in the map, and its size
  "footX": 897, "footY": 403,                        // where it touches the ground (the sprite's pivot)
  "collision": "standing" | "ground" | "none",
  "sortY": 390,                                      // depth-sort line (standing objects)
  "feet": [[x, y], ...],                             // blocking polygon (absent when collision is "none")
  "parts": [[[x, y], ...], ...],                     // optional: extra blocking polygons inside a group picture
  "pieces": [{ "srcX": 0, "srcW": 32, "x": 812, "sortY": 395 }, ...],   // optional: a long object split into slices
  "autoCollision": true                              // optional: the collision was guessed (buyer's own art)
}
```
- **Pivot.** Put the sprite's pivot at (`footX` − `x`, `footY` − `y`) in picture pixels, i.e. place the sprite so that its pivot lands on (`footX`, `footY`) in the map. (For Unity: pivot in normalized units = ((footX − x) / w, 1 − (footY − y) / h).)
- **Depth.** Objects with `collision: "ground"` are drawn **under** every actor and every other object. All other objects and the actors sort by one line: an object by its `sortY`, an actor by its feet y. Smaller y is drawn first (behind). The list is already in that order, so a renderer that keeps the order and only inserts actors is correct.
- **Blocking.** `feet` (and every polygon in `parts`) blocks movement; it is the object's footprint, not its picture. `collision: "none"` objects never block.
- **Pieces.** A cliff, a cave or a fallen log is long: one sort line is wrong for an actor walking along it. `pieces` splits its picture into vertical slices: slice *k* is the picture's columns `srcX … srcX + srcW` (full height), drawn at map x = `x` (same `y` as the object), sorted at its own `sortY`. Use the pieces instead of the whole sprite when you can; otherwise draw the whole sprite at the object's `sortY`.
- `shape` says what the game treats it as (pine, broadleaf-tree, rock, log, cave, cliff, stump, …); `folder` is the kit folder it came from.

### Water
`water.polygons` are the outlines of the blocked water (ponds, streams) in map pixels, one ring per region, simplified to about 3 px. An island inside a pond is not cut out: it stays inside the ring. `water.mask` is the same water as a grid: `n × n` cells of `scale` px, `rows[j]` = run lengths `[startCell, length, startCell, length, ...]`. Use the polygons for engine colliders, the mask for pixel tests. `null` when the ground has no water.

### No-go areas
`noGo` are ellipses (centre `cx, cy`, radii `rx, ry`) the generator kept free: a mound, baked bones, a fence. They do **not** block; they only mark painted features of the overlay.

### Roads
`roadsAtEdges.N/E/S/W` list where a painted road meets that edge: `[centre, width]` in px along the edge. Neighbouring maps continue the road there. (The overlays shipped in this version carry no roads; a buyer's own overlay may.)

## world.json
```
{
  "format": "forest-map-kit-world", "version": 2, "generator": "Forest Map Kit 2.0",
  "cols": 5, "rows": 5, "cellSize": 1254, "pixelsPerMetre": 37, "outerEdgesBlocked": true,
  "cells": { "A1": { "col": 0, "row": 0, "folder": "cells/A1/", "neighbours": { "N": null, "E": "B1", "S": "A2", "W": null },
                     "roadsAtEdges": {...}, "tile": "...", "overlay": "...", "theme": "...", "seed": "..." }, ... },
  "project": { ... the tool's own project, to reopen the world in the tool ... }
}
```
Travel: when an actor leaves a map across an edge, load the neighbour named in `neighbours` and put the actor at the same place on the opposite edge (east edge x = 1254 → neighbour x = 0, same y). A `null` neighbour is a wall. Every `cells/<name>/` folder holds `map.json` (this format), and when exported with pictures `map.png` (ground + objects), `objects.png` (objects only, transparent) and `collision.png` (white = blocked: feet, parts and water).

## kit.json (inside the kit's data/ folder)
Importers may also read the kit itself: `tiles/<file>: {}`, `overlays/<file>: { avoid, tags, edges, water, cells }`, `objects/<file>: { foot: [x, y], size: [w, h], collision: { kind, shape, feet, sortY, strips, parts } }` — the same fields as above but in the **picture's own pixels** (feet/parts/strips relative to the PNG's top-left; `strips` = `[x, width, sortY]`).
