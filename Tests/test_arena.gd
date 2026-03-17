extends Node2D

const ROBOT_SCALE := Vector2(1.7, 1.7)
const GROUND_MINE_TRIGGER_Y := 500.0

@export var player_scene: PackedScene
@export var background_scene: PackedScene
@export var robot_scene: PackedScene
@export var ground_mine_scene: PackedScene
@export var void_raptor_scene: PackedScene
@export var air_enemy_scene: PackedScene
@export var interceptor_scene: PackedScene
@export var turret_scene: PackedScene

var _player: Node2D = null
var _status_label: Label = null
var _pending_ground_mines: Array[Node2D] = []
var _background: Node2D = null
var _ui_root: CanvasLayer = null

func _ready() -> void:
	_setup_background()
	_setup_player()
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

func _setup_ui() -> void:
	_ui_root = CanvasLayer.new()
	add_child(_ui_root)

	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.size = Vector2(300, 520)
	_ui_root.add_child(panel)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(root)

	root.add_child(_make_title("TEST ARENA"))
	root.add_child(_make_section_label("Bosses"))
	root.add_child(_make_button("Spawn Robot", _spawn_robot))

	root.add_child(_make_section_label("Monsters"))
	root.add_child(_make_button("Spawn Void Raptor", _spawn_void_raptor))

	root.add_child(_make_section_label("Ground Enemies"))
	root.add_child(_make_button("Spawn Ground Mine", _spawn_ground_mine))
	root.add_child(_make_button("Spawn Turret", _spawn_turret))

	root.add_child(_make_section_label("Air Enemies"))
	root.add_child(_make_button("Spawn Air Enemy", _spawn_air_enemy))
	root.add_child(_make_button("Spawn Interceptor", _spawn_interceptor))

	root.add_child(_make_section_label("Background"))
	root.add_child(_make_button("Background 1", func(): _apply_background_preview(0)))
	root.add_child(_make_button("Background 2", func(): _apply_background_preview(1)))
	root.add_child(_make_button("Background 3", func(): _apply_background_preview(2)))

	root.add_child(_make_section_label("Tools"))
	root.add_child(_make_button("Clear Enemies", _clear_test_enemies))
	root.add_child(_make_button("Reset Player", _reset_player))
	root.add_child(_make_button("Normal Speed", func(): _set_time_scale(1.0)))
	root.add_child(_make_button("Half Speed", func(): _set_time_scale(0.5)))
	root.add_child(_make_button("Quarter Speed", func(): _set_time_scale(0.25)))

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(260, 72)
	root.add_child(_status_label)

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

func _make_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 32)
	b.pressed.connect(action)
	return b

func _show_help() -> void:
	_set_status("Keyboard: 1 Robot | 2 Mine | 3 Raptor | C Clear | R Reset")

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
	var raptor := _spawn_scene(void_raptor_scene, Vector2(900, 520), "test_enemy") as Node2D
	if raptor == null:
		return
	_set_status("Void Raptor spawned")

func _spawn_air_enemy() -> void:
	_spawn_scene(air_enemy_scene, Vector2(980, 260), "test_enemy")
	_set_status("Air enemy spawned")

func _spawn_interceptor() -> void:
	_spawn_scene(interceptor_scene, Vector2(980, 220), "test_enemy")
	_set_status("Interceptor spawned")

func _spawn_turret() -> void:
	_spawn_scene(turret_scene, Vector2(960, 610), "test_enemy")
	_set_status("Turret spawned")

func _spawn_scene(scene: PackedScene, pos: Vector2, group_name: StringName) -> Node:
	if scene == null:
		return null
	var inst := scene.instantiate()
	if inst == null:
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
	_set_status("Player reset")

func _apply_background_preview(index: int) -> void:
	if _background == null:
		return
	if _background.has_method("set"):
		_background.set("preview_stage_index", index)
	if _background.has_method("_apply"):
		_background.call("_apply")
	_set_status("Background %d loaded" % (index + 1))

func _set_time_scale(scale_value: float) -> void:
	Engine.time_scale = scale_value
	_set_status("Time scale set to %.2fx" % scale_value)

func _set_status(text: String) -> void:
	if _status_label == null:
		return
	_status_label.text = text

func stage_has_ground(stage: int = -1) -> bool:
	return true
