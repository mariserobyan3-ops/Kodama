extends Control

@export var credit_lines: Array[String] = [
	"Kodama gave the forest its last light.",
	"Not a sprout, not a miracle, but himself.",
	"His spirit went into the roots, and the roots held.",
	"So the forest could rest, and the people could live in peace.",
	"Remember him when you pass a tree.",
]
@export var credit_voices: Array[AudioStream] = []
@export var credit_time: float = 6.0
@export var planting_time: float = 1.0
@export var bloom_time: float = 40.0
@export var fade_time: float = 2.0

@onready var bloom: TextureRect = $BloomingForest
@onready var credits: Label = $Credits
@onready var fade: ColorRect = $Fade
@onready var voice: AudioStreamPlayer = $Voice

func _ready() -> void:
	bloom.modulate.a = 0.0
	fade.modulate.a = 0.5
	credits.modulate.a = 0.0
	_run_ending()

func _run_ending() -> void:
	await _play_credits()
	get_tree().change_scene_to_file("res://menu.tscn")

func _play_credits() -> void:
	await get_tree().create_timer(planting_time).timeout
	_fade_node(bloom, 1.0, bloom_time)

	for i in credit_lines.size():
		credits.text = credit_lines[i]
		var dur := credit_time
		if i < credit_voices.size() and credit_voices[i] != null:
			voice.stream = credit_voices[i]
			voice.play()
			dur = credit_voices[i].get_length()

		_fade_node(credits, 1.0, 0.8)
		await get_tree().create_timer(0.8).timeout

		if i == credit_lines.size() - 1:
			_fade_node(fade, 1.0, fade_time)

		await get_tree().create_timer(max(dur - 1.6, 0.1)).timeout
		_fade_node(credits, 0.0, 0.8)
		await get_tree().create_timer(0.8).timeout

func _fade_node(node: CanvasItem, target: float, duration: float) -> void:
	var t := create_tween()
	t.tween_property(node, "modulate:a", target, max(duration, 0.01))
