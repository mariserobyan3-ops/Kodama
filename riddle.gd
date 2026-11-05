extends Node2D
var fragments = ["надежда ждёт", "Там, где жизнь уснула", "пробуждения"]
var answer = ["Там, где жизнь уснула", "надежда ждёт", "пробуждения"]
var picked = []
var buttons = []
var panel
var status_label
var hint_label
func _ready():
	var layer = CanvasLayer.new()
	add_child(layer)
	hint_label = Label.new()
	hint_label.text = "Нажмите E, чтобы разгадать загадку"
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
	for i in range(fragments.size()):
		var b = Button.new()
		b.text = fragments[i]
		b.position = Vector2(20 + i * 260, 120)
		b.size = Vector2(240, 60)
		b.pressed.connect(_on_button_pressed.bind(fragments[i], b))
		panel.add_child(b)
		buttons.append(b)
func _unhandled_input(event):
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
	picked = []
	for b in buttons:
		b.disabled = false
	status_label.text = "Расставь части фразы по порядку"
func _on_button_pressed(text, button):
	picked.append(text)
	button.disabled = true
	if picked.size() < answer.size():
		return
	if picked == answer:
		status_label.text = "Руны загораются! Проход открыт."
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://menu.tscn")
	else:
		status_label.text = "Не то. Попробуй ещё раз."
		await get_tree().create_timer(1.0).timeout
		start_puzzle()
