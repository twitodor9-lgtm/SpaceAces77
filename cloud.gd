extends Area2D

@export var speed: float = 20.0
@export var direction: Vector2 = Vector2.LEFT

func _ready() -> void:
	add_to_group("clouds")
	# חיבור סיגנלים
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _process(delta: float) -> void:
	position += direction.normalized() * speed * delta
	
	# אם יצא מהמסך - מחק
	var screen_width = get_viewport_rect().size.x
	if direction.x < 0 and global_position.x < -200:
		queue_free()
	elif direction.x > 0 and global_position.x > screen_width + 200:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("enter_cloud"):
			area.enter_cloud()


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("exit_cloud"):
			area.exit_cloud()
