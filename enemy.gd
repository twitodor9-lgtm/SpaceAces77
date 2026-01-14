extends Area2D

# =========================
# Movement (Dogfight-like)
# =========================
@export var min_speed: float = 110.0
@export var max_speed: float = 220.0
@export var accel: float = 140.0
@export var base_speed: float = 150.0
@export var turn_rate: float = 1.6
@export var engage_turn_rate: float = 2.2
@export var engage_distance: float = 520.0

@export var y_offset_range: float = 160.0
@export var aim_lead: float = 0.18

var _speed: float = 0.0
var _y_offset: float = 0.0

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
@export var life_time: float = 12.0


func _ready() -> void:
	add_to_group("air_enemies")
	add_to_group("enemies")

	_y_offset = randf_range(-y_offset_range, y_offset_range)
	_speed = base_speed
	_ammo = clip_size
	_fire_cd = randf_range(0.0, fire_interval)

	# --- Confusion label (❓❓❓) ---
	confusion_label = Label.new()
	confusion_label.text = "❗❓"
	confusion_label.add_theme_font_size_override("font_size", 22)
	confusion_label.add_theme_color_override("font_color", Color.YELLOW)
	confusion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confusion_label.visible = false
	add_child(confusion_label)
	confusion_label.position = Vector2(-18, -40)

	rotation = PI  # נכנס מימין שמאלה

	get_tree().create_timer(life_time).timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)


func _process(delta: float) -> void:
	if confused:
		_move_forward(delta)
		return

	if _fire_cd > 0.0:
		_fire_cd -= delta

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
	_try_shoot()


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
	var target := player.global_position + Vector2(0, _y_offset)
	var to_target := target - global_position

	var desired_angle := to_target.angle()
	var dist := to_target.length()

	var rate := turn_rate
	if dist < engage_distance:
		rate = engage_turn_rate

	var diff = wrapf(desired_angle - rotation, -PI, PI)
	rotation += clamp(diff, -rate * delta, rate * delta)


# -------------------------
# Shooting
# -------------------------
func _try_shoot() -> void:
	if confused or _reloading or bullet_scene == null:
		return

	if _ammo <= 0:
		_start_reload()
		return

	if _fire_cd > 0.0:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	if player.has_method("is_hidden") and player.is_hidden():
		return

	var angle_to_player := (player.global_position - global_position).angle()
	var diff = abs(wrapf(angle_to_player - rotation, -PI, PI))

	if diff > deg_to_rad(30):
		return

	_fire_cd = fire_interval
	_shoot()
	_ammo -= 1


func _shoot() -> void:
	if not has_node("Muzzle"):
		return

	var muzzle := $Muzzle
	var bullet := bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.global_position = muzzle.global_position

	var dir := Vector2.RIGHT.rotated(rotation)
	if aim_spread_deg > 0.0:
		dir = dir.rotated(deg_to_rad(randf_range(-aim_spread_deg, aim_spread_deg)))

	if bullet.has_method("setup"):
		bullet.setup(dir, bullet_speed)


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
