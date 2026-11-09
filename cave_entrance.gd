extends Area2D

var triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if triggered or body.name != "Player":
		return

	triggered = true
	get_tree().change_scene_to_file.call_deferred("res://cave.tscn")
