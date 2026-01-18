extends Area2D

@export var speed: float = 650.0
@export var damage: int = 3
@export var life_time: float = 3.0

var velocity: Vector2


func _ready() -> void:
	# ⭐ כיוון אלכסוני נקבע פעם אחת בלבד
	var x_drift := randf_range(-120.0, 120.0)
	velocity = Vector2(x_drift, speed)

	# מחיקה אוטומטית אחרי זמן
	get_tree().create_timer(life_time).timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)

	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	position += velocity * delta


func _on_area_entered(area: Area2D) -> void:
	# פוגע רק באויבים אמיתיים
	if area.is_in_group("enemies") or area.is_in_group("ground_enemies"):
		if area.has_method("take_damage"):
			area.take_damage(damage)

		queue_free()
