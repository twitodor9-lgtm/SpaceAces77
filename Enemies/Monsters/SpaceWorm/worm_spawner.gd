extends Node2D

@export var worm_scene: PackedScene
@export var player_path: NodePath
@export var ground_line_path: NodePath  # Marker2D "GroundLine"

@export var trigger_height_above_ground: float = 140.0 # כמה מעל הקרקע נחשב "נמוך"
@export var cooldown: float = 2.5
@export var telegraph_time: float = 0.55
@export var leap_height: float = 220.0
@export var max_worms: int = 1

var _player: Node2D
var _ground: Node2D
var _cd: float = 0.0

# מצב “ירידה”
var _was_low := false
var _rolled_this_dip := false
var _spawn_this_dip := false

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node2D
	_ground = get_node_or_null(ground_line_path) as Node2D
	print("WormSpawner READY. worm_scene=", worm_scene, " player=", _player, " ground=", _ground)

func _process(delta: float) -> void:
	if worm_scene == null or _player == null or _ground == null:
		return

	_cd = maxf(_cd - delta, 0.0)

	# רק במסכים שמוגדרים עם תולעת
	if not GameBalance.rule("worm_enabled", false):
		_reset_dip_state()
		return

	# קח חוקים מהמסך (אם קיימים)
	cooldown = float(GameBalance.rule("worm_cooldown", cooldown))
	telegraph_time = float(GameBalance.rule("telegraph_time", telegraph_time))
	var chance: float = float(GameBalance.rule("worm_dip_chance", 0.35))

	# לא יותר מתולעת אחת (או כמה שהגדרת)
	if _count_worms() >= max_worms:
		return

	var ground_y: float = _ground.global_position.y
	var trigger_y: float = ground_y - trigger_height_above_ground

	# "נמוך" = השחקן מתחת לקו הסף (קרוב לקרקע)
	var is_low: bool = _player.global_position.y >= trigger_y

	# אם השחקן עלה למעלה -> מאפסים כדי שבפעם הבאה יהיה רול חדש
	if not is_low:
		_reset_dip_state()
		return

	# נכנסנו לנמוך עכשיו (רגע הירידה) -> מגלגלים פעם אחת
	if not _was_low:
		_was_low = true
		_rolled_this_dip = true
		_spawn_this_dip = (randf() < chance)

	# אם הרול הצליח והקולדאון נגמר -> מזמנים פעם אחת
	if _rolled_this_dip and _spawn_this_dip and _cd <= 0.0:
		_spawn_this_dip = false
		_rolled_this_dip = false
		_spawn_worm(_player.global_position.x, ground_y)
		_cd = cooldown

func _spawn_worm(x: float, ground_y: float) -> void:
	print("SPAWN WORM at x=", x, " ground_y=", ground_y)
	var worm := worm_scene.instantiate()
	get_tree().current_scene.add_child(worm)

	# מתחיל קצת “מתחת לקרקע”
	worm.global_position = Vector2(x, ground_y + 90.0)

	if worm.has_method("start_attack"):
		worm.start_attack(x, ground_y, telegraph_time, leap_height)

func _count_worms() -> int:
	return get_tree().get_nodes_in_group("worms").size()

func _reset_dip_state() -> void:
	_was_low = false
	_rolled_this_dip = false
	_spawn_this_dip = false
