extends Node2D

@export var mine_scene: PackedScene
@export var player_group: StringName = &"player"

@export var trigger_player_y: float = 520.0   # כשהשחקן יורד מתחת ל-Y הזה (למטה) -> מתחילים מוקשים
@export var ground_y: float = 600.0           # ה-Y של "פני הקרקע" שממנו המוקש יוצא

@export var spawn_every: float = 1.2
@export var max_active_mines: int = 3
@export var spawn_x_radius: float = 260.0

var _player: Node2D
var _cooldown: float = 0.0

func _ready() -> void:
	_player = get_tree().get_first_node_in_group(player_group) as Node2D
	if _player == null:
		push_warning("GroundMineSpawner: no player found in group '%s'." % [player_group])

func _process(delta: float) -> void:
	if mine_scene == null or _player == null:
		return

	# אם השחקן גבוה מדי — לא עושים כלום
	if _player.global_position.y < trigger_player_y:
		_cooldown = 0.0
		return

	# מגבלת כמות מוקשים פעילים
	var active: int = get_tree().get_nodes_in_group(&"ground_mines").size()
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
	mine.add_to_group(&"ground_mines")
