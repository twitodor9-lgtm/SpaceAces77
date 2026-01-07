extends Area2D
@export var speed: float = 50.0
var _velocity: Vector2 = Vector2.ZERO
  
func _ready() -> void:
	add_to_group("enemy_bullets")
	# אחרי 2.5 שניות הכדור נעלם
	await get_tree().create_timer(2.5).timeout
	queue_free()

# הפונקציה שהטנק / המטוס קוראים אליה כדי להגדיר כיוון ומהירות
func setup(direction: Vector2, custom_speed: float = -1.0) -> void:
	direction = direction.normalized()
	if custom_speed > 0.0:
		_velocity = direction * custom_speed
	else:
		_velocity = direction * speed
	
	# ⭐ הכדור מסתובב לכיוון התנועה שלו
	rotation = direction.angle()

func _process(delta: float) -> void:
	position += _velocity * delta
	var r := get_viewport_rect()
	if global_position.x < -200 or global_position.x > r.size.x + 200 or global_position.y < -200 or global_position.y > r.size.y + 200:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.name == "Player" or area.is_in_group("player"):
		if area.has_method("_on_area_entered"):
			area._on_area_entered(self)
		queue_free()
