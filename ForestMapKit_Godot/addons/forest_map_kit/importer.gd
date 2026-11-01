@tool
class_name ForestMapKitImporter
extends RefCounted
## Forest Map Kit - builds Godot scenes from the files the Random Map Generator exports (see MAP_FORMAT.md, version 2).
##
## One map (map.json) becomes a Node2D scene:
##   Map (Node2D, y_sort_enabled, nearest texture filter)
##     Ground/Tile, Ground/Overlay   the two ground layers (Sprite2D, top-left at 0,0)
##     Under/<objects>              lying objects (logs, stumps, low rocks): always under actors
##     Objects/<objects>            standing objects, Y-sorted at their sort line; long objects as slices
##     Blockers (StaticBody2D)      one CollisionPolygon2D per blocking polygon (feet, parts)
##     Water (StaticBody2D)         one CollisionPolygon2D per water outline
## A world (world.json) becomes one scene per cell plus World.tscn (script forest_world.gd) that loads the cells and
## carries the player across the edges.
##
## Units: 1 Godot unit = 1 map pixel; a person is about 63 px tall (37 px per metre). Every number is read as exported.

const FORMAT_MAP := "forest-map-kit-map"
const FORMAT_WORLD := "forest-map-kit-world"
const WORLD_SCRIPT := "res://addons/forest_map_kit/forest_world.gd"


## Entry point of the menu: builds whatever the file is. Returns the path of the scene to open, or "" on failure.
static func import_any(json_path: String, out_dir: String) -> String:
	var data := load_json(json_path)
	if data.is_empty():
		return ""
	var kit_root := find_kit_root(json_path)
	if kit_root.is_empty():
		push_error("Forest Map Kit: the ForestMapKit folder (with tiles/, overlays/, objects/) was not found above " + json_path + ". Copy the whole kit folder into the project and put the exported files inside or beside it.")
		return ""
	match data.get("format", ""):
		FORMAT_MAP:
			return import_map(json_path, data, kit_root, out_dir)
		FORMAT_WORLD:
			return import_world(json_path, data, kit_root, out_dir)
	push_error("Forest Map Kit: " + json_path + " is not a map.json or world.json of the Random Map Generator (format = " + str(data.get("format", "")) + ").")
	return ""


static func import_map(json_path: String, data: Dictionary, kit_root: String, out_dir: String) -> String:
	var scene_name := _scene_name_for(json_path, data)
	var root := build_map(data, kit_root, scene_name)
	var path := out_dir.path_join(scene_name + ".tscn")
	return path if save_scene(root, path) == OK else ""


static func import_world(json_path: String, data: Dictionary, kit_root: String, out_dir: String) -> String:
	var world_name := json_path.get_base_dir().get_file()
	if world_name.is_empty() or world_name == "res:":
		world_name = "world"
	var dir := out_dir.path_join(world_name)
	var cells: Dictionary = data.get("cells", {})
	var world_cells := {}
	for cell_name in cells.keys():
		var c: Dictionary = cells[cell_name]
		var map_path := json_path.get_base_dir().path_join(String(c.get("folder", "cells/" + cell_name + "/")).path_join("map.json"))
		var map_data := load_json(map_path)
		if map_data.is_empty():
			push_error("Forest Map Kit: cell " + cell_name + " has no readable map.json at " + map_path)
			continue
		var root := build_map(map_data, kit_root, "Cell" + cell_name)
		var scene_path := dir.path_join("Cell" + cell_name + ".tscn")
		if save_scene(root, scene_path) != OK:
			continue
		var neighbours := {}
		var nb: Dictionary = c.get("neighbours", {})
		for side in ["N", "E", "S", "W"]:
			var n = nb.get(side, null)
			neighbours[side] = "" if n == null else String(n)
		world_cells[cell_name] = {"scene": scene_path, "neighbours": neighbours, "col": int(c.get("col", 0)), "row": int(c.get("row", 0))}
	if world_cells.is_empty():
		return ""
	var world := Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true                      # the cell's objects and your player sort together (nested Y-sort)
	world.set_script(load(WORLD_SCRIPT))
	world.set("cells", world_cells)
	world.set("cell_size", int(data.get("cellSize", 1254)))
	var first := ""
	for cell_name in world_cells.keys():             # start at the top-left filled cell
		var wc: Dictionary = world_cells[cell_name]
		if first.is_empty() or wc["row"] < world_cells[first]["row"] or (wc["row"] == world_cells[first]["row"] and wc["col"] < world_cells[first]["col"]):
			first = cell_name
	world.set("start_cell", first)
	var world_path := dir.path_join("World.tscn")
	return world_path if save_scene(world, world_path) == OK else ""


## The map scene. Everything is placed in map pixels; the picture of a standing object hangs from its sort line so that
## Godot's Y-sort (which sorts by the node's position.y) draws it in the right order against actors standing at their feet.
static func build_map(data: Dictionary, kit_root: String, scene_name: String) -> Node2D:
	var root := Node2D.new()
	root.name = scene_name
	root.y_sort_enabled = true
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.set_meta("forest_map_kit", {"format": data.get("format", ""), "version": data.get("version", 0), "cell": data.get("cell", ""),
		"size": data.get("size", [1254, 1254]), "seed": data.get("seed", ""), "theme": data.get("theme", ""),
		"roadsAtEdges": data.get("roadsAtEdges", {}), "noGo": data.get("noGo", [])})

	var ground := Node2D.new()
	_node(ground, "Ground", root, root)
	var g: Dictionary = data.get("ground", {})
	_sprite(_texture(kit_root, g.get("tile", "")), Vector2.ZERO, "Tile", ground, root)
	_sprite(_texture(kit_root, g.get("overlay", "")), Vector2.ZERO, "Overlay", ground, root)

	var under := Node2D.new()
	_node(under, "Under", root, root)
	var objects := Node2D.new()
	_node(objects, "Objects", root, root)
	objects.y_sort_enabled = true
	var blockers := StaticBody2D.new()
	_node(blockers, "Blockers", root, root)
	var water := StaticBody2D.new()
	_node(water, "Water", root, root)

	for o in data.get("objects", []):
		var obj: Dictionary = o
		var tex := _texture(kit_root, obj.get("file", ""))
		if tex == null:
			continue
		var pos := Vector2(float(obj.get("x", 0)), float(obj.get("y", 0)))
		var nm := String(obj.get("file", "object")).get_file().get_basename()
		var sort_y := float(obj.get("sortY", pos.y + float(obj.get("h", 0))))
		if obj.get("collision", "none") == "ground":
			_sprite(tex, pos, nm, under, root)
		elif obj.has("pieces") and not (obj["pieces"] as Array).is_empty():
			var h := float(obj.get("h", tex.get_height()))
			var k := 0
			for p in obj["pieces"]:
				var piece: Dictionary = p
				var s := _sprite(tex, Vector2(float(piece.get("x", pos.x)), float(piece.get("sortY", sort_y))), nm + "_" + str(k), objects, root)
				s.offset = Vector2(0, pos.y - float(piece.get("sortY", sort_y)))
				s.region_enabled = true
				s.region_rect = Rect2(float(piece.get("srcX", 0)), 0, float(piece.get("srcW", 1)), h)
				k += 1
		else:
			var s := _sprite(tex, Vector2(pos.x, sort_y), nm, objects, root)
			s.offset = Vector2(0, pos.y - sort_y)             # the picture's top-left stays at (x, y); the node sits on the sort line
		if obj.has("feet"):
			_add_polygon(blockers, obj["feet"], root)
		for part in obj.get("parts", []):
			_add_polygon(blockers, part, root)

	var w = data.get("water", null)
	if w is Dictionary:
		for poly in w.get("polygons", []):
			_add_polygon(water, poly, root)
	return root


# ---------------------------------------------------------------------------------------------- helpers

static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Forest Map Kit: file not found: " + path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_error("Forest Map Kit: not valid JSON: " + path)
		return {}
	return parsed


## The ForestMapKit folder: the nearest folder above the file that holds tiles/ and data/kit.json.
static func find_kit_root(from_path: String) -> String:
	var dir := from_path.get_base_dir()
	var last := ""
	while dir != last:
		if DirAccess.dir_exists_absolute(dir.path_join("tiles")) and FileAccess.file_exists(dir.path_join("data/kit.json")):
			return dir
		last = dir
		dir = dir.get_base_dir()
	return ""


static func _texture(kit_root: String, rel: String) -> Texture2D:
	if rel.is_empty():
		return null
	var p := kit_root.path_join(rel)
	if not ResourceLoader.exists(p):
		push_error("Forest Map Kit: picture not found or not imported yet: " + p + " (let the editor finish importing the kit folder, then run the import again).")
		return null
	return load(p) as Texture2D


static func _node(n: Node, nm: String, parent: Node, root: Node) -> Node:
	n.name = nm
	parent.add_child(n, true)
	n.owner = root
	return n


static func _sprite(tex: Texture2D, pos: Vector2, nm: String, parent: Node, root: Node) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.texture = tex
	s.position = pos
	_node(s, nm, parent, root)
	return s


## One blocking polygon. Clipper (offset 0) cleans rings that touch themselves at a corner, which a CollisionPolygon2D
## cannot triangulate; it may return several rings, each becomes its own CollisionPolygon2D.
static func _add_polygon(body: StaticBody2D, pts: Array, root: Node) -> void:
	var poly := PackedVector2Array()
	for p in pts:
		poly.append(Vector2(float(p[0]), float(p[1])))
	if poly.size() < 3:
		return
	var rings: Array = Geometry2D.offset_polygon(poly, 0.0)
	if rings.is_empty():
		rings = [poly]
	for ring in rings:
		if ring.size() < 3:
			continue
		var c := CollisionPolygon2D.new()
		c.polygon = ring
		body.add_child(c, true)
		c.owner = root


static func save_scene(root: Node, path: String) -> Error:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Forest Map Kit: could not pack the scene " + path + " (error " + str(err) + ")")
		root.free()
		return err
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("Forest Map Kit: could not save " + path + " (error " + str(err) + ")")
	root.free()
	return err


static func _scene_name_for(json_path: String, data: Dictionary) -> String:
	var cell := String(data.get("cell", ""))
	var base := json_path.get_file().get_basename()
	if base == "map" and not cell.is_empty():
		base = "Cell" + cell
	return base.validate_node_name().replace(" ", "_")
