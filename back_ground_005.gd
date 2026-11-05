extends Sprite2D

var speed: float = 10

func _process(delta: float) -> void:
	position.x -= speed * delta
