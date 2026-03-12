extends Node2D

@export var mine_scene: PackedScene
@export var player_group: StringName = &"player"

# ⬅️ זה השם האמיתי של הקבוצה אצלך
@export var mine_group: StringName = &"hazards"

@export var trigger_player_y: float = 520.0
@export var ground_y: float = 600.0
@export var ground_line_path: NodePath = ^"../GroundLine"

@export var spawn_every: float = 1.2
@export var max_active_mines: int = 3
@export var spawn_x_radius: float = 260.0

@export var debug_print: bool = true

var _player: Node2D
var _cooldown: float = 0.0

func _ready() -> void:
	_player = get_tree().get_first_node_in_group(player_group) as Node2D
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"Player") as Node2D
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node2D

	if _player == null:
		push_warning("GroundMineSpawner: no player found in group '%s' (also tried 'Player'/'player')." % [player_group])

	# ground_y לפי GroundLine אם יש
	if ground_line_path != NodePath("") and has_node(ground_line_path):
		var n := get_node(ground_line_path)
		if n is Node2D:
			ground_y = (n as Node2D).global_position.y
			if debug_print:
				print("[GroundMineSpawner] ground_y from GroundLine => ", ground_y)

	if mine_scene == null:
		push_warning("GroundMineSpawner: mine_scene is NOT set. Assign your mine scene in the Inspector.")

func _process(delta: float) -> void:
	if mine_scene == null or _player == null:
		return

	# אם השחקן גבוה מדי — לא עושים כלום
	if _player.global_position.y < trigger_player_y:
		_cooldown = 0.0
		return

	# מגבלת כמות לפי הקבוצה האמיתית: hazards
	var active: int = get_tree().get_nodes_in_group(mine_group).size()
	if active >= max_active_mines:
		return

	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = spawn_every

	var mine := mine_scene.instantiate() as Node2D
	get_parent().add_child(mine)

	var x: float = _player.global_position.x + randf_range(-spawn_x_radius, spawn_x_radius)
	mine.global_position = Vector2(x, ground_y)

	# לוודא שהמוקש אכן בקבוצה hazards גם אם שכחת בסצנה
	mine.add_to_group(mine_group)

	if debug_print:
		print("[MINE SPAWN] pos=", mine.global_position, " active_in_group=", active, " group=", mine_group)
