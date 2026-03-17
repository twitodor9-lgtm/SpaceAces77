extends CanvasLayer

signal next_stage_pressed

@export var player_path: NodePath
@export var star_punch_path: NodePath

@onready var score_label: Label = $UI/ScoreLabel
@onready var hud: Control = $HUD
@onready var stage_label: Label = $UI/StageLabel
@onready var low_label: Label = $UI/LowAltitudeLabel
@onready var threat_labels: Array[Label] = [
	$UI/ThreatList/Threat1,
	$UI/ThreatList/Threat2,
	$UI/ThreatList/Threat3,
]
@onready var star_punch_bar: ProgressBar = $UI/StarPunchBar
@onready var stage_clear_label: Label = $"STAGE CLEAR"
@onready var next_button: Button = $NEXT

var player: Node2D
var star_punch: Node
var _threat_memory: Dictionary = {}
var _low_flash_t: float = 0.0
var _low_recent_t: float = 0.0
var _stage_label_t: float = 0.0

func set_score(value: int) -> void:
	score_label.text = str(value)

func _bind_runtime_refs() -> void:
	player = get_node_or_null(player_path) as Node2D
	star_punch = get_node_or_null(star_punch_path)

func _ready() -> void:
	_bind_runtime_refs()
	stage_clear_label.visible = false
	next_button.visible = false
	next_button.pressed.connect(_on_next_pressed)
	print("stage_clear_label=", stage_clear_label, " next_button=", next_button)

func _process(delta: float) -> void:
	_update_star_punch_bar()
	_update_low_altitude(delta)
	_update_stage_label(delta)
	_update_threat_list(delta)

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

func set_stage(n: int) -> void:
	stage_label.text = "STAGE %d" % n
	stage_label.visible = true
	stage_label.modulate = Color(0.42, 1.0, 0.66, 0.92)
	_stage_label_t = 2.4

func _update_stage_label(delta: float) -> void:
	if not stage_label.visible:
		return
	_stage_label_t = maxf(_stage_label_t - delta, 0.0)
	if _stage_label_t <= 0.0:
		stage_label.visible = false
		return
	var alpha := 1.0
	if _stage_label_t < 0.8:
		alpha = _stage_label_t / 0.8
	stage_label.modulate = Color(0.42, 1.0, 0.66, 0.92 * alpha)

func _update_star_punch_bar() -> void:
	if star_punch == null:
		star_punch_bar.visible = false
		return

	if not ("cooldown" in star_punch):
		star_punch_bar.visible = false
		return

	star_punch_bar.visible = true
	var cd: float = float(star_punch.cooldown)
	var left: float = 0.0
	if "cooldown_left" in star_punch:
		left = float(star_punch.cooldown_left)
	star_punch_bar.visible = true
	star_punch_bar.value = (1.0 if cd <= 0.0 else 1.0 - clamp(left / cd, 0.0, 1.0))

func _update_low_altitude(delta: float) -> void:
	if player == null:
		low_label.visible = false
		return

	if "is_hidden_low" in player and player.is_hidden_low:
		_low_flash_t += delta * 7.0
		_low_recent_t = 0.9
		low_label.visible = true
		var a := 0.45 + (sin(_low_flash_t) * 0.25 + 0.25)
		low_label.modulate = Color(0.5, 1.0, 0.7, a)
	else:
		_low_flash_t = 0.0
		low_label.visible = false
	_low_recent_t = maxf(_low_recent_t - delta, 0.0)

func _remember_threat(node: Node, default_tag: String) -> void:
	if node == null or not is_instance_valid(node) or not node.has_method("get_health_ratio"):
		return
	var key := str(node.get_instance_id())
	var display_name := String(node.get("ar_threat_text") if "ar_threat_text" in node else "")
	if display_name.strip_edges() == "":
		display_name = String(node.name).replace("_", " ").to_upper()
	var type_name := String(node.get("ar_threat_type") if "ar_threat_type" in node else "")
	if type_name.strip_edges() == "":
		type_name = default_tag
	_threat_memory[key] = {
		"node": node,
		"tag": type_name,
		"name": display_name,
		"ttl": 1.25,
	}

func _update_threat_list(delta: float) -> void:
	var boss := get_tree().get_first_node_in_group("boss")
	if boss != null:
		_remember_threat(boss, "BOSS")

	if _low_recent_t <= 0.0:
		for node in get_tree().get_nodes_in_group("health_bar_target"):
			if node != null:
				_remember_threat(node, "MONSTER")

	var rows: Array[Dictionary] = []
	for key in _threat_memory.keys():
		var entry: Dictionary = _threat_memory[key]
		entry["ttl"] = float(entry.get("ttl", 0.0)) - delta
		var node_ref: Variant = entry.get("node", null)
		var alive := node_ref != null and is_instance_valid(node_ref)
		var node: Node = node_ref if alive else null
		if alive:
			var item := node as CanvasItem
			alive = item != null and item.visible and node.has_method("get_health_ratio")
		if not alive and float(entry.get("ttl", 0.0)) <= 0.0:
			_threat_memory.erase(key)
			continue

		var ratio := 0.0
		if alive and node != null:
			ratio = float(node.call("get_health_ratio"))

		rows.append({
			"text": "%s // %s // %d%%" % [String(entry.get("tag", "TARGET")), String(entry.get("name", "UNKNOWN")), int(round(ratio * 100.0))],
			"alpha": clamp(float(entry.get("ttl", 0.0)), 0.18, 1.0),
			"priority": 2 if String(entry.get("tag", "")).contains("BOSS") else 1,
			"ratio": ratio,
		})

	rows.sort_custom(func(a: Dictionary, b: Dictionary):
		if int(a.get("priority", 0)) != int(b.get("priority", 0)):
			return int(a.get("priority", 0)) > int(b.get("priority", 0))
		return float(a.get("ratio", 0.0)) > float(b.get("ratio", 0.0))
	)

	for i in range(threat_labels.size()):
		var lbl: Label = threat_labels[i]
		if i < rows.size():
			var row: Dictionary = rows[i]
			lbl.visible = true
			lbl.text = String(row.get("text", ""))
			var alpha := float(row.get("alpha", 1.0)) * (0.72 - i * 0.12)
			lbl.modulate = Color(0.4, 1.0, 0.64, alpha)
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
