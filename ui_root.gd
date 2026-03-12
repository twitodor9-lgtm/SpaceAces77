extends CanvasLayer

signal next_stage_pressed

# --- Paths (לקבוע ב-Inspector של UIRoot) ---
@export var player_path: NodePath
@export var star_punch_path: NodePath
@export var low_zone_ratio: float = 0.45
@onready var score_label: Label = $UI/ScoreLabel

func set_score(value: int) -> void:
	score_label.text = str(value)
# --- UI Nodes (לפי המבנה שלך: בתוך HUD) ---
@onready var hud: Control = $HUD
@onready var stage_label: Label = $UI/StageLabel
#@onready var star_punch_bar: ProgressBar = $HUD/StarPunchBar
@onready var low_label: Label = $UI/LowAltitudeLabel
@onready var boss_bar: ProgressBar = $UI/BossBar
@onready var star_punch_bar: ProgressBar = $UI/StarPunchBar
# Stage clear
@onready var stage_clear_label: Label = $"STAGE CLEAR"
@onready var next_button: Button = $NEXT

var player: Node2D
var star_punch: Node

func _ready() -> void:
	player = get_node_or_null(player_path) as Node2D
	star_punch = get_node_or_null(star_punch_path)

	# ברירת מחדל: מסך סיום מוסתר
	stage_clear_label.visible = false
	next_button.visible = false
	next_button.pressed.connect(_on_next_pressed)
	print("stage_clear_label=", stage_clear_label, " next_button=", next_button)
func _process(_delta: float) -> void:
	_update_star_punch_bar()
	_update_low_altitude()
	_update_boss_bar()

# ---------------- Stage Clear ----------------
func show_stage_clear() -> void:
	stage_clear_label.visible = true
	next_button.visible = true
	get_tree().paused = true

func hide_stage_clear() -> void:
	stage_clear_label.visible = false
	next_button.visible = false
	get_tree().paused = false

func _on_next_pressed() -> void:
	hide_stage_clear()
	emit_signal("next_stage_pressed")

# ---------------- HUD Updates ----------------
func set_stage(n: int) -> void:
	stage_label.text = "STAGE %d" % n

func _update_star_punch_bar() -> void:
	if star_punch == null:
		star_punch_bar.visible = false
		return

	if not ("cooldown" in star_punch and "cooldown_left" in star_punch):
		star_punch_bar.visible = false
		return

	star_punch_bar.visible = true
	var cd: float = float(star_punch.cooldown)
	var left: float = float(star_punch.cooldown_left)
	star_punch_bar.value = (1.0 if cd <= 0.0 else 1.0 - clamp(left / cd, 0.0, 1.0))

func _update_low_altitude() -> void:
	if player == null:
		low_label.visible = false
		return

	var r := _get_visible_world_rect()
	var low_line_y := r.position.y + r.size.y * (1.0 - low_zone_ratio)
	low_label.visible = player.global_position.y > low_line_y

func _update_boss_bar() -> void:
	var boss_node: Node = get_tree().get_first_node_in_group("boss")
	if boss_node == null:
		boss_bar.visible = false
		return

	var boss_item := boss_node as CanvasItem
	if boss_item == null or not boss_item.visible:
		boss_bar.visible = false
		return

	if boss_node.has_method("get_health_ratio"):
		boss_bar.visible = true
		boss_bar.value = boss_node.get_health_ratio() * 100.0
	else:
		boss_bar.visible = false

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
