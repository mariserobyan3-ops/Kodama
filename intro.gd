extends Control

@export var next_scene: String = "res://level.tscn"

@onready var story: Label = $StoryLabel
@onready var prompt: Label = $Prompt

var lines: Array[String] = [
	"Once, the forest was full of light.",
	"The old spirits sang to the roots, and the roots answered.",
	"Then people stopped believing in miracles.",
	"The spirits grew quiet, and the trees grew still.",
	"Only a small spirit, Kodama, woke beneath a dead oak.",
]

var index := 0
var skipping := false
var can_advance := false

func _ready() -> void:
	prompt.visible = false
	_show_line()

func _unhandled_input(event: InputEvent) -> void:
	if skipping:
		return
	if event.is_action_pressed("ui_cancel"):
		_go_to_level()
	elif can_advance and event.is_action_pressed("ui_accept"):
		_next_line()

func _show_line() -> void:
	can_advance = false
	prompt.visible = false
	story.text = lines[index]
	story.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(story, "modulate:a", 1.0, 1.2)
	t.tween_callback(_on_line_shown)

func _on_line_shown() -> void:
	can_advance = true
	prompt.visible = true

func _next_line() -> void:
	index += 1
	if index >= lines.size():
		_go_to_level()
	else:
		_show_line()

func _go_to_level() -> void:
	if skipping:
		return
	skipping = true
	get_tree().change_scene_to_file(next_scene)
