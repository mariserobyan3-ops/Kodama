extends CharacterBody2D
const SPEED = 160.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var last_direction = "down"
func _physics_process(_delta):
	var direction = Input.get_vector(
		"ui_left", "ui_right",
		"ui_up", "ui_down"
	)
	velocity = direction * SPEED
	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			last_direction = "right" if direction.x > 0 else "left"
		else:
			last_direction = "down" if direction.y > 0 else "up"
		sprite.play("walk_" + last_direction)
	else:
		sprite.stop()
		sprite.frame = 0
	move_and_slide()
