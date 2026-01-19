extends Area2D

@export var speed: float = 650.0
@export var damage: int = 3
@export var drift_x: float = 40.0

var velocity: Vector2

func _ready() -> void:
	var x_drift := randf_range(-drift_x, drift_x)
	velocity = Vector2(x_drift, speed)

	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position += velocity * delta

	if global_position.y > get_viewport_rect().size.y + 300:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var target: Node = area

	# אם פגענו בהיטבוקס – נעלה לאבא
	while target and not target.has_method("take_damage"):
		target = target.get_parent()

	if target and target.has_method("take_damage"):
		target.take_damage(damage)

	queue_free()
