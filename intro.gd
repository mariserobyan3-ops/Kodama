extends Control

@export var next_scene: String = "res://level.tscn"
@export var line_time: float = 4.0
@export var fade_time: float = 1.2
@export var voice_lines: Array[AudioStream] = []
@export var pause_between: float = 0.8
@export var music_stream: AudioStream
@export var music_volume_db: float = -10.0
@export var music_fade_out: float = 3.0

@onready var story: Label = $StoryLabel
@onready var voice: AudioStreamPlayer = $Voice

var lines: Array[String] = [
	"Once, the forest sang. Every root listened.",
	"The spirits lived in the bark, and they kept the cold light burning.",
	"Then the people stopped believing in miracles.",
	"The songs went silent. The roots forgot the sun.",
	"Only Kodama heard the silence, and went looking.",
]

var skipping := false

func _ready() -> void:
	story.modulate.a = 0.0
	if music_stream:
		MusicManager.play_track(music_stream, music_volume_db)
	_play_sequence()

func _play_sequence() -> void:
	for i in lines.size():
		if skipping:
			return
		story.text = lines[i]

		var duration := line_time
		if i < voice_lines.size() and voice_lines[i] != null:
			voice.stream = voice_lines[i]
			voice.play()
			duration = voice_lines[i].get_length()

		var t := create_tween()
		t.tween_property(story, "modulate:a", 1.0, fade_time)
		await t.finished

		await get_tree().create_timer(max(duration - fade_time * 2, 0.0)).timeout
		if skipping:
			return
		t = create_tween()
		t.tween_property(story, "modulate:a", 0.0, fade_time)
		await t.finished
		await get_tree().create_timer(pause_between).timeout

	_go_to_level()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_to_level()

func _go_to_level() -> void:
	if skipping:
		return
	skipping = true
	voice.stop()
	get_tree().change_scene_to_file(next_scene)
