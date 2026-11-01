class_name ForestWorld
extends Node2D
## Forest Map Kit - a world of maps at run time. Built by the importer as World.tscn; add it to your game scene, then add
## your player (a CharacterBody2D whose position is its feet) as a child of this node and point "player_path" at it.
## The current cell scene is instanced as the first child, so its objects Y-sort together with the player (nested Y-sort).
## When the player walks off an edge, the neighbour cell is loaded and the player appears at the same place on its
## opposite edge. An edge with no neighbour is a wall.

## cell name -> { "scene": String (path of the cell scene), "neighbours": { "N": name or "", "E", "S", "W" }, "col", "row" }
@export var cells: Dictionary = {}
@export var cell_size: int = 1254
@export var start_cell: String = ""
@export var player_path: NodePath

signal cell_entered(cell_name: String)

var current: String = ""
var map: Node2D = null
var _player: Node2D = null


func _ready() -> void:
	process_physics_priority = 1000                  # run after the player's own movement in each physics step: edges checked on the final position
	_player = get_node_or_null(player_path) as Node2D
	if not start_cell.is_empty():
		enter(start_cell, Vector2(cell_size / 2.0, cell_size / 2.0))


## Load a cell and put the player at player_pos (in the cell's pixels).
func enter(cell_name: String, player_pos: Vector2) -> void:
	if not cells.has(cell_name):
		push_error("ForestWorld: unknown cell " + cell_name)
		return
	if map != null:
		map.queue_free()
		map = null
	var packed: PackedScene = load(cells[cell_name]["scene"])
	if packed == null:
		push_error("ForestWorld: cannot load " + str(cells[cell_name]["scene"]))
		return
	map = packed.instantiate() as Node2D
	add_child(map)
	move_child(map, 0)
	current = cell_name
	if _player != null:
		_player.position = player_pos
		await get_tree().physics_frame                   # the cell's colliders exist for queries from the next physics step
		if is_instance_valid(_player) and current == cell_name:
			_player.position = _free_spot(player_pos)
	cell_entered.emit(cell_name)


## The nearest spot where a body of radius 14 px overlaps nothing (a pond or a tree may sit exactly where the player should start).
func _free_spot(pos: Vector2) -> Vector2:
	var space := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.collide_with_areas = false
	if _player is CollisionObject2D:
		q.exclude = [(_player as CollisionObject2D).get_rid()]
	var free := func(p: Vector2) -> bool:
		q.transform = Transform2D(0.0, to_global(p))
		return space.intersect_shape(q, 1).is_empty()
	if free.call(pos):
		return pos
	for d in range(8, int(cell_size), 8):
		for a in range(16):
			var p: Vector2 = pos + Vector2(cos(a * PI / 8.0), sin(a * PI / 8.0)) * d
			if p.x > 20 and p.y > 20 and p.x < cell_size - 20 and p.y < cell_size - 20 and free.call(p):
				return p
	return pos


func _physics_process(_delta: float) -> void:
	if _player == null or map == null or current.is_empty():
		return
	var p := _player.position
	var side := ""
	if p.x < 0:
		side = "W"
	elif p.x >= cell_size:
		side = "E"
	elif p.y < 0:
		side = "N"
	elif p.y >= cell_size:
		side = "S"
	if side.is_empty():
		return
	var next: String = str(cells[current]["neighbours"].get(side, ""))
	if next.is_empty():
		_player.position = p.clamp(Vector2.ZERO, Vector2(cell_size - 1, cell_size - 1))     # the edge of the world: a wall
		return
	match side:
		"W":
			p.x += cell_size
		"E":
			p.x -= cell_size
		"N":
			p.y += cell_size
		"S":
			p.y -= cell_size
	enter(next, p)
