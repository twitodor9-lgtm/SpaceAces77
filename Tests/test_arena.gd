extends Node2D

@export var player_scene: PackedScene
@export var background_scene: PackedScene
@export var robot_scene: PackedScene
@export var ground_mine_scene: PackedScene
@export var void_raptor_scene: PackedScene

var _player: Node2D = null
var _status_label: Label = null

func _ready() -> void:
	_setup_background()
	_setup_player()
	_setup_status_label()
	_show_help()

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
	_spawn_scene(robot_scene, Vector2(930, 340), "test_enemy")

func _spawn_ground_mine() -> void:
	_spawn_scene(ground_mine_scene, Vector2(860, 585), "test_enemy")

func _spawn_void_raptor() -> void:
	_spawn_scene(void_raptor_scene, Vector2(900, 520), "test_enemy")

func _spawn_scene(scene: PackedScene, pos: Vector2, group_name: StringName) -> void:
	if scene == null:
		return
	var inst := scene.instantiate()
	if inst == null:
		return
	add_child(inst)
	if inst is Node2D:
		(inst as Node2D).global_position = pos
	inst.add_to_group(group_name)

func _clear_test_enemies() -> void:
	for n in get_tree().get_nodes_in_group("test_enemy"):
		n.queue_free()

func _reset_player() -> void:
	if is_instance_valid(_player):
		_player.queue_free()
	_setup_player()

func stage_has_ground(stage: int = -1) -> bool:
	return true
