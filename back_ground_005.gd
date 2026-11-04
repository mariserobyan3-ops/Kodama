extends Sprite2D

var speed: float = 5

func _process(delta: float) -> void:
	position.x -= speed * delta
