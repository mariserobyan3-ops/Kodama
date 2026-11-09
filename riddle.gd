extends Node2D

var fragments: Array = ["because it is rooted", "The wind bends the grass", "in the ground", "but the oak does not bend"]
var answer: Array = ["The wind bends the grass", "but the oak does not bend", "because it is rooted", "in the ground"]
var busy := false
var picked: Array = []
var buttons: Array = []
var panel: Panel
var status_label: Label
var hint_label: Label

func _ready():
	fragments.shuffle()

	var layer = CanvasLayer.new()
	add_child(layer)

	hint_label = Label.new()
	hint_label.text = "Press E to solve the riddle"
	hint_label.position = Vector2(21, 21)
	hint_label.add_theme_font_size_override("font_size", 20)
	layer.add_child(hint_label)

	panel = Panel.new()
	panel.position = Vector2(200, 150)
	panel.size = Vector2(800, 300)
	panel.visible = false
	layer.add_child(panel)

	status_label = Label.new()
	status_label.position = Vector2(21, 21)
	panel.add_child(status_label)

	# Сетка 2x2: у каждой кнопки свои координаты внутри панели
	var positions = [Vector2(20, 100), Vector2(420, 100), Vector2(20, 180), Vector2(420, 180)]
	for i in range(fragments.size()):
		var b = Button.new()
		b.text = fragments[i]
		b.position = positions[i]
		b.size = Vector2(360, 60)
		b.pressed.connect(_on_button_pressed.bind(fragments[i], b))
		panel.add_child(b)
		buttons.append(b)

func _unhandled_input(event):
	if busy:
		return
	if event.is_action_pressed("interact"):
		panel.visible = not panel.visible
		hint_label.visible = not panel.visible
		if panel.visible:
			start_puzzle()

func _physics_process(_delta):
	var k = $kodama
	var bg = $background
	var r = bg.get_rect()
	var top_left = bg.to_global(r.position)
	var bottom_right = bg.to_global(r.end)
	k.global_position = k.global_position.clamp(top_left, bottom_right)

func start_puzzle():
	busy = false
	picked = []
	for b in buttons:
		b.disabled = false
	if buttons.size() > 0:
		buttons[0].grab_focus()
	status_label.text = "Arrange the fragments in the correct order"

func _on_button_pressed(text, button):
	picked.append(text)
	button.disabled = true
	if picked.size() < answer.size():
		return

	busy = true
	if picked == answer:
		status_label.text = "Runes glow! The passage is open."
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://menu.tscn")
	else:
		status_label.text = "Not quite right. Try again."
		await get_tree().create_timer(1.0).timeout
		start_puzzle()
