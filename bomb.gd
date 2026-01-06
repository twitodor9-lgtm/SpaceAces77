extends Area2D

@export var fall_speed: float = 400.0      # מהירות נפילה ישר למטה

func _ready() -> void:
	add_to_group("bombs")
	await get_tree().create_timer(5.0).timeout
	queue_free()


func _process(delta: float) -> void:
	# תנועה ישרה למטה במסך (ציר Y גלובלי)
	global_position.y += fall_speed * delta
	
	var screen_size = get_viewport_rect().size
	if global_position.y > screen_size.y + 100:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") or area.is_in_group("ground_enemies"):
		area.queue_free()
		queue_free()
		
		var main = get_tree().root.get_node_or_null("Main")
		if main and main.has_method("add_score"):
			main.add_score(25)
