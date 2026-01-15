extends Area2D

@export var speed: float = 650.0
@export var damage: int = 3
@export var life_time: float = 3.0

func _ready() -> void:
	# מחיקת מטאור אוטומטית אחרי זמן
	get_tree().create_timer(life_time).timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)

	connect("area_entered", _on_area_entered)


func _process(delta: float) -> void:
	# נפילה אלכסונית קלה
	position += Vector2(randf_range(-40, 40), speed) * delta


func _on_area_entered(area: Area2D) -> void:
	# פוגע בכל אויב שיש לו take_damage
	if area.has_method("take_damage"):
		area.take_damage(damage)

	# אפשר להוסיף אפקט פגיעה כאן
	queue_free()
