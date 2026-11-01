extends CharacterBody2D
## A placeholder hero: the node's position is its feet (that is what the map's Y-sort and the world's edge travel expect).

const SPEED := 260.0            # px per second; a person is about 63 px tall


func _physics_process(_delta: float) -> void:
	var d := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		d.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		d.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		d.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		d.y += 1
	velocity = d.normalized() * SPEED
	move_and_slide()
