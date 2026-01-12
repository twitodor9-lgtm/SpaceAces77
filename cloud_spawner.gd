extends Node2D

@export var cloud_scene: PackedScene
@export var spawn_interval_min: float = 3.0
@export var spawn_interval_max: float = 11.0
@export var cloud_speed_min: float = 10.0
@export var cloud_speed_max: float = 50.0

var _spawn_timer: float = 5.0


func _ready() -> void:
	_spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)


func _process(delta: float) -> void:
	_spawn_timer -= delta
	
	if _spawn_timer <= 0.0:
		_spawn_cloud()
		_spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)


func _spawn_cloud() -> void:
	if cloud_scene == null:
		return
	
	var cloud = cloud_scene.instantiate()
	get_tree().current_scene.add_child(cloud)
	
	# מיקום אקראי בגובה
	var screen_size = get_viewport_rect().size
	var y_pos = randf_range(30, screen_size.y * 0.20)
	
	# מופיע מצד ימין
	cloud.global_position = Vector2(screen_size.x + 100, y_pos)
	
	# מהירות אקראית
	cloud.speed = randf_range(cloud_speed_min, cloud_speed_max)
	cloud.direction = Vector2.LEFT
