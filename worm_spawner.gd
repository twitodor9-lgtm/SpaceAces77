extends Node2D

@export var worm_scene: PackedScene
@export var player_path: NodePath
@export var ground_line_path: NodePath  # Marker2D "GroundLine"

@export var trigger_height_above_ground: float = 140.0  # כמה גבוה מעל הקרקע זה עדיין "מסוכן"
@export var cooldown: float = 2.5
@export var telegraph_time: float = 0.55
@export var leap_height: float = 220.0
@export var max_worms: int = 1

var _player: Node2D
var _ground: Node2D
var _cd: float = 0.0
var _armed: bool = true

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node2D
	_ground = get_node_or_null(ground_line_path) as Node2D
	print("WormSpawner READY. worm_scene=", worm_scene, " player=", _player, " ground=", _ground)

func _process(delta: float) -> void:
	if worm_scene == null or _player == null or _ground == null:
		return

	_cd = maxf(_cd - delta, 0.0)
	if _count_worms() >= max_worms:
		return

	var ground_y: float = _ground.global_position.y
	var trigger_y: float = ground_y - trigger_height_above_ground

	# אם השחקן גבוה (מעל קו הסף) — “מדריכים” מחדש ומחכים
	if _player.global_position.y < trigger_y:
		_armed = true
		return

	# אם השחקן נמוך מספיק, ורק פעם אחת עד שיעלה שוב
	if not _armed or _cd > 0.0:
		return

	_spawn_worm(_player.global_position.x, ground_y)
	_cd = cooldown
	_armed = false

func _spawn_worm(x: float, ground_y: float) -> void:
	print("SPAWN WORM at x=", x, " ground_y=", ground_y)
	var worm := worm_scene.instantiate()
	get_tree().current_scene.add_child(worm)
	worm.global_position = Vector2(x, ground_y + 90.0)

	if worm.has_method("start_attack"):
		worm.start_attack(x, ground_y, telegraph_time, leap_height)

func _count_worms() -> int:
	return get_tree().get_nodes_in_group("worms").size()
