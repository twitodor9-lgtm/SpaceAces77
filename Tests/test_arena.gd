extends Node2D

const ROBOT_SCALE := Vector2(1.7, 1.7)
const GROUND_MINE_TRIGGER_Y := 500.0

@export var player_scene: PackedScene
@export var background_scene: PackedScene
@export var ui_scene: PackedScene
@export var robot_scene: PackedScene
@export var ground_mine_scene: PackedScene
@export var void_raptor_scene: PackedScene
@export var octo_whale_scene: PackedScene
@export var space_worm_scene: PackedScene
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

func _ready() -> void:
	_setup_background()
	_setup_player()
	_setup_game_ui()
	_setup_ui()
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

func _setup_background() -> void:
	if background_scene == null:
		return
	_background = background_scene.instantiate() as Node2D
	add_child(_background)
	_background.name = "Background"
	_apply_background_preview(0)

func _setup_player() -> void:
	if player_scene == null:
		return
	_player = player_scene.instantiate() as Node2D
	_player.name = "Player"
	add_child(_player)
	_player.global_position = Vector2(180, 340)

func _setup_game_ui() -> void:
	if ui_scene == null:
		return
	_game_ui = ui_scene.instantiate() as CanvasLayer
	if _game_ui == null:
		return
	add_child(_game_ui)
	_game_ui.name = "UIRoot"
	_game_ui.set("player_path", NodePath("../Player"))
	_game_ui.set("star_punch_path", NodePath("../Player/Abilities/StarPunch"))
	if _game_ui.has_method("set_stage"):
		_game_ui.call("set_stage", 1)
	if _game_ui.has_method("set_score"):
		_game_ui.call("set_score", 0)

func _setup_ui() -> void:
	_ui_root = CanvasLayer.new()
	add_child(_ui_root)

	var top_bar := PanelContainer.new()
	top_bar.position = Vector2(12, 8)
	top_bar.size = Vector2(1240, 48)
	_ui_root.add_child(top_bar)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(row)

	row.add_child(_make_menu_button("Bosses", [
		_make_button("Spawn Robot", _spawn_robot),
	]))
	row.add_child(_make_menu_button("Monsters", [
		_make_button("Spawn Void Raptor", _spawn_void_raptor),
		_make_button("Spawn Octo Whale", _spawn_octo_whale),
		_make_button("Spawn Space Worm", _spawn_space_worm),
	]))
	row.add_child(_make_menu_button("Ground", [
		_make_button("Spawn Ground Mine", _spawn_ground_mine),
		_make_button("Spawn Turret", _spawn_turret),
	]))
	row.add_child(_make_menu_button("Air", [
		_make_button("Spawn Air Enemy", _spawn_air_enemy),
		_make_button("Spawn Interceptor", _spawn_interceptor),
	]))
	row.add_child(_make_menu_button("Backgrounds", [
		_make_button("Background 1", func(): _apply_background_preview(0)),
		_make_button("Background 2", func(): _apply_background_preview(1)),
		_make_button("Background 3", func(): _apply_background_preview(2)),
	]))
	row.add_child(_make_menu_button("Tools", [
		_make_button("Clear Enemies", _clear_test_enemies),
		_make_button("Reset Player", _reset_player),
		_make_button("Normal Speed", func(): _set_time_scale(1.0)),
		_make_button("Half Speed", func(): _set_time_scale(0.5)),
		_make_button("Quarter Speed", func(): _set_time_scale(0.25)),
	]))
	row.add_child(_make_button("Controls Help", _toggle_controls_help))

	_status_label = Label.new()
	_status_label.position = Vector2(16, 60)
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.size = Vector2(780, 48)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ui_root.add_child(_status_label)

	_setup_controls_panel()

func _setup_controls_panel() -> void:
	_controls_panel = PanelContainer.new()
	_controls_panel.position = Vector2(16, 96)
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
	box.add_child(_make_button("Close Help", _toggle_controls_help))

func _make_title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 24)
	return l

func _make_help_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _make_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(140, 30)
	b.pressed.connect(action)
	return b

func _make_menu_button(title: String, controls: Array[Control]) -> MenuButton:
	var menu_button := MenuButton.new()
	menu_button.text = title
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
	_set_status("Ready. Use top menus or keyboard: 1/2/3, C clear, R reset, H help")

func _toggle_controls_help() -> void:
	if _controls_panel == null:
		return
	_controls_panel.visible = not _controls_panel.visible

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
	if _spawn_scene(void_raptor_scene, Vector2(900, 520), "test_enemy") != null:
		_set_status("Void Raptor spawned")

func _spawn_octo_whale() -> void:
	if _spawn_scene(octo_whale_scene, Vector2(1020, 360), "test_enemy") != null:
		_set_status("Octo Whale spawned")

func _spawn_space_worm() -> void:
	var worm := _spawn_scene(space_worm_scene, Vector2(980, 640), "test_enemy")
	if worm != null and worm.has_method("start_attack"):
		worm.call("start_attack", 980.0, 640.0, 0.0, 0.0)
		_set_status("Space Worm spawned")

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
	if not is_instance_valid(_player):
		return
	if _pending_ground_mines.is_empty():
		return
	if _player.global_position.y < GROUND_MINE_TRIGGER_Y:
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
	if is_instance_valid(_player):
		_player.queue_free()
	_setup_player()
	if _game_ui != null:
		_game_ui.set("player_path", NodePath("../Player"))
	_set_status("Player reset")

func _apply_background_preview(index: int) -> void:
	if _background == null:
		return
	var stages = GameBalance.STAGES
	if index < 0 or index >= stages.size():
		return
	if _background.has_method("_set_textures_from_rules"):
		_background.call("_set_textures_from_rules", stages[index])
	_set_status("Background %d loaded" % (index + 1))

func _set_time_scale(scale_value: float) -> void:
	Engine.time_scale = scale_value
	_set_status("Time scale set to %.2fx" % scale_value)

func _set_status(text: String) -> void:
	if _status_label == null:
		return
	_status_label.text = text

func add_score(points: int) -> void:
	if _game_ui != null and _game_ui.has_method("set_score"):
		var current_text := (_game_ui.get_node_or_null("UI/ScoreLabel") as Label)
		var current := 0
		if current_text != null:
			current = int(current_text.text)
		_game_ui.call("set_score", current + points)

func stage_has_ground(stage: int = -1) -> bool:
	return true
