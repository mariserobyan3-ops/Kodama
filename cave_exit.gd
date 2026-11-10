extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "kodama":
		print("ВХОД В ВЫХОД: ", body.name)
		get_node("/root/Transition").change_scene("res://riddle.tscn")
