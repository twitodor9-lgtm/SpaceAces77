extends Node2D

const ROBOT_SCALE := Vector2(1.7, 1.7)
const GROUND_MINE_TRIGGER_Y := 500.0

@export var player_scene: PackedScene
@export var background_scene: PackedScene
@export var robot_scene: PackedScene
@export var ground_mine_scene: PackedScene
@export var void_raptor_scene: PackedScene

var _player: Node2D = null
var _status_label: Label = null
var _pending_ground_mines: Array[Node2D] = []

func _ready() -> void:
	_setup_background()
	_setup_player()
	_setup_status_label()
	_show_help()

func _process(_delta: float) -> void:
	_update_ground_mine_activation()

func _setup_background() -> void:
	if background_scene == null:
		return
	var bg := background_scene.instantiate() as Node2D
	add_child(bg)
	bg.name = "Background"

func _setup_player() -> void:
	if player_scene == null:
		return
	_player = player_scene.instantiate() as Node2D
	_player.name = "Player"
	add_child(_player)
	_player.global_position = Vector2(180, 340)

func _setup_status_label() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	_status_label = Label.new()
	_status_label.position = Vector2(20, 20)
	_status_label.add_theme_font_size_override("font_size", 22)
	_status_label.text = ""
	canvas.add_child(_status_label)

func _show_help() -> void:
	if _status_label == null:
		return
	_status_label.text = "1 Robot | 2 Ground Mine | 3 Void Raptor | C Clear Enemies | R Reset Player"

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

func _spawn_robot() -> void:
	var robot := _spawn_scene(robot_scene, Vector2(930, 340), "test_enemy") as Node2D
	if robot == null:
		return
	robot.scale = ROBOT_SCALE

func _spawn_ground_mine() -> void:
	var mine := _spawn_scene(ground_mine_scene, Vector2(860, 605), "test_enemy") as Node2D
	if mine == null:
		return
	mine.set_physics_process(false)
	mine.set_process(false)
	_pending_ground_mines.append(mine)
	_set_status("Ground mine armed. It will wake only below Y=%d" % int(GROUND_MINE_TRIGGER_Y))

func _spawn_void_raptor() -> void:
	var raptor := _spawn_scene(void_raptor_scene, Vector2(900, 520), "test_enemy") as Node2D
	if raptor == null:
		return
	_set_status("Void Raptor spawned")

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

func _set_status(text: String) -> void:
	if _status_label == null:
		return
	_status_label.text = text + "\n1 Robot | 2 Ground Mine | 3 Void Raptor | C Clear Enemies | R Reset Player"

func stage_has_ground(stage: int = -1) -> bool:
	return true
