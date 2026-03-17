extends Node2D
var _prev_hidden := false
@export var player_path: NodePath
@export var GroundLine_path: NodePath
var _player: Node2D
var _ground_line: Node2D
@export var low_altitude_margin: float = 140.0

func _ready() -> void:
	_player = get_node_or_null(player_path) as Node2D
	_ground_line = get_node_or_null(GroundLine_path) as Node2D
	if _ground_line == null:
		_ground_line = get_tree().current_scene.get_node_or_null("GroundLine") as Node2D

func _process(_delta: float) -> void:
	if _player == null:
		return

	# אם המסך הזה לא תומך ב-"מחבוא נמוך" -> תמיד כבוי
	if not GameBalance.rule("low_cover_enabled", false):
		_player.is_hidden_low = false
		return

	var low_line_y := _get_low_line_y()
	var is_low := _player.global_position.y >= low_line_y
	_player.is_hidden_low = is_low
	if is_low != _prev_hidden:
		print("LOW COVER:", is_low, "  player_y=", _player.global_position.y)
	_prev_hidden = is_low
func _get_visible_world_rect() -> Rect2:
	var vp := get_viewport_rect().size
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


func _get_low_line_y() -> float:
	if _ground_line == null or not is_instance_valid(_ground_line):
		_ground_line = get_tree().current_scene.get_node_or_null("GroundLine") as Node2D

	if _ground_line != null:
		return _ground_line.global_position.y - low_altitude_margin

	var r := _get_visible_world_rect()
	var low_ratio := float(GameBalance.rule("low_line_ratio", 0.18))
	return r.position.y + r.size.y * (1.0 - low_ratio)
