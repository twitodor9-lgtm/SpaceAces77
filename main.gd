extends Node2D

@export var cloud_scene: PackedScene
@export var spawn_interval_min: float = 3.0
@export var spawn_interval_max: float = 8.0
@export var cloud_speed_min: float = 20.0
@export var cloud_speed_max: float = 50.0
@onready var boss := $Boss
var boss_spawned: bool = false

@onready var bg := $ParallaxBackground
@export var interceptor_scene: PackedScene
@export var interceptor_chance: float = 0.25
@export var interceptor_start_stage: int = 2
var stage_index: int = 1



@export var air_enemy_scene: PackedScene
@export var max_air_enemies: int = 4
@export var player_scene: PackedScene

# === הגדרות אויבי קרקע (טנקים/טורטים) ===
@export var ground_enemy_scene: PackedScene
@export var max_ground_enemies_on_screen: int = 2
@export var ground_min_distance: float = 220.0
@export var ground_spawn_y: float = 520.0
@export var ground_spawn_tries: int = 12
@export var boss_score_threshold: int = 300
var score: int = 0
var boss_spawned: bool = false

@onready var score_label: Label = $UI/ScoreLabel

var _spawn_timer: float = 0.0
var spawning_enabled: bool = true

# === הגדרות אויבי אוויר ===
func _on_air_spawn_timer_timeout() -> void:
	if not spawning_enabled:
		return
	if air_enemy_scene == null:
		return

	var existing: int = get_tree().get_nodes_in_group("air_enemies").size()
	if existing >= max_air_enemies:
		return

	var chosen: PackedScene = air_enemy_scene

	if interceptor_scene != null and stage_index >= interceptor_start_stage:
		if randf() < interceptor_chance:
			chosen = interceptor_scene

	var enemy: Node2D = chosen.instantiate() as Node2D
	add_child(enemy)
	# ... המשך מיקום וכו'

	


func _ready() -> void:
	# קישור טיימר אויבי אוויר
	if has_node("EnemySpawnTimer"):
		$EnemySpawnTimer.timeout.connect(_on_air_spawn_timer_timeout)
	
	# קישור טיימר אויבי קרקע (טורטים)
	if has_node("GroundEnemyTimer"):
		$GroundEnemyTimer.timeout.connect(_on_ground_spawn_timer_timeout)
	if boss:
		
		boss.visible = false
		boss.set_process(false)
		boss.set_physics_process(false)
	if boss.has_signal("boss_died"):
			var sig: Signal = boss.get("boss_died")
			if not sig.is_connected(_on_boss_died):
				sig.connect(_on_boss_died)
	# ⭐ טיימר עננים
	_spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)
	

func _process(delta: float) -> void:
	# ⭐ רקע נע
	bg.scroll_offset.x += 100 * delta
	
	## ⭐ טיימר עננים
	#_spawn_timer -= delta
	#if _spawn_timer <= 0.0:
		#_spawn_cloud()
		#_spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)
func add_score(points: int) -> void:
	score += points
	score_label.text = str(score)

	if (not boss_spawned) and score >= boss_score_threshold:
		boss_spawned = true
		# זימון בוס כמו במקש B
		_toggle_boss()

func _set_spawning_enabled(enabled: bool) -> void:
	spawning_enabled = enabled

	var air_timer: Timer = get_node_or_null("EnemySpawnTimer") as Timer
	if air_timer:
		if enabled: air_timer.start()
		else: air_timer.stop()

	var ground_timer: Timer = get_node_or_null("GroundEnemyTimer") as Timer
	if ground_timer:
		if enabled: ground_timer.start()
		else: ground_timer.stop()

# ... המשך מיקום וכו'

func _on_ground_spawn_timer_timeout() -> void:
	if not spawning_enabled:
		return
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

func _get_visible_world_rect() -> Rect2:
	var vp := get_viewport().get_visible_rect().size
	var inv := get_viewport().get_canvas_transform().affine_inverse()

	var p0 := inv * Vector2(0, 0)
	var p1 := inv * Vector2(vp.x, 0)
	var p2 := inv * Vector2(0, vp.y)
	var p3 := inv * Vector2(vp.x, vp.y)

	var minx: float = minf(minf(p0.x, p1.x), minf(p2.x, p3.x))
	var maxx: float = maxf(maxf(p0.x, p1.x), maxf(p2.x, p3.x))
	var miny: float = minf(minf(p0.y, p1.y), minf(p2.y, p3.y))
	var maxy: float = maxf(maxf(p0.y, p1.y), maxf(p2.y, p3.y))

	return Rect2(Vector2(minx, miny), Vector2(maxx - minx, maxy - miny))
	
func _is_ground_x_free(candidate_x: float, min_dist: float) -> bool:
	for e in get_tree().get_nodes_in_group("ground_enemies"):
		if e is Node2D:
			var dx: float = abs((e as Node2D).global_position.x - candidate_x)
			if dx < min_dist:
				return false
	return true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_boss"):
		_toggle_boss()

func _toggle_boss() -> void:
	if boss == null:
		return

	var should_show: bool = not boss.visible
	boss.visible = should_show
	boss.set_process(should_show)
	boss.set_physics_process(should_show)
	_set_spawning_enabled(not should_show) # אם הבוס מופיע -> ספאון כבוי

	if should_show:
		var r := _get_visible_world_rect()
		boss.global_position = Vector2(r.position.x + r.size.x + 220.0, r.position.y + r.size.y * 0.30)
		
func _on_boss_died() -> void:
	print("BOSS DOWN")

	stage_index += 1
	boss_spawned = false

	_set_spawning_enabled(true)

	# אם אתה מזמן בוס עם toggle, תוודא שהוא כבוי אחרי המוות (למקרה של hide/show)
	if boss != null and boss.visible:
		_toggle_boss()

	
	
	# כאן בהמשך נעצור ספאונרים/נציג הודעה/נעבור שלב

#func _spawn_cloud() -> void:
	#if cloud_scene == null:
		#return
	#
	#var cloud = cloud_scene.instantiate()
	#add_child(cloud)
	#
	#var screen_size = get_viewport_rect().size
	## ⭐ רק בשליש העליון!
	#var y_pos = randf_range(30, screen_size.y * 0.20)
	#
	#cloud.global_position = Vector2(screen_size.x + 100, y_pos)
	#cloud.speed = randf_range(cloud_speed_min, cloud_speed_max)
	#cloud.direction = Vector2.LEFT
