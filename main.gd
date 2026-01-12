extends Node2D

@export var cloud_scene: PackedScene
@export var spawn_interval_min: float = 3.0
@export var spawn_interval_max: float = 8.0
@export var cloud_speed_min: float = 20.0
@export var cloud_speed_max: float = 50.0

@onready var bg := $ParallaxBackground

var _spawn_timer: float = 0.0

# === הגדרות אויבי אוויר ===
@export var air_enemy_scene: PackedScene
@export var max_air_enemies: int = 5
@export var player_scene: PackedScene

# === הגדרות אויבי קרקע (טנקים/טורטים) ===
@export var ground_enemy_scene: PackedScene
@export var max_ground_enemies_on_screen: int = 3
@export var ground_min_distance: float = 220.0
@export var ground_spawn_y: float = 520.0
@export var ground_spawn_tries: int = 12


func _ready() -> void:
	# קישור טיימר אויבי אוויר
	if has_node("EnemySpawnTimer"):
		$EnemySpawnTimer.timeout.connect(_on_air_spawn_timer_timeout)
	
	# קישור טיימר אויבי קרקע (טורטים)
	if has_node("GroundEnemyTimer"):
		$GroundEnemyTimer.timeout.connect(_on_ground_spawn_timer_timeout)
	
	# ⭐ טיימר עננים
	_spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)


func _process(delta: float) -> void:
	# ⭐ רקע נע
	bg.scroll_offset.x += 100 * delta
	
	# ⭐ טיימר עננים
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_cloud()
		_spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)


func _on_air_spawn_timer_timeout() -> void:
	if air_enemy_scene == null:
		return
	
	var existing := get_tree().get_nodes_in_group("air_enemies").size()
	if existing >= max_air_enemies:
		return
	
	var enemy = air_enemy_scene.instantiate()
	add_child(enemy)
	
	var view := get_viewport_rect().size
	enemy.global_position = Vector2(
		randf_range(100, view.x - 100),
		-50
	)


func _on_ground_spawn_timer_timeout() -> void:
	if ground_enemy_scene == null:
		return
	
	# בדיקת כמות טנקים על המסך
	var existing := get_tree().get_nodes_in_group("ground_enemies").size()
	if existing >= max_ground_enemies_on_screen:
		return
	
	var view := get_viewport_rect().size
	var x_min := 80.0
	var x_max := view.x - 80.0
	
	# ניסיון למצוא מקום X פנוי
	var spawn_x := -1.0
	for i in range(ground_spawn_tries):
		var candidate := randf_range(x_min, x_max)
		if _is_ground_x_free(candidate, ground_min_distance):
			spawn_x = candidate
			break
	
	# אם לא נמצא מקום פנוי — לא יוצרים טנק
	if spawn_x < 0.0:
		return
	
	# יצירת טנק חדש
	var g = ground_enemy_scene.instantiate() as Node2D
	add_child(g)
	g.global_position = Vector2(spawn_x, ground_spawn_y)


func _is_ground_x_free(candidate_x: float, min_dist: float) -> bool:
	for e in get_tree().get_nodes_in_group("ground_enemies"):
		if e is Node2D:
			var dx: float = abs((e as Node2D).global_position.x - candidate_x)
			if dx < min_dist:
				return false
	return true


func _spawn_cloud() -> void:
	if cloud_scene == null:
		return
	
	var cloud = cloud_scene.instantiate()
	add_child(cloud)
	
	var screen_size = get_viewport_rect().size
	# ⭐ רק בשליש העליון!
	var y_pos = randf_range(30, screen_size.y * 0.20)
	
	cloud.global_position = Vector2(screen_size.x + 100, y_pos)
	cloud.speed = randf_range(cloud_speed_min, cloud_speed_max)
	cloud.direction = Vector2.LEFT
