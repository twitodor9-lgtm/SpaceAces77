extends Area2D

@export_group("Combat")
@export var max_health: int = 10
@export var player_damage_multiplier: float = 1.0
@export var score_value: int = 100
@export var show_in_ar_hud: bool = false

# =========================
# Movement (Dogfight-like)
# =========================
@export var min_speed: float = 110.0
@export var max_speed: float = 220.0
@export var accel: float = 140.0
@export var base_speed: float = 150.0
@export var turn_rate: float = 1.6
@export var engage_turn_rate: float = 2.2
@export var disengage_turn_rate: float = 1.1
@export var engage_distance: float = 300.0
@export var disengage_distance: float = 135.0
@export var strafe_distance: float = 240.0
@export var strafe_interval_min: float = 1.0
@export var strafe_interval_max: float = 2.1
@export var strafe_strength: float = 120.0
@export var y_offset_range: float = 160.0
@export var aim_lead: float = 0.18

var _speed: float = 0.0
var _y_offset: float = 0.0
var _strafe_dir: float = 1.0
var _strafe_timer: float = 0.0

# =========================
# Entry
# =========================
@export var enter_margin: float = 80.0
var _entering: bool = true

# =========================
# Shooting
# =========================
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 200.0
@export var fire_interval: float = 0.9
@export var clip_size: int = 8
@export var reload_time: float = 2.5
@export var aim_spread_deg: float = 6.0
@export var debug_shot_telemetry: bool = true

var _ammo: int = 0
var _reloading: bool = false
var _fire_cd: float = 0.0

# =========================
# CONFUSION (Player Loop)
# =========================
var confused: bool = false
@export var confusion_time: float = 1.2
@onready var confusion_label: Label = null

# =========================
# Lifetime
# =========================
@export var auto_despawn_time: float = 0.0

var _dead: bool = false
var _health: int = 0

func _ready() -> void:
	add_to_group("air_enemies")
	add_to_group("enemies")
	if show_in_ar_hud:
		add_to_group("health_bar_target")

	_health = max(1, max_health)
	_y_offset = randf_range(-y_offset_range, y_offset_range)
	_speed = base_speed
	_ammo = clip_size
	_fire_cd = randf_range(0.0, fire_interval)
	_pick_new_strafe()

	# --- Confusion label (❗❓) ---
	confusion_label = Label.new()
	confusion_label.text = "❗❓"
	confusion_label.add_theme_font_size_override("font_size", 22)
	confusion_label.add_theme_color_override("font_color", Color.YELLOW)
	confusion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confusion_label.visible = false
	add_child(confusion_label)
	confusion_label.position = Vector2(-18, -40)

	rotation = PI  # נכנס מימין שמאלה

	if auto_despawn_time > 0.0:
		get_tree().create_timer(auto_despawn_time).timeout.connect(func():
			if is_instance_valid(self):
				queue_free()
		)


func _process(delta: float) -> void:
	if confused:
		_move_forward(delta)
		return

	if _fire_cd > 0.0:
		_fire_cd -= delta
	if _strafe_timer > 0.0:
		_strafe_timer -= delta
	else:
		_pick_new_strafe()

	_speed = clamp(_speed, min_speed, max_speed)

	if _entering:
		_enter_move(delta)
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_move_forward(delta)
		return

	_ai_fly_like_player(player, delta)
	_move_forward(delta)
	_try_shoot(player)


# -------------------------
# Entry
# -------------------------
func _enter_move(delta: float) -> void:
	_speed = _move_toward(_speed, base_speed, accel * delta)
	_move_forward(delta)

	var w := get_viewport_rect().size.x
	if global_position.x < w - enter_margin:
		_entering = false


# -------------------------
# Movement
# -------------------------
func _move_forward(delta: float) -> void:
	position += Vector2(_speed, 0).rotated(rotation) * delta


func _ai_fly_like_player(player: Node2D, delta: float) -> void:
	var player_velocity := Vector2.ZERO
	if "forward_speed" in player:
		player_velocity = Vector2(float(player.forward_speed), 0.0).rotated(player.rotation)

	var lead_target := player.global_position + player_velocity * aim_lead
	var dist_to_player := global_position.distance_to(player.global_position)
	var side := signf(global_position.x - player.global_position.x)
	if absf(side) < 0.1:
		side = _strafe_dir

	var target := lead_target + Vector2(side * strafe_strength * _strafe_dir, _y_offset)
	if dist_to_player < disengage_distance:
		target = player.global_position + Vector2(side * strafe_distance, _y_offset * 0.55)
	elif dist_to_player < strafe_distance:
		target += Vector2(0.0, _strafe_dir * strafe_strength * 0.5)

	var to_target := target - global_position
	var desired_angle := to_target.angle()

	var rate := turn_rate
	if dist_to_player < disengage_distance:
		rate = disengage_turn_rate
	elif dist_to_player < engage_distance:
		rate = engage_turn_rate

	var target_speed := base_speed
	if dist_to_player < disengage_distance:
		target_speed = max_speed
	elif dist_to_player < engage_distance:
		target_speed = lerpf(base_speed, max_speed, 0.35)
	else:
		target_speed = lerpf(min_speed, base_speed, 0.75)
	_speed = _move_toward(_speed, target_speed, accel * delta)

	var diff := wrapf(desired_angle - rotation, -PI, PI)
	rotation += clamp(diff, -rate * delta, rate * delta)


# -------------------------
# Shooting
# -------------------------
func _try_shoot(player: Node2D) -> void:
	if confused or _reloading or bullet_scene == null:
		return

	if _ammo <= 0:
		_log_shot_event("reload_start", {"ammo": _ammo, "clip": clip_size, "reload": reload_time})
		_start_reload()
		return

	if _fire_cd > 0.0:
		return

	if player == null:
		_log_shot_event("skip_no_player")
		return

	if player.has_method("is_hidden") and player.is_hidden():
		_log_shot_event("blocked_hidden", {"ammo": _ammo, "cooldown_left": snapped(_fire_cd, 0.01)})
		return

	var low_cover_active := ("is_hidden_low" in player and player.is_hidden_low)
	var accuracy_mul := 1.0
	if low_cover_active:
		accuracy_mul = float(GameBalance.rule("low_cover_accuracy_mul", 1.0))
		if accuracy_mul <= 0.0:
			_log_shot_event("blocked_low_cover", {"accuracy_mul": accuracy_mul})
			return

	var player_velocity := Vector2.ZERO
	if "forward_speed" in player:
		player_velocity = Vector2(float(player.forward_speed), 0.0).rotated(player.rotation)
	var aim_target := player.global_position + player_velocity * aim_lead
	var angle_to_player := (aim_target - global_position).angle()
	var diff: float = absf(wrapf(angle_to_player - rotation, -PI, PI))
	var allowed_angle := deg_to_rad(30.0)
	if low_cover_active:
		allowed_angle *= clampf(accuracy_mul, 0.15, 1.0)

	if diff > allowed_angle:
		_log_shot_event("blocked_angle", {
			"low_cover": low_cover_active,
			"accuracy_mul": snapped(accuracy_mul, 0.01),
			"angle_diff_deg": snapped(rad_to_deg(diff), 0.1),
			"allowed_angle_deg": snapped(rad_to_deg(allowed_angle), 0.1),
			"distance": snapped(global_position.distance_to(player.global_position), 0.1),
		})
		return

	var shot_cd := fire_interval * randf_range(0.92, 1.12)
	_fire_cd = shot_cd
	var final_spread := _shoot(player, accuracy_mul)
	_ammo -= 1
	_log_shot_event("fired", {
		"low_cover": low_cover_active,
		"accuracy_mul": snapped(accuracy_mul, 0.01),
		"angle_diff_deg": snapped(rad_to_deg(diff), 0.1),
		"allowed_angle_deg": snapped(rad_to_deg(allowed_angle), 0.1),
		"spread_deg": snapped(final_spread, 0.1),
		"bullet_speed": bullet_speed,
		"fire_cd": snapped(shot_cd, 0.01),
		"ammo_left": _ammo,
		"distance": snapped(global_position.distance_to(player.global_position), 0.1),
	})

func _looks_like_enemy_instance(inst: Node) -> bool:
	# פיוז: אם מישהו שם Enemy במקום Bullet ב-bullet_scene — לעצור כאן.
	var scr: Script = inst.get_script()

	if scr is Script:
		var p := (scr as Script).resource_path.to_lower()
		# אם זה "bullet" זה כנראה תקין. אם זה enemy.gd/ground_enemy.gd — זה אסון.
		if p.find("bullet") == -1:
			if p.ends_with("/enemy.gd") or p.ends_with("/ground_enemy.gd") or p.find("ground_enemy") != -1:
				return true

	# עוד סימנים מחשידים (עדיין לפני add_child):
	if inst.has_method("on_player_loop") and inst.has_method("take_damage"):
		return true
	if inst.has_node("ShootTimer"):
		return true

	return false


func _shoot(player: Node2D = null, accuracy_mul: float = 1.0) -> float:
	if not has_node("Muzzle"):
		return 0.0

	if bullet_scene == null:
		return 0.0

	var inst := bullet_scene.instantiate()
	if inst == null or not (inst is Node):
		push_error("Enemy: bullet_scene did not instantiate a Node.")
		return 0.0

	var bullet_node := inst as Node

	# 🚨 פיוז בטיחותי נגד ספאון אינסופי
	if _looks_like_enemy_instance(bullet_node):
		push_error("Enemy: bullet_scene points to an ENEMY scene (not a bullet). Fix bullet_scene in Inspector.")
		# כדי לא לספאם כל פריים:
		_fire_cd = 999.0
		_reloading = true
		bullet_node.queue_free()
		return 0.0

	# נכניס לעולם
	get_tree().current_scene.add_child(bullet_node)

	# מיקום/כיוון
	var muzzle := $Muzzle as Node2D
	if bullet_node is Node2D:
		(bullet_node as Node2D).global_position = muzzle.global_position

	var dir := Vector2.RIGHT.rotated(rotation)
	if player != null:
		var player_velocity := Vector2.ZERO
		if "forward_speed" in player:
			player_velocity = Vector2(float(player.forward_speed), 0.0).rotated(player.rotation)
		dir = (player.global_position + player_velocity * aim_lead - muzzle.global_position).normalized()
		if dir.length() < 0.001:
			dir = Vector2.RIGHT.rotated(rotation)

	var spread := aim_spread_deg
	if accuracy_mul < 1.0:
		spread = lerpf(aim_spread_deg, aim_spread_deg * 2.8, 1.0 - clampf(accuracy_mul, 0.0, 1.0))
	if spread > 0.0:
		dir = dir.rotated(deg_to_rad(randf_range(-spread, spread)))

	# חשוב למגן: לסמן ככדור אויב
	bullet_node.add_to_group("enemy_bullets")

	# אם לכדור יש setup – זה המצב האידיאלי
	if bullet_node.has_method("setup"):
		bullet_node.call("setup", dir, bullet_speed)
	elif bullet_node is Node2D:
		# fallback: רק סיבוב, בלי מהירות
		(bullet_node as Node2D).rotation = dir.angle()

	return spread


func _start_reload() -> void:
	_reloading = true
	get_tree().create_timer(reload_time).timeout.connect(func():
		if is_instance_valid(self):
			_ammo = clip_size
			_reloading = false
	)


# -------------------------
# Player LOOP reaction
# -------------------------
func on_player_loop() -> void:
	if confused:
		return

	confused = true
	confusion_label.visible = true
	_fire_cd = confusion_time

	get_tree().create_timer(confusion_time).timeout.connect(func():
		if is_instance_valid(self):
			confused = false
			confusion_label.visible = false
	)


# -------------------------
# Helper
# -------------------------
func _move_toward(v: float, to: float, step: float) -> float:
	if v < to:
		return min(v + step, to)
	return max(v - step, to)

func _pick_new_strafe() -> void:
	_strafe_dir = -1.0 if randf() < 0.5 else 1.0
	_strafe_timer = randf_range(strafe_interval_min, strafe_interval_max)
	_y_offset = randf_range(-y_offset_range, y_offset_range)

func _log_shot_event(event_name: String, extra: Dictionary = {}) -> void:
	if not debug_shot_telemetry:
		return
	var parts: Array[String] = ["[AIR-AI]", name, event_name]
	for key in extra.keys():
		parts.append("%s=%s" % [String(key), String(extra[key])])
	print(" ".join(parts))


func _award_score() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("add_score"):
		scene.call("add_score", score_value)

func take_damage(amount: int) -> void:
	if _dead:
		return
	var final_damage := maxi(1, int(round(float(amount) * player_damage_multiplier)))
	_health -= final_damage
	print("TAKE_DAMAGE:", name, " amount=", amount, " final=", final_damage, " health=", _health)
	if _health <= 0:
		_dead = true
		_award_score()
		queue_free()
