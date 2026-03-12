extends Area2D

@export var speed: float = 260.0
@export var life: float = 2.0

var dir: int = 1

func set_dir(d: int) -> void:
	dir = d

func _process(delta: float) -> void:
	position.x += float(dir) * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()
