extends Node2D

const ROBOT_SCALE := Vector2(1.7, 1.7)
const GROUND_MINE_TRIGGER_Y := 500.0
const NEUTRAL_BACKGROUND_ID := "neutral_arena"
const NEUTRAL_LOW_COVER_STAGE_INDEX := 2 # borrow Stage 3 low-cover accuracy for telemetry tuning

@export var robot_scene: PackedScene
@export var ground_mine_scene: PackedScene
@export var air_enemy_scene: PackedScene
@export var interceptor_scene: PackedScene
@export var turret_scene: PackedScene

var _player: Node2D = null
var _status_label: Label = null
var _pending_ground_mines: Array[Node2D] = []
var _background: Node2D = null
var _ui_root: CanvasLayer = null
var _game_ui: CanvasLayer = null
var _controls_panel: PanelContainer = null
var _enemies_panel: PanelContainer = null
var _worm_spawner: Node = null
var _monster_director: MonsterDirector = null
var _score: int = 0
var _shell: Node = null
var _arena_stage_mode: int = -1 # -1 = neutral
var _status_ttl: float = 0.0

func _ready() -> void:
	_bind_shell_nodes()
	_setup_ui()
	_apply_neutral_arena()
	_show_help()

func _process(_delta: float) -> void:
	_update_ground_mine_activation()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_spawn_robot()
			KEY_2:
				_spawn_ground_mine()
			KEY_3:
				_spawn_void_raptor()
			KEY_C:
				_clear_test_enemies()
			KEY_R:
				_reset_player()
			KEY_H:
				_toggle_controls_help()

func _bind_shell_nodes() -> void:
	_shell = get_node_or_null("GameplayShell")
	if _shell == null:
		return

	_player = _shell.get_node_or_null("Player") as Node2D
	_background = _shell.get_node_or_null("Background") as Node2D
	_worm_spawner = _shell.get_node_or_null("WormSpawner")
	_monster_director = _shell.get_node_or_null("MonsterDirector") as MonsterDirector
	_game_ui = _shell.get_node_or_null("UIRoot") as CanvasLayer
	var low_cover := _shell.get_node_or_null("LowCoverController")

	if _player != null:
		_player.global_position = Vector2(180, 340)

	if _game_ui != null:
		_game_ui.set("player_path", NodePath("../Player"))
		_game_ui.set("star_punch_path", NodePath("../Player/Abilities/StarPunch"))
		if _game_ui.has_method("_bind_runtime_refs"):
			_game_ui.call("_bind_runtime_refs")
		GameplayRuntime.setup_ui(_shell, 0, _score)

	if _background != null:
		GameplayRuntime.setup_background(_shell)

	if low_cover != null:
		low_cover.set("player_path", NodePath("../Player"))
		low_cover.set("GroundLine_path", NodePath("../GroundLine"))
		if low_cover.has_method("_ready"):
			low_cover.call("_ready")

	if _worm_spawner != null:
		_worm_spawner.set("worm_scene", load("res://Enemies/Monsters/SpaceWorm/space_worm.tscn"))
		_worm_spawner.set("player_path", NodePath("../Player"))
		_worm_spawner.set("ground_line_path", NodePath("../GroundLine"))
		_worm_spawner.set("dip_chance_override", 1.0)
		if _worm_spawner.has_method("_ready"):
			_worm_spawner.call("_ready")
		_worm_spawner.set_process(false)

func _spawn_named_monster(id: String, pos: Vector2) -> Node:
	if _monster_director == null:
		return null
	var parent := _shell if _shell != null else self
	var inst := _monster_director.spawn_once(id, parent, pos)
	if inst != null:
		inst.add_to_group("test_enemy")
	return inst

func _setup_ui() -> void:
	_ui_root = CanvasLayer.new()
	add_child(_ui_root)

	var top_bar := PanelContainer.new()
	top_bar.position = Vector2(760, 8)
	top_bar.size = Vector2(500, 48)
	_ui_root.add_child(top_bar)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(row)

	row.add_child(_make_top_button("Enemies", _toggle_enemies_panel))
	row.add_child(_make_menu_button("Stages", [
		_make_button("Neutral Arena", _apply_neutral_arena),
		_make_button("Stage 1 Rules", func(): _apply_stage_mode(0)),
		_make_button("Stage 2 Rules", func(): _apply_stage_mode(1)),
		_make_button("Stage 3 Rules", func(): _apply_stage_mode(2)),
	]))
	row.add_child(_make_menu_button("Tools", [
		_make_button("Clear Enemies", _clear_test_enemies),
		_make_button("Reset Player", _reset_player),
		_make_button("Normal Speed", func(): _set_time_scale(1.0)),
		_make_button("Half Speed", func(): _set_time_scale(0.5)),
		_make_button("Quarter Speed", func(): _set_time_scale(0.25)),
	]))
	row.add_child(_make_top_button("Controls", _toggle_controls_help))

	_status_label = Label.new()
	_status_label.position = Vector2(16, 60)
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.size = Vector2(740, 48)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ui_root.add_child(_status_label)

	_setup_enemies_panel()
	_setup_controls_panel()

func _setup_enemies_panel() -> void:
	_enemies_panel = PanelContainer.new()
	_enemies_panel.position = Vector2(760, 60)
	_enemies_panel.size = Vector2(330, 320)
	_enemies_panel.visible = false
	_ui_root.add_child(_enemies_panel)

	var root := VBoxContainer.new()
	_enemies_panel.add_child(root)
	root.add_child(_make_title("ENEMIES"))
	root.add_child(_make_section_label("Bosses"))
	root.add_child(_make_button("Spawn Robot", _spawn_robot))
	root.add_child(_make_section_label("Monsters"))
	root.add_child(_make_button("Spawn Void Raptor", _spawn_void_raptor))
	root.add_child(_make_button("Spawn Octo Whale", _spawn_octo_whale))
	root.add_child(_make_button("Trigger Space Worm", _trigger_space_worm))
	root.add_child(_make_section_label("Ground"))
	root.add_child(_make_button("Spawn Ground Mine", _spawn_ground_mine))
	root.add_child(_make_button("Spawn Turret", _spawn_turret))
	root.add_child(_make_section_label("Air"))
	root.add_child(_make_button("Spawn Air Enemy", _spawn_air_enemy))
	root.add_child(_make_button("Spawn Interceptor", _spawn_interceptor))

func _setup_controls_panel() -> void:
	_controls_panel = PanelContainer.new()
	_controls_panel.position = Vector2(900, 60)
	_controls_panel.size = Vector2(360, 260)
	_controls_panel.visible = false
	_ui_root.add_child(_controls_panel)

	var box := VBoxContainer.new()
	_controls_panel.add_child(box)
	box.add_child(_make_title("PLAYER CONTROLS"))
	box.add_child(_make_help_label("Move/Rotate: Arrow keys"))
	box.add_child(_make_help_label("Shoot: Space"))
	box.add_child(_make_help_label("Bomb: V"))
	box.add_child(_make_help_label("Loop: C"))
	box.add_child(_make_help_label("Star Punch: X"))
	box.add_child(_make_help_label("Dolphin Wave: D"))
	box.add_child(_make_help_label("Way Jump: W"))
	box.add_child(_make_help_label("Turbo: T"))
	box.add_child(_make_help_label("Deflector Shield: F"))
	box.add_child(_make_help_label("Arena: 1/2/3, C clear, R reset, H help"))
	box.add_child(_make_top_button("Close", _toggle_controls_help))

func _make_title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 24)
	return l

func _make_section_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	return l

func _make_help_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _disable_focus(c: Control) -> Control:
	c.focus_mode = Control.FOCUS_NONE
	return c

func _make_top_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(90, 30)
	b.pressed.connect(action)
	return _disable_focus(b) as Button

func _make_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(180, 30)
	b.pressed.connect(action)
	return _disable_focus(b) as Button

func _make_menu_button(title: String, controls: Array[Control]) -> MenuButton:
	var menu_button := MenuButton.new()
	menu_button.text = title
	menu_button.focus_mode = Control.FOCUS_NONE
	var popup := menu_button.get_popup()
	for i in range(controls.size()):
		var c := controls[i]
		popup.add_item(c.text, i)
	popup.id_pressed.connect(func(id: int):
		var btn := controls[id] as Button
		if btn != null:
			btn.pressed.emit()
	)
	return menu_button

func _show_help() -> void:
	pass

func _toggle_controls_help() -> void:
	if _controls_panel == null:
		return
	_controls_panel.visible = not _controls_panel.visible
	if _controls_panel.visible and _enemies_panel != null:
		_enemies_panel.visible = false

func _toggle_enemies_panel() -> void:
	if _enemies_panel == null:
		return
	_enemies_panel.visible = not _enemies_panel.visible
	if _enemies_panel.visible and _controls_panel != null:
		_controls_panel.visible = false

func _apply_neutral_arena() -> void:
	_arena_stage_mode = -1
	GameBalance.stage_index = NEUTRAL_LOW_COVER_STAGE_INDEX
	if _background != null and _background.has_method("_apply"):
		_background.call("_apply")
	_apply_background_id(NEUTRAL_BACKGROUND_ID)
	if _worm_spawner != null:
		_worm_spawner.set_process(true)
		_worm_spawner.set("cooldown", 0.6)
		_worm_spawner.set("telegraph_time", 0.35)
		_worm_spawner.set("dip_chance_override", 1.0)
	if _game_ui != null and _game_ui.has_method("set_stage"):
		_game_ui.call("set_stage", 0)
	_set_status("Neutral arena loaded (worm + low cover active, accuracy mul=%.2f)" % float(GameBalance.rule("low_cover_accuracy_mul", 1.0)))

func _apply_stage_mode(stage_idx: int) -> void:
	_arena_stage_mode = stage_idx
	GameBalance.stage_index = stage_idx
	if _background != null and _background.has_method("_apply"):
		_background.call("_apply")
	if _worm_spawner != null:
		_worm_spawner.set_process(GameBalance.rule("worm_enabled", false))
		_worm_spawner.set("cooldown", float(GameBalance.rule("worm_cooldown", 2.5)))
		_worm_spawner.set("telegraph_time", float(GameBalance.rule("telegraph_time", 0.55)))
	if _game_ui != null and _game_ui.has_method("set_stage"):
		_game_ui.call("set_stage", stage_idx + 1)
	_set_status("Stage %d rules loaded" % (stage_idx + 1))

func _apply_background_id(background_id: String) -> void:
	if _background == null:
		return
	if _background.has_method("apply_background_id"):
		_background.call("apply_background_id", background_id)

func _spawn_robot() -> void:
	var robot := _spawn_scene(robot_scene, Vector2(930, 340), "test_enemy") as Node2D
	if robot == null:
		return
	robot.scale = ROBOT_SCALE
	_set_status("Robot spawned")

func _spawn_ground_mine() -> void:
	var mine := _spawn_scene(ground_mine_scene, Vector2(860, 605), "test_enemy") as Node2D
	if mine == null:
		return
	mine.set_physics_process(false)
	mine.set_process(false)
	_pending_ground_mines.append(mine)
	_set_status("Ground mine armed. Wakes only below Y=%d" % int(GROUND_MINE_TRIGGER_Y))

func _spawn_void_raptor() -> void:
	if _spawn_named_monster("void_raptor", Vector2(900, 520)) != null:
		_set_status("Void Raptor spawned")

func _spawn_octo_whale() -> void:
	if _spawn_named_monster("octo_whale", Vector2(1020, 360)) != null:
		_set_status("Octo Whale spawned")

func _trigger_space_worm() -> void:
	if _worm_spawner == null:
		return
	if _worm_spawner.has_method("trigger_now"):
		var spawn_x := (_player.global_position.x if _player != null else 640.0)
		_worm_spawner.call("trigger_now", spawn_x)
		_set_status("Space Worm spawned")
		return
	_set_status("Space Worm trigger unavailable")

func _spawn_air_enemy() -> void:
	if _spawn_scene(air_enemy_scene, Vector2(980, 260), "test_enemy") != null:
		_set_status("Air enemy spawned")

func _spawn_interceptor() -> void:
	if _spawn_scene(interceptor_scene, Vector2(980, 220), "test_enemy") != null:
		_set_status("Interceptor spawned")

func _spawn_turret() -> void:
	if _spawn_scene(turret_scene, Vector2(960, 470), "test_enemy") != null:
		_set_status("Turret spawned")

func _spawn_scene(scene: PackedScene, pos: Vector2, group_name: StringName) -> Node:
	if scene == null:
		_set_status("Scene is not assigned yet")
		return null
	var inst := scene.instantiate()
	if inst == null:
		_set_status("Failed to instantiate scene")
		return null
	add_child(inst)
	if inst is Node2D:
		(inst as Node2D).global_position = pos
	inst.add_to_group(group_name)
	return inst

func _update_ground_mine_activation() -> void:
	if not is_instance_valid(_player) or _pending_ground_mines.is_empty() or _player.global_position.y < GROUND_MINE_TRIGGER_Y:
		return
	for mine in _pending_ground_mines:
		if is_instance_valid(mine):
			mine.set_physics_process(true)
			mine.set_process(true)
	_pending_ground_mines.clear()
	_set_status("Ground mine activated")

func _clear_test_enemies() -> void:
	for n in get_tree().get_nodes_in_group("test_enemy"):
		n.queue_free()
	_pending_ground_mines.clear()
	_set_status("Cleared test enemies")

func _reset_player() -> void:
	if _shell == null:
		return
	if is_instance_valid(_player):
		_player.queue_free()

	var player_scene := load("res://player.tscn") as PackedScene
	if player_scene == null:
		_set_status("Player scene missing")
		return

	var new_player := player_scene.instantiate() as Node2D
	if new_player == null:
		_set_status("Failed to reset player")
		return

	_shell.add_child(new_player)
		
	new_player.name = "Player"
	new_player.global_position = Vector2(180, 340)
	_player = new_player

	var thrust := _player.get_node_or_null("ThrustFlame") as Sprite2D
	if thrust != null:
		thrust.texture = null

	if _game_ui != null:
		_game_ui.set("player_path", NodePath("../Player"))
		_game_ui.set("star_punch_path", NodePath("../Player/Abilities/StarPunch"))

	if _worm_spawner != null:
		_worm_spawner.set("player_path", NodePath("../Player"))

	_set_status("Player reset")

func _set_time_scale(scale_value: float) -> void:
	Engine.time_scale = scale_value
	_set_status("Time scale set to %.2fx" % scale_value)

func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
		_status_label.visible = true
		_status_label.modulate = Color(0.42, 1.0, 0.66, 0.95)
		_status_ttl = 2.2

func _update_status_fade(delta: float) -> void:
	if _status_label == null or not _status_label.visible:
		return
	_status_ttl = maxf(_status_ttl - delta, 0.0)
	if _status_ttl <= 0.0:
		_status_label.visible = false
		return
	var alpha := 1.0
	if _status_ttl < 0.8:
		alpha = _status_ttl / 0.8
	_status_label.modulate = Color(0.42, 1.0, 0.66, 0.95 * alpha)

func add_score(points: int) -> void:
	_score += points
	if _game_ui != null and _game_ui.has_method("set_score"):
		_game_ui.call("set_score", _score)

func stage_has_ground(stage: int = -1) -> bool:
	return true
