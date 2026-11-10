extends Node

var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.bus = "Master"
	add_child(player)

func play_track(stream: AudioStream, volume_db: float = -10.0) -> void:
	if player.stream == stream and player.playing:
		return  # уже играет этот трек, не перезапускаем
	player.stream = stream
	player.volume_db = volume_db
	player.play()

func fade_out(duration: float) -> void:
	if not player.playing:
		return
	var t := create_tween()
	t.tween_property(player, "volume_db", -60.0, duration)
	await t.finished
	player.stop()
