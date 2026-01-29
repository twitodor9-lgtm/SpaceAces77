extends Area2D

var speed = 800
var velocity = Vector2.ZERO

func _ready():
	velocity = Vector2(speed, 0).rotated(rotation)
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _process(delta):
	position += velocity * delta
	
	var screen_size = get_viewport_rect().size
	if position.x < -100 or position.x > screen_size.x + 100 or position.y < -100 or position.y > screen_size.y + 100:
		queue_free()

@export var damage: int = 1
@export var score_air: int = 10
@export var score_ground: int = 5

func _on_area_entered(area: Area2D) -> void:
	# מוצאים את היעד האמיתי (לפעמים ה-Area הוא ילד)
	var target: Node = area
	while target and not target.has_method("take_damage"):
		target = target.get_parent()

	var main := get_tree().root.get_node_or_null("Main")

	# --- אויבי אוויר / enemies ---
	if area.is_in_group("enemies"):
		if target:
			target.take_damage(damage)
		else:
			# fallback: אם אין take_damage (כמו שהיה לך קודם)
			area.queue_free()

		queue_free()

		if main and main.has_method("add_score"):
			main.add_score(score_air)
		return

	# --- אויבי קרקע / ground_enemies ---
	if area.is_in_group("ground_enemies"):
		if target:
			target.take_damage(damage)
		else:
			area.queue_free()

		queue_free()

		if main and main.has_method("add_score"):
			main.add_score(score_ground)
		return
