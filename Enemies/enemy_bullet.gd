extends Area2D

@export var speed: float = 200.0
@export var life_time: float = 2.0
@export var deflected_damage: int = 5

var _velocity: Vector2 = Vector2.ZERO
var _deflected: bool = false

func _ready() -> void:
	add_to_group("enemy_bullets")
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	await get_tree().create_timer(life_time).timeout
	if is_instance_valid(self):
		queue_free()

func setup(direction: Vector2, custom_speed: float = -1.0) -> void:
	var s := speed if custom_speed <= 0.0 else custom_speed
	_velocity = direction.normalized() * s
	rotation = _velocity.angle()

func deflect_from(point: Vector2, speed_mult: float = 1.0, spread_deg: float = 0.0) -> void:
	_deflected = true

	var n := global_position - point
	if n.length() < 0.001:
		n = Vector2.LEFT
	n = n.normalized()

	_velocity = _velocity.bounce(n)
	if _velocity.length() < 1.0:
		_velocity = n * maxf(speed, 80.0)

	_velocity *= maxf(speed_mult, 1.0)

	if absf(spread_deg) > 0.001:
		var ang := deg_to_rad(randf_range(-spread_deg, spread_deg))
		_velocity = _velocity.rotated(ang)

	rotation = _velocity.angle()

	# להפוך ל"כדור ידידותי" שפוגע באויבים
	collision_layer = 16
	collision_mask = 4

	remove_from_group("enemy_bullets")
	add_to_group("player_bullets_deflected")

func _process(delta: float) -> void:
	position += _velocity * delta

func _on_area_entered(area: Area2D) -> void:
	if not is_instance_valid(area):
		return

	if _deflected:
		if area.has_method("take_damage") and (area.is_in_group("enemies") or area.is_in_group("ground_enemies") or area.is_in_group("air_enemies")):
			area.call("take_damage", deflected_damage)
			queue_free()
		return

	# כדור אויב - אם פגע בשחקן -> נעלם (השחקן מוריד חיים בצד שלו)
	if area.is_in_group("player") or area.is_in_group("Player") or area.name == "Player":
		queue_free()
