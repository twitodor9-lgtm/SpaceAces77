extends CanvasLayer
@onready var stage_label: Label = $StageLabel
@export var player_path: NodePath
@export var star_punch_path: NodePath

@onready var player := get_node(player_path) as Node2D
@onready var star_punch := get_node(star_punch_path)
@onready var bar := $StarPunchBar as ProgressBar
@onready var low_label := $LowAltitudeLabel as Label
@onready var boss_bar: ProgressBar = $BossBar

func _process(_delta: float) -> void:
	_update_star_punch_bar()
	_update_low_altitude()
	_update_star_punch_bar()
	_update_low_altitude()
	_update_boss_bar()
func _update_star_punch_bar() -> void:
	if star_punch == null:
		return
	if not ("cooldown" in star_punch and "cooldown_left" in star_punch):
		bar.visible = false
		return

	bar.visible = true
	var cd: float = star_punch.cooldown
	var left: float = star_punch.cooldown_left
	bar.value = (1.0 if cd <= 0.0 else 1.0 - clamp(left / cd, 0.0, 1.0))

func _update_low_altitude() -> void:
	if player == null:
		low_label.visible = false
		return
	low_label.visible = player.is_hidden_low

func _get_visible_world_rect() -> Rect2:
	var vp := get_viewport().get_visible_rect().size

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
func _update_boss_bar() -> void:
	
	var boss_node: Node = get_tree().get_first_node_in_group("boss")
	if boss_node == null:
		boss_bar.visible = false
		return

	var boss_item: CanvasItem = boss_node as CanvasItem
	if boss_item == null or not boss_item.visible:
		boss_bar.visible = false
		return

	if boss_node.has_method("get_health_ratio"):
		boss_bar.visible = true
		boss_bar.value = boss_node.get_health_ratio() * 100.0

	else:
		boss_bar.visible = false
func set_stage(n: int) -> void:
	stage_label.text = "STAGE %d" % n
