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

# שונות בין מטוסים כדי שלא יהיו מסונכרנים
@export var y_offset_range: float = 160.0
@export var aim_lead: float = 0.18

var _speed: float = 0.0
var _y_offset: float = 0.0

# =========================
# Entry behavior
# =========================
@export var enter_margin: float = 80.0
var _entering: bool = true

# =========================
# Looping (big loops)
# =========================
@export var loop_chance: float = 0.22
@export var loop_min_time: float = 1.4
@export var loop_max_time: float = 2.6
@export var loop_cooldown_min: float = 2.8
@export var loop_cooldown_max: float = 5.0

@export var loop_turn_rate: float = 1.35
@export var loop_speed_boost: float = 1.25

var _looping: bool = false
var _loop_time_left: float = 0.0
var _loop_cd_left: float = 0.0
var _loop_dir: float = 1.0

# =========================
# Shooting / Ammo
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
# Safety lifetime
# =========================
@export var life_time: float = 12.0


func _ready() -> void:
	add_to_group("air_enemies")
	add_to_group("enemies")
	_y_offset = randf_range(-y_offset_range, y_offset_range)

	_fire_cd = randf_range(0.0, fire_interval)
	_loop_cd_left = randf_range(0.0, loop_cooldown_max)

	_ammo = clip_size
	_speed = base_speed

	# כניסה מהצד הימני: שיפנה שמאלה פנימה
	rotation = PI

	get_tree().create_timer(life_time).timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)


func _process(delta: float) -> void:
	# קירור טיימרים
	if _fire_cd > 0.0:
		_fire_cd -= delta
	if _loop_cd_left > 0.0:
		_loop_cd_left -= delta

	# תמיד שומרים מהירות מינימלית כדי שלא "יעמוד"
	_speed = clamp(_speed, min_speed, max_speed)

	# שלב כניסה: טוס ישר לתוך המסך
	if _entering:
		_enter_move(delta)
		_try_shoot(delta)
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D

	# אם אין שחקן כרגע - תמשיך ישר
	if player == null:
		_move_forward(delta)
		return

	# מצב לופ
	if _looping:
		_loop_time_left -= delta

		var target_speed = clamp(base_speed * loop_speed_boost, min_speed, max_speed)
		_speed = _move_toward(_speed, target_speed, accel * delta)

		rotation += _loop_dir * loop_turn_rate * delta
		_move_forward(delta)
		_try_shoot(delta)

		if _loop_time_left <= 0.0:
			_looping = false
		return

	# טיסה רגילה
	_ai_fly_like_player(player, delta)

	_try_start_loop(player)
	_move_forward(delta)
	_try_shoot(delta)


# -------------------------
# Entry
# -------------------------
func _enter_move(delta: float) -> void:
	_speed = _move_toward(_speed, base_speed, accel * delta)
	_move_forward(delta)

	var w = get_viewport_rect().size.x
	if global_position.x < w - enter_margin:
		_entering = false


# -------------------------
# Core movement
# -------------------------
func _move_forward(delta: float) -> void:
	var vel = Vector2(_speed, 0.0).rotated(rotation)
	position += vel * delta


# -------------------------
# AI steering (smooth turn)
# -------------------------
func _ai_fly_like_player(player: Node2D, delta: float) -> void:
	var target_pos = player.global_position + Vector2(0.0, _y_offset)

	var to_target = target_pos - global_position
	var desired_angle = to_target.angle()

	var dist = to_target.length()
	var current_turn_rate = turn_rate
	if dist < engage_distance:
		current_turn_rate = engage_turn_rate

	var angle_diff = wrapf(desired_angle - rotation, -PI, PI)
	var max_turn = current_turn_rate * delta
	rotation += clamp(angle_diff, -max_turn, max_turn)

	var desired_speed = base_speed
	if dist < engage_distance:
		desired_speed = clamp(base_speed * 1.08, min_speed, max_speed)

	_speed = _move_toward(_speed, desired_speed, accel * delta)


# -------------------------
# Loop start logic
# -------------------------
func _try_start_loop(player: Node2D) -> void:
	if _loop_cd_left > 0.0:
		return

	var dist = global_position.distance_to(player.global_position)
	if dist > engage_distance:
		return

	if randf() < loop_chance:
		_looping = true
		_loop_time_left = randf_range(loop_min_time, loop_max_time)
		_loop_cd_left = randf_range(loop_cooldown_min, loop_cooldown_max)

		_loop_dir = -1.0 if randf() < 0.5 else 1.0


# -------------------------
# Shooting
# -------------------------
func _try_shoot(delta: float) -> void:
	if _reloading:
		return
	if bullet_scene == null:
		return
	if _ammo <= 0:
		_start_reload()
		return
	if _fire_cd > 0.0:
		return

	_fire_cd = fire_interval
	_shoot()
	_ammo -= 1


func _shoot() -> void:
	if bullet_scene == null:
		print("No bullet scene!")
		return
	
	# הנתיב הנכון למוזל
	var muzzle: Node2D = null
	if has_node("Sprite2D/Muzzle"):
		muzzle = $Sprite2D/Muzzle
	elif has_node("Muzzle"):
		muzzle = $Muzzle
	
	if muzzle == null:
		print("Warning: No Muzzle node found!")
		return
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	# הכדור יוצא מהמיקום המדויק של המוזל
	bullet.global_position = muzzle.global_position
	
	# ⭐ חישוב הכיוון - לוקח בחשבון flip
	var sprite: Sprite2D = $Sprite2D
	var dir: Vector2 = Vector2.RIGHT.rotated(global_rotation)
	
	# אם הספרייט הפוך אופקית - הפוך את כיוון X
	if sprite.flip_h:
		dir.x = -dir.x
	
	# אם הספרייט הפוך אנכית - הפוך את כיוון Y
	if sprite.flip_v:
		dir.y = -dir.y
	
	dir = dir.normalized()
	
	# פיזור אופציונלי
	if aim_spread_deg > 0.0:
		var spread = deg_to_rad(randf_range(-aim_spread_deg, aim_spread_deg))
		dir = dir.rotated(spread)
	
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
# Small helper
# -------------------------
func _move_toward(v: float, to: float, step: float) -> float:
	if v < to:
		return min(v + step, to)
	return max(v - step, to)
