extends CanvasLayer

@onready var fade: ColorRect = $Fade

func _ready() -> void:
	fade.modulate.a = 0.0

func change_scene(path: String) -> void:
	fade.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tween2 := create_tween()
	tween2.tween_property(fade, "modulate:a", 0.0, 0.5)
