extends Node2D

@export var cloud_scene: PackedScene
@export var spawn_interval_min: float = 3.0
@export var spawn_interval_max: float = 8.0
@export var cloud_speed_min: float = 20.0
@export var cloud_speed_max: float = 50.0
@onready var boss = get_node_or_null("Boss")
var boss_spawned: bool = false

@onready var bg = get_node_or_null("ParallaxBackground")
@export var interceptor_scene: PackedScene
@export var interceptor_chance: float = 0.25
@export var interceptor_start_stage: int = 2
var stage_index: int = 1
@export var air_enemy_scene: PackedScene
@export var max_air_enemies: int = 4
@export var player_scene: PackedScene
@export var void_raptor_scene: PackedScene

# === הגדרות אויבי קרקע (טנקים/טורטים) ===
@export var ground_enemy_scene: PackedScene
@export var max_ground_enemies_on_screen: int = 2
@export var ground_min_distance: float = 220.0
@export var ground_spawn_y: float = 520.0
@export var ground_spawn_tries: int = 12
@export var boss_score_threshold: int = 300
var score: int = 0

# ✅ באילו שלבים יש "קרקע"
# אם הרשימה ריקה => קרקע תמיד קיימת
@export var stages_with_ground: PackedInt32Array = PackedInt32Array([1])

# מפלצות
var octo_whale_spawned := false
var monster_director = null

@onready var score_label: Label = get_node_or_null("UI/ScoreLabel") as Label

var _spawn_timer: float = 0.0
var spawning_enabled: bool = true

func _ready() -> void:
	score = GameState.score

	spawn_void_raptor()

	GameBalance.stage_index = maxi(GameState.stage_index - 1, 0)
	print("STAGE:", GameState.stage_index, " RULES:", GameBalance.rules())

	_apply_stage_rules()

	print("CAMERA:", get_viewport().get_camera_2d())

	var ui_root := get_node_or_null("UIRoot")
	if ui_root != null:
		if ui_root.has_signal("next_stage_pressed"):
			var sig: Signal = ui_root.get("next_stage_pressed")
			if not sig.is_connected(_on_next_stage_pressed):
				sig.connect(_on_next_stage_pressed)
		if ui_root.has_method("set_stage"):
			ui_root.call("set_stage", GameState.stage_index)
		if ui_root.has_method("set_score"):
			ui_root.call("set_score", score)

	var bg_node := get_node_or_null("Background")
	if bg_node != null and bg_node.has_method("apply_stage"):
		bg_node.call("apply_stage")

	# קישור טיימר אויבי אוויר
	if has_node("EnemySpawnTimer"):
		var air_timer: Timer = $EnemySpawnTimer
		if not air_timer.timeout.is_connected(_on_air_spawn_timer_timeout):
			air_timer.timeout.connect(_on_air_spawn_timer_timeout)

	# קישור טיימר אויבי קרקע (טורטים)
	if has_node("GroundEnemyTimer"):
		var ground_timer: Timer = $GroundEnemyTimer
		if not ground_timer.timeout.is_connected(_on_ground_spawn_timer_timeout):
			ground_timer.timeout.connect(_on_ground_spawn_timer_timeout)

	# בוס מתחיל כבוי
	if boss:
		boss.visible = false
		boss.set_process(false)
		boss.set_physics_process(false)

	if boss and boss.has_signal("boss_died"):
		var boss_sig: Signal = boss.get("boss_died")
		if not boss_sig.is_connected(_on_boss_died):
			boss_sig.connect(_on_boss_died)

	# ⭐ טיימר עננים
	_spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)

	# ✅ חשוב: אם ה-OctoWhale כבר קיים ב-main.tscn, מוחקים אותו כדי שיופיע רק בקריאה
	var pre_ow := get_node_or_null("OctoWhale")
	if pre_ow:
		pre_ow.queue_free()

	# שימוש ב-MonsterDirector קיים אם יש, אחרת יוצרים חדש
	var existing_md := get_node_or_null("MonsterDirector")
	if existing_md != null:
		monster_director = existing_md
	else:
		monster_director = MonsterDirector.new()
		monster_director.name = "MonsterDirector"
		add_child(monster_director)

	_print_all_groups(get_tree().current_scene)
	print("READY SCORE:", score)

func _apply_stage_rules() -> void:
	_set_timer_enabled(get_node_or_null("EnemySpawnTimer") as Timer,
		bool(GameBalance.rule("air_spawner_enabled", true)))

	_set_timer_enabled(get_node_or_null("GroundEnemyTimer") as Timer,
		bool(GameBalance.rule("ground_spawner_enabled", true)))

	_set_node_enabled(get_node_or_null("CloudSpawner"),
		bool(GameBalance.rule("cloud_spawner_enabled", true)))

	_set_node_enabled(get_node_or_null("WormSpawner"),
		bool(GameBalance.rule("worm_enabled", false)))

func _set_timer_enabled(t: Timer, enabled: bool) -> void:
	if t == null:
		return
	if enabled:
		if t.is_stopped():
			t.start()
	else:
		t.stop()

func _set_node_enabled(n: Node, enabled: bool) -> void:
	if n == null:
		return

	n.set_process(enabled)
	n.set_physics_process(enabled)

	if n is Area2D:
		(n as Area2D).monitoring = enabled
		(n as Area2D).monitorable = enabled

func _on_next_stage_pressed() -> void:
	GameState.next_stage()

func call_octo_whale() -> void:
	if octo_whale_spawned:
		return

	var r := _get_visible_world_rect()
	var spawn_pos := Vector2(r.position.x + r.size.x + 220.0, r.position.y + r.size.y * 0.50)

	if monster_director and monster_director.has_method("spawn_once"):
		var inst = monster_director.call("spawn_once", "octo_whale", self, spawn_pos)
		if inst != null:
			octo_whale_spawned = true

func stage_has_ground(stage: int = -1) -> bool:
	var s := stage
	if s < 0:
		s = stage_index
	if stages_with_ground.is_empty():
		return true
	return stages_with_ground.has(s)

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

	var ui_root := get_node_or_null("UIRoot")
	if ui_root != null and ui_root.has_method("set_stage"):
		ui_root.call("set_stage", GameBalance.stage_index)

func _print_all_groups(root: Node) -> void:
	var groups: Dictionary = {}

	var stack: Array[Node] = [root]
	while stack.size() > 0:
		var n: Node = stack.pop_back()

		var gs: Array[StringName] = n.get_groups()
		for g: StringName in gs:
			groups[g] = true

		var children: Array[Node] = n.get_children()
		for c: Node in children:
			stack.append(c)

	print("ALL GROUPS IN SCENE:", groups.keys())

func add_score(points: int) -> void:
	score += points
	GameState.score = score

	var ui_root := get_node_or_null("UIRoot")
	if ui_root != null and ui_root.has_method("set_score"):
		ui_root.call("set_score", score)

	print("SCORE UPDATED:", score)

	if (not boss_spawned) and score >= boss_score_threshold:
		boss_spawned = true
		_toggle_boss()

func _go_to_stage_clear() -> void:
	GameState.score = score
	print("DEBUG: GO TO STAGE CLEAR WITH SCORE:", GameState.score)
	get_tree().change_scene_to_file("res://_context/Stages/StageClear.tscn")

func _set_spawning_enabled(enabled: bool) -> void:
	spawning_enabled = enabled

	var air_timer: Timer = get_node_or_null("EnemySpawnTimer") as Timer
	if air_timer:
		if enabled:
			air_timer.start()
		else:
			air_timer.stop()

	var ground_timer: Timer = get_node_or_null("GroundEnemyTimer") as Timer
	if ground_timer:
		if enabled:
			ground_timer.start()
		else:
			ground_timer.stop()

func _on_ground_spawn_timer_timeout() -> void:
	if not spawning_enabled:
		return
	if ground_enemy_scene == null:
		return

	var existing := get_tree().get_nodes_in_group("ground_enemies").size()
	if existing >= max_ground_enemies_on_screen:
		return

	var view := get_viewport_rect().size
	var x_min := 80.0
	var x_max := view.x - 80.0

	var spawn_x := -1.0
	for i in range(ground_spawn_tries):
		var candidate := randf_range(x_min, x_max)
		if _is_ground_x_free(candidate, ground_min_distance):
			spawn_x = candidate
			break

	if spawn_x < 0.0:
		return

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

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo and k.keycode == KEY_M:
			call_octo_whale()
		elif k.pressed and not k.echo and k.keycode == KEY_P:
			print("DEBUG: P PRESSED")
			_go_to_stage_clear()

	if event.is_action_pressed("spawn_boss"):
		_toggle_boss()

func _toggle_boss() -> void:
	if boss == null:
		return

	var should_show: bool = not boss.visible
	boss.visible = should_show
	boss.set_process(should_show)
	boss.set_physics_process(should_show)
	_set_spawning_enabled(not should_show)

	if should_show:
		var r := _get_visible_world_rect()
		boss.global_position = Vector2(r.position.x + r.size.x + 220.0, r.position.y + r.size.y * 0.30)

func _on_boss_died() -> void:
	print("BOSS DOWN")
	_go_to_stage_clear()

func spawn_void_raptor() -> void:
	if void_raptor_scene == null:
		return

	# לא ליצור פעמיים
	if get_node_or_null("VoidRaptor") != null:
		return

	var r := _get_visible_world_rect()

	# ברירת מחדל: בתוך המסך, קצת מעל הקרקע
	var x := r.position.x + r.size.x * 0.75
	var y := ground_spawn_y - 80.0

	var gl := get_node_or_null("GroundLine") as Marker2D
	if gl != null:
		y = gl.global_position.y - 80.0

	# אם יש Marker ייעודי – עדיף
	var spawn_marker := get_node_or_null("RaptorSpawn") as Marker2D
	if spawn_marker != null:
		x = spawn_marker.global_position.x
		y = spawn_marker.global_position.y

	var raptor := void_raptor_scene.instantiate() as Node2D
	add_child(raptor)
	raptor.global_position = Vector2(x, y)
