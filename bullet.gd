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

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		area.queue_free()
		queue_free()
		
		var main = get_tree().root.get_node_or_null("Main")
		if main and main.has_method("add_score"):
			main.add_score(10)
	
	elif area.is_in_group("ground_enemies"):
		if area.has_method("take_damage"):
			area.take_damage()
		else:
			area.queue_free()
		queue_free()
		
		var main = get_tree().root.get_node_or_null("Main")
		if main and main.has_method("add_score"):
			main.add_score(5)
