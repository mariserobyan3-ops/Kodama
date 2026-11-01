extends Node2D
## Forest Map Kit example: builds the sample 2 x 2 world from the kit (once), then lets you walk it.
## Needs the ForestMapKit folder inside this project (res://ForestMapKit).

const KIT := "res://ForestMapKit"
const WORLD_JSON := KIT + "/examples/html/sample/world.json"
const OUT := "res://forest_maps"
const PLAYER := preload("res://Player.tscn")


func _ready() -> void:
	var info: Label = $UI/Info
	if not DirAccess.dir_exists_absolute(KIT + "/tiles"):
		info.text = "Copy the ForestMapKit folder into this project (next to project.godot), let Godot import its pictures, then press Play again."
		return
	var world_scene := OUT + "/sample/World.tscn"
	if not ResourceLoader.exists(world_scene):
		info.text = "Building the sample world from " + WORLD_JSON + " ..."
		world_scene = ForestMapKitImporter.import_any(WORLD_JSON, OUT)
		if world_scene.is_empty():
			info.text = "The import failed: see the Output panel. Is the kit folder fully imported?"
			return
	var world: Node2D = load(world_scene).instantiate()
	var player := PLAYER.instantiate()
	player.name = "Player"
	world.add_child(player)                              # the player is a child of World: it Y-sorts with the map's objects
	world.set("player_path", NodePath("Player"))
	world.connect("cell_entered", func(cell_name: String): info.text = "Cell " + cell_name + "  -  arrows / WASD to walk, walk off an edge to enter the next map")
	add_child(world)
