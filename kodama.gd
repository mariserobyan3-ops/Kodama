extends CharacterBody2D

const SPEED = 180.0
const MAP_LEFT = -627.0
const MAP_TOP = -627.0
const MAP_RIGHT = 627.0
const MAP_BOTTOM = 627.0

@export var horizontal_only := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if horizontal_only:
		direction.y = 0.0

	velocity = direction * SPEED
	move_and_slide()
	global_position.x = clampf(global_position.x, MAP_LEFT, MAP_RIGHT)

	if direction != Vector2.ZERO:
		sprite.play("walk")
		if direction.x != 0.0:
			sprite.flip_h = direction.x < 0.0
	else:
		sprite.stop()
		sprite.frame = 0
