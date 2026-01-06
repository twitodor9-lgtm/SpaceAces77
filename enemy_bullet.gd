extends Area2D

@export var speed: float = 200.0
@export var life_time: float = 2.0

var _velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("enemy_bullets")
	await get_tree().create_timer(life_time).timeout
	queue_free()


func setup(direction: Vector2, custom_speed: float = -1.0) -> void:
	var s := speed if custom_speed <= 0.0 else custom_speed
	_velocity = direction.normalized() * s
	rotation = _velocity.angle()


func _process(delta: float) -> void:
	position += _velocity * delta
