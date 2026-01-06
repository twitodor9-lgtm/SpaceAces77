extends Node2D

@onready var bg := $ParallaxBackground
# === הגדרות אויבי אוויר ===
#
@export var air_enemy_scene: PackedScene
@export var max_air_enemies: int = 5
@export var player_scene: PackedScene
#
# === הגדרות אויבי קרקע (טנקים/טורטים) ===
#
@export var ground_enemy_scene: PackedScene
@export var max_ground_enemies_on_screen: int = 3     # מקסימום טנקים במסך
@export var ground_min_distance: float = 220.0        # מרחק מינימלי בין טנקים
@export var ground_spawn_y: float = 520.0             # גובה הספאון (התאם למסך שלך)
@export var ground_spawn_tries: int = 12              # ניסיונות למצוא מקום פנוי
func _process(delta):
	bg.scroll_offset.x += 100* delta

func _ready() -> void:
	# קישור טיימר אויבי אוויר
	if has_node("EnemySpawnTimer"):
		$EnemySpawnTimer.timeout.connect(_on_air_spawn_timer_timeout)

	# קישור טיימר אויבי קרקע (טורטים)
	if has_node("GroundEnemyTimer"):
		$GroundEnemyTimer.timeout.connect(_on_ground_spawn_timer_timeout)
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
		-50   # נכנס מלמעלה
	)
func _on_ground_spawn_timer_timeout() -> void:
	if ground_enemy_scene == null:
		return

	# 1) בדיקת כמות טנקים על המסך
	var existing := get_tree().get_nodes_in_group("ground_enemies").size()
	if existing >= max_ground_enemies_on_screen:
		return

	var view := get_viewport_rect().size
	var x_min := 80.0
	var x_max := view.x - 80.0

	# 2) ניסיון למצוא מקום X פנוי
	var spawn_x := -1.0
	for i in range(ground_spawn_tries):
		var candidate := randf_range(x_min, x_max)
		if _is_ground_x_free(candidate, ground_min_distance):
			spawn_x = candidate
			break

	# אם לא נמצא מקום פנוי — לא יוצרים טנק הפעם
	if spawn_x < 0.0:
		return

	# 3) יצירת טנק חדש
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
