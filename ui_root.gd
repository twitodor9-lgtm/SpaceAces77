extends CanvasLayer

signal next_stage_pressed

# --- Paths (לקבוע ב-Inspector של UIRoot) ---
@export var player_path: NodePath
@export var star_punch_path: NodePath
@onready var score_label: Label = $UI/ScoreLabel

func set_score(value: int) -> void:
	score_label.text = str(value)
# --- UI Nodes (לפי המבנה שלך: בתוך HUD) ---
@onready var hud: Control = $HUD
@onready var stage_label: Label = $UI/StageLabel
#@onready var star_punch_bar: ProgressBar = $HUD/StarPunchBar
@onready var low_label: Label = $UI/LowAltitudeLabel
@onready var boss_bracket_left: Label = $UI/BossBracketLeft
@onready var boss_bar_label: Label = $UI/BossBarLabel
@onready var boss_bar: ProgressBar = $UI/BossBar
@onready var boss_bracket_right: Label = $UI/BossBracketRight
@onready var star_punch_bar: ProgressBar = $UI/StarPunchBar
# Stage clear
@onready var stage_clear_label: Label = $"STAGE CLEAR"
@onready var next_button: Button = $NEXT

var player: Node2D
var star_punch: Node

func _bind_runtime_refs() -> void:
	player = get_node_or_null(player_path) as Node2D
	star_punch = get_node_or_null(star_punch_path)

func _ready() -> void:
	_bind_runtime_refs()

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

func _update_low_altitude(delta: float) -> void:
	if player == null:
		low_label.visible = false
		return
	if player.is_hidden_low:
		_low_flash_t += delta * 7.0
		low_label.visible = true
		low_label.modulate.a = 0.45 + (sin(_low_flash_t) * 0.25 + 0.25)
	else:
		_low_flash_t = 0.0
		low_label.visible = false

func _remember_threat(node: Node, tag: String) -> void:
	if node == null or not node.has_method("get_health_ratio"):
		return
	var key := str(node.get_instance_id())
	var display_name := String(node.name).replace("_", " ").to_upper()
	_threat_memory[key] = {
		"node": node,
		"tag": tag,
		"name": display_name,
		"ttl": 1.25,
	}

func _update_threat_list(delta: float) -> void:
	var boss := get_tree().get_first_node_in_group("boss")
	if boss != null:
		_remember_threat(boss, "[AR] BOSS")
	for node in get_tree().get_nodes_in_group("health_bar_target"):
		if node != null:
			_remember_threat(node, "[AR] MONSTER")

	var rows: Array = []
	for key in _threat_memory.keys():
		var entry = _threat_memory[key]
		entry["ttl"] = float(entry["ttl"]) - delta
		var node: Node = entry["node"]
		var alive := node != null and is_instance_valid(node)
		if alive:
			var item := node as CanvasItem
			alive = item != null and item.visible and node.has_method("get_health_ratio")
		if not alive and float(entry["ttl"]) <= 0.0:
			_threat_memory.erase(key)
			continue
		var ratio := 0.0
		if alive:
			ratio = float(node.call("get_health_ratio"))
		rows.append({
			"text": "%s // %s // %d%%" % [entry["tag"], entry["name"], int(round(ratio * 100.0))],
			"alpha": clamp(float(entry["ttl"]), 0.18, 1.0),
			"priority": 2 if String(entry["tag"]).contains("BOSS") else 1,
			"ratio": ratio,
		})
	rows.sort_custom(func(a, b): return a["priority"] > b["priority"] if a["priority"] != b["priority"] else a["ratio"] > b["ratio"])
	for i in range(threat_labels.size()):
		var lbl := threat_labels[i]
		if i < rows.size():
			lbl.visible = true
			lbl.text = rows[i]["text"]
			var c := lbl.modulate
			c.a = rows[i]["alpha"] * (0.72 - i * 0.12)
			lbl.modulate = c
		else:
			lbl.visible = false

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
