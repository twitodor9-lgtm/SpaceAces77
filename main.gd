extends Node2D

const STAGE_CLEAR_SCENE_PATH := "res://Stages/StageClear.tscn"

@export var cloud_scene: PackedScene
@export var spawn_interval_min: float = 3.0
@export var spawn_interval_max: float = 8.0
@export var cloud_speed_min: float = 20.0
@export var cloud_speed_max: float = 50.0
@export var interceptor_scene: PackedScene
@export var interceptor_chance: float = 0.25
@export var interceptor_start_stage: int = 2
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
@export var boss_scene: PackedScene

# ✅ באילו שלבים יש "קרקע"
# אם הרשימה ריקה => קרקע תמיד קיימת
@export var stages_with_ground: PackedInt32Array = PackedInt32Array([1])

var boss: Node = null
@onready var score_label: Label = get_node_or_null("UI/ScoreLabel") as Label

var boss_spawned: bool = false
var stage_index: int = 1
var score: int = 0
var octo_whale_spawned := false
var monster_director = null
var _spawn_timer: float = 0.0
var spawning_enabled: bool = true

func _ready() -> void:
	score = GameState.score
	stage_index = GameState.stage_index

	GameBalance.stage_index = maxi(stage_index - 1, 0)
	print("STAGE:", stage_index, " RULES:", GameBalance.rules())
	print("CAMERA:", get_viewport().get_camera_2d())

	_setup_ui()
	_setup_background()
	_setup_spawn_timers()
	_setup_boss()
	_setup_monster_director()
	_cleanup_preplaced_monsters()

	_apply_stage_rules()

	_spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)

	_print_all_groups(get_tree().current_scene)
	print("READY SCORE:", score)

func _setup_ui() -> void:
	GameplayRuntime.setup_ui(self, stage_index, score, _on_next_stage_pressed)

func _setup_background() -> void:
	GameplayRuntime.setup_background(self)

func _setup_spawn_timers() -> void:
	_connect_timer("EnemySpawnTimer", _on_air_spawn_timer_timeout)
	_connect_timer("GroundEnemyTimer", _on_ground_spawn_timer_timeout)

func _connect_timer(timer_name: String, callback: Callable) -> void:
	GameplayRuntime.connect_timer(self, timer_name, callback)

func _setup_boss() -> void:
	var preplaced := get_node_or_null("WardenGiant")
	if preplaced != null:
		preplaced.queue_free()
	boss = null

func _setup_monster_director() -> void:
	monster_director = GameplayRuntime.setup_monster_director(self)

func _cleanup_preplaced_monsters() -> void:
	var pre_ow := get_node_or_null("OctoWhale")
	if pre_ow:
		pre_ow.queue_free()

func _apply_stage_rules() -> void:
	GameplayRuntime.apply_stage_rules(self)
	max_air_enemies = int(GameBalance.rule("max_air_enemies", max_air_enemies))
	max_ground_enemies_on_screen = int(GameBalance.rule("max_ground_enemies", max_ground_enemies_on_screen))
	boss_score_threshold = int(GameBalance.rule("boss_score_threshold", boss_score_threshold))
	interceptor_chance = float(GameBalance.rule("interceptor_chance", interceptor_chance))
	interceptor_start_stage = int(GameBalance.rule("interceptor_start_stage", interceptor_start_stage))

func _set_timer_enabled(t: Timer, enabled: bool) -> void:
	GameplayRuntime.set_timer_enabled(t, enabled)

func _set_node_enabled(n: Node, enabled: bool) -> void:
	GameplayRuntime.set_node_enabled(n, enabled)

func spawn_named_monster(id: String, pos: Vector2) -> Node:
	if monster_director == null:
		return null
	if monster_director.has_method("spawn_once"):
		return monster_director.call("spawn_once", id, self, pos)
	return null

func spawn_void_raptor() -> Node:
	var r := _get_visible_world_rect()
	var x := r.position.x + r.size.x - 120.0
	var y := ground_spawn_y - 80.0

	var gl := GameplayRuntime.find_node(self, "GroundLine") as Marker2D
	if gl != null:
		y = gl.global_position.y - 90.0

	var spawn_marker := GameplayRuntime.find_node(self, "RaptorSpawn") as Marker2D
	if spawn_marker != null:
		x = spawn_marker.global_position.x
		y = spawn_marker.global_position.y

	return spawn_named_monster("void_raptor", Vector2(x, y))

func _on_next_stage_pressed() -> void:
	GameState.next_stage()

func call_octo_whale() -> void:
	if octo_whale_spawned:
		return

	var r := _get_visible_world_rect()
	var spawn_pos := Vector2(r.position.x + r.size.x + 220.0, r.position.y + r.size.y * 0.50)
	var inst := spawn_named_monster("octo_whale", spawn_pos)
	if inst != null:
		octo_whale_spawned = true

func stage_has_ground(stage: int = -1) -> bool:
	var s := stage
	if s < 0:
		s = stage_index
	if stages_with_ground.is_empty():
		return true
	return stages_with_ground.has(s)

func _on_air_spawn_timer_timeout() -> void:
	if not spawning_enabled:
		return
	if air_enemy_scene == null:
		return

	var existing: int = get_tree().get_nodes_in_group("air_enemies").size()
	if existing >= max_air_enemies:
		return

	var chosen: PackedScene = air_enemy_scene
	if interceptor_scene != null and stage_index >= interceptor_start_stage and randf() < interceptor_chance:
		chosen = interceptor_scene

	var enemy: Node2D = chosen.instantiate() as Node2D
	add_child(enemy)

func _print_all_groups(root: Node) -> void:
	var groups: Dictionary = {}
	var stack: Array[Node] = [root]

	while stack.size() > 0:
		var n: Node = stack.pop_back()

		for g: StringName in n.get_groups():
			groups[g] = true

		for c: Node in n.get_children():
			stack.append(c)

	print("ALL GROUPS IN SCENE:", groups.keys())

func add_score(points: int) -> void:
	score += points
	GameState.score = score

	var ui_root := GameplayRuntime.find_node(self, "UIRoot")
	if ui_root != null and ui_root.has_method("set_score"):
		ui_root.call("set_score", score)

	print("SCORE UPDATED:", score, " threshold=", boss_score_threshold, " boss_spawned=", boss_spawned, " boss=", boss)

	if (not boss_spawned) and score >= boss_score_threshold:
		print("BOSS THRESHOLD REACHED -> toggling boss")
		boss_spawned = true
		_toggle_boss()

func _go_to_stage_clear() -> void:
	GameState.score = score
	print("DEBUG: GO TO STAGE CLEAR WITH SCORE:", GameState.score)

	if not ResourceLoader.exists(STAGE_CLEAR_SCENE_PATH):
		push_error("StageClear scene not found: %s" % STAGE_CLEAR_SCENE_PATH)
		return

	get_tree().change_scene_to_file(STAGE_CLEAR_SCENE_PATH)

func _set_spawning_enabled(enabled: bool) -> void:
	spawning_enabled = enabled
	_set_timer_enabled(GameplayRuntime.find_node(self, "EnemySpawnTimer") as Timer, enabled)
	_set_timer_enabled(GameplayRuntime.find_node(self, "GroundEnemyTimer") as Timer, enabled)

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
		if boss_scene == null:
			print("_toggle_boss: boss_scene is null")
			return
		boss = boss_scene.instantiate()
		if boss == null:
			print("_toggle_boss: failed to instantiate boss_scene")
			return
		add_child(boss)
		if boss.has_signal("boss_died"):
			var boss_sig: Signal = boss.get("boss_died")
			if not boss_sig.is_connected(_on_boss_died):
				boss_sig.connect(_on_boss_died)

	var should_show: bool = not boss.visible
	print("_toggle_boss: should_show=", should_show, " current_visible=", boss.visible)
	boss.visible = should_show
	boss.set_process(should_show)
	boss.set_physics_process(should_show)
	_set_spawning_enabled(not should_show)

	if should_show:
		var ui_root := GameplayRuntime.find_node(self, "UIRoot")
		if ui_root != null and ui_root.has_method("set_stage"):
			ui_root.call("set_stage", stage_index)
		var boss_spawn := GameplayRuntime.find_node(self, "BossSpawn") as Marker2D
		if boss_spawn != null:
			boss.global_position = boss_spawn.global_position
		else:
			var r := _get_visible_world_rect()
			boss.global_position = Vector2(r.position.x + r.size.x + 220.0, r.position.y + r.size.y * 0.30)

func _on_boss_died() -> void:
	print("BOSS DOWN")
	_go_to_stage_clear()
