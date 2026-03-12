extends CharacterBody2D

signal lock_started(target: Node)
signal lock_ended(target: Node)

@export var max_hp: int = 300
@export var move_speed: float = 120.0
@export var gravity_strength: float = 900.0

# "כבדות" תנועה (תכוון באינספקטור)
@export var accel: float = 140.0     # קטן = מתחיל לזוז לאט (כבד)
@export var decel: float = 220.0     # קטן = עוצר לאט (כבד)

# כיוון ספרייט: אם ה-ART מצויר "פונה ימינה" ברירת מחדל -> true
# אם הוא מצויר "פונה שמאלה" ברירת מחדל -> false
@export var sprite_faces_right: bool = true

# דיבאג / שליטה בירי
@export var debug_attacks: bool = false
@export var bullet_speed_override: float = 0.0 # 0 => להשתמש במהירות שמוגדרת בפרוג'קטייל עצמו

# התקפות
@export var lock_duration: float = 0.75
@export var missiles_per_burst: int = 5
@export var missile_gap: float = 0.12
@export var overheat_duration: float = 1.25

@export var slam_range: float = 240.0
@export var slam_damage: int = 1
@export var slam_windup: float = 0.35
@export var slam_cooldown: float = 0.25

# Friendly fire מהטילים של הבוס
@export var self_missile_damage_scale: float = 1.0
@export var self_missile_bypass_overheat: bool = true

# סצנות
@export var bullet_scene: PackedScene
@export var fire_cooldown: float = 0.25
@export var missile_scene: PackedScene
@export var songbird_scene: PackedScene
@export var songbird_count: int = 14
@export var songbird_gap: float = 0.04
@export var songbird_chance: float = 0.35
@export var songbird_spread_deg: float = 38.0

# איתור שחקן
@export var Player_group: StringName = &"Player"

# נודים
@onready var anim: AnimatedSprite2D = $Anim
@onready var muzzle: Marker2D = $Muzzle
@onready var attack_timer: Timer = $AttackTimer

enum State { IDLE, WALK, LOCK, SHOOT, SLAM, OVERHEAT, DEAD }
var state: State = State.IDLE

var hp: int
var Player: Node2D
var _fire_cd_left := 0.0
var busy := false
var vulnerable := false
var _face_left: bool = false

func _ready() -> void:
	hp = max_hp
	add_to_group("boss")

	Player = _find_Player()

	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	_set_state(State.IDLE)
	_schedule_next_attack()

	if debug_attacks:
		print("[WardenGiant READY] bullet_scene=", bullet_scene,
			" missile_scene=", missile_scene,
			" songbird_scene=", songbird_scene,
			" Player_group=", Player_group,
			" fire_cd=", fire_cooldown,
			" bullet_speed_override=", bullet_speed_override)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if _fire_cd_left > 0.0:
		_fire_cd_left -= delta

	if Player == null or not is_instance_valid(Player):
		Player = _find_Player()

	# כבידה / רצפה
	if not is_on_floor():
		velocity.y += gravity_strength * delta
	else:
		velocity.y = 0.0

	# תנועה ימינה/שמאלה
	if busy or Player == null:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
	else:
		var dir: float = signf(Player.global_position.x - global_position.x)
		var target_vx := dir * move_speed
		velocity.x = move_toward(velocity.x, target_vx, accel * delta)

	_set_state(State.WALK if absf(velocity.x) > 1.0 else State.IDLE)
	move_and_slide()

	# מהירות אנימציה
	var speed_x := absf(velocity.x)
	if state == State.WALK:
		anim.speed_scale = clampf(speed_x / 120.0, 0.35, 1.1)
	else:
		anim.speed_scale = 1.0

	# כיוון - תמיד פונה לשחקן
	if Player != null and is_instance_valid(Player):
		var dx: float = Player.global_position.x - global_position.x
		if absf(dx) > 8.0:
			_face_left = dx < 0.0

	var want_flip_h := _face_left
	if not sprite_faces_right:
		want_flip_h = not want_flip_h
	anim.flip_h = want_flip_h

func _find_Player() -> Node2D:
	# 1) לפי הקבוצה שמוגדרת (ברירת מחדל: "Player")
	var arr := get_tree().get_nodes_in_group(Player_group)
	if arr.size() > 0 and arr[0] is Node2D:
		return arr[0] as Node2D

	# 2) fallback נפוץ: "player"
	arr = get_tree().get_nodes_in_group(&"player")
	if arr.size() > 0 and arr[0] is Node2D:
		return arr[0] as Node2D

	# 3) fallback אחרון: לפי שם node
	var n := get_tree().current_scene
	if n != null:
		var p := n.find_child("Player", true, false)
		if p != null and p is Node2D:
			return p as Node2D

	return null

# -------------------------
# תזמון התקפה
# -------------------------
func _schedule_next_attack() -> void:
	if state == State.DEAD:
		return
	attack_timer.stop()
	attack_timer.wait_time = randf_range(0.9, 1.5)
	attack_timer.start()
	if debug_attacks:
		print("[ATTACK SCHEDULE] wait_time=", attack_timer.wait_time, " stopped?=", attack_timer.is_stopped())

func _on_attack_timer_timeout() -> void:
	if busy or Player == null:
		_schedule_next_attack()
		return

	var dist: float = global_position.distance_to(Player.global_position)

	if debug_attacks:
		print("[ATTACK TICK] busy=", busy,
			" player=", Player,
			" dist=", dist,
			" slam_range=", slam_range,
			" missile_scene=", missile_scene,
			" bullet_scene=", bullet_scene,
			" songbird_scene=", songbird_scene)

	if dist <= slam_range and randf() < 0.50:
		if debug_attacks:
			print("[ATTACK] SLAM")
		_do_slam()
	else:
		if songbird_scene != null and randf() < songbird_chance:
			if debug_attacks:
				print("[ATTACK] LOCK->SONGBIRDS")
			_do_lock_then_songbirds()
		else:
			if debug_attacks:
				print("[ATTACK] LOCK->MISSILES/BULLETS")
			_do_lock_then_missiles()

# -------------------------
# LOCK -> SONGBIRDS -> OVERHEAT
# -------------------------
func _do_lock_then_songbirds() -> void:
	busy = true
	_set_state(State.LOCK)
	lock_started.emit(Player)

	await get_tree().create_timer(lock_duration).timeout

	_set_state(State.SHOOT)
	await _fire_songbirds()

	lock_ended.emit(Player)

	await _enter_overheat()
	busy = false
	_schedule_next_attack()

func _fire_songbirds() -> void:
	if songbird_scene == null or Player == null:
		return

	var base_dir := (Player.global_position - muzzle.global_position).normalized()
	if base_dir.length() < 0.001:
		base_dir = Vector2.RIGHT

	var spread_rad := deg_to_rad(songbird_spread_deg)

	for i in range(songbird_count):
		var m = songbird_scene.instantiate()

		# חשוב: להגדיר shooter/target לפני add_child כדי למנוע self-collision בפריים הראשון
		if m.has_method("set_shooter"):
			m.call("set_shooter", self)
		if m.has_method("set_target"):
			m.call("set_target", Player)

		get_tree().current_scene.add_child(m)

		if m is Node2D:
			(m as Node2D).global_position = muzzle.global_position

		var t := 0.0
		if songbird_count > 1:
			t = float(i) / float(songbird_count - 1)
		var ang := lerpf(-spread_rad * 0.5, spread_rad * 0.5, t)
		var dir := base_dir.rotated(ang)

		if m.has_method("set_initial_direction"):
			m.call("set_initial_direction", dir)

		if debug_attacks:
			print("[SONGBIRD] spawned #", i, " node=", m, " pos=", (m as Node2D).global_position if (m is Node2D) else "n/a")

		await get_tree().create_timer(songbird_gap).timeout

# -------------------------
# LOCK -> "BULLETS" (fallback to missiles) -> OVERHEAT
# -------------------------
func _do_lock_then_missiles() -> void:
	busy = true
	_set_state(State.LOCK)
	lock_started.emit(Player)

	# ירי burst
	for i in range(missiles_per_burst):
		_fire_bullet()
		await get_tree().create_timer(missile_gap).timeout

	await get_tree().create_timer(lock_duration).timeout

	_set_state(State.SHOOT)
	# אם יש missile_scene נמשיך עם טילים "אמיתיים" אחרי ה-lock
	await _fire_missiles()

	lock_ended.emit(Player)

	await _enter_overheat()
	busy = false
	_schedule_next_attack()

func _fire_missiles() -> void:
	if missile_scene == null or Player == null:
		if debug_attacks:
			print("[MISSILES] ABORT: missile_scene=", missile_scene, " Player=", Player)
		return

	if debug_attacks:
		print("[MISSILES] spawning count=", missiles_per_burst, " gap=", missile_gap)

	for i in range(missiles_per_burst):
		var m = missile_scene.instantiate()

		# חשוב: להגדיר shooter/target לפני add_child כדי למנוע self-collision בפריים הראשון
		if m.has_method("set_shooter"):
			m.call("set_shooter", self)
		if m.has_method("set_target"):
			m.call("set_target", Player)

		get_tree().current_scene.add_child(m)

		if m is Node2D:
			(m as Node2D).global_position = muzzle.global_position

		if debug_attacks:
			print("[MISSILES] spawned #", i, " node=", m, " pos=", (m as Node2D).global_position if (m is Node2D) else "n/a")

		await get_tree().create_timer(missile_gap).timeout

# -------------------------
# SLAM -> OVERHEAT
# -------------------------
func _do_slam() -> void:
	busy = true
	_set_state(State.SLAM)

	await get_tree().create_timer(slam_windup).timeout

	if Player != null and is_instance_valid(Player):
		if global_position.distance_to(Player.global_position) <= slam_range:
			_damage_Player(Player, slam_damage)

	await get_tree().create_timer(slam_cooldown).timeout
	await _enter_overheat()

	busy = false
	_schedule_next_attack()

# -------------------------
# OVERHEAT (חלון פגיעות)
# -------------------------
func _enter_overheat() -> void:
	_set_state(State.OVERHEAT)
	vulnerable = true
	await get_tree().create_timer(overheat_duration).timeout
	vulnerable = false
	_set_state(State.IDLE)

# -------------------------
# דמג' לבוס
# -------------------------
func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	if amount <= 0:
		return
	if not vulnerable:
		return

	hp -= amount
	if hp <= 0:
		_die()

func apply_homing_missile_hit(amount: int) -> void:
	if state == State.DEAD:
		return
	if amount <= 0:
		return
	if (not vulnerable) and (not self_missile_bypass_overheat):
		return

	var final_damage: int = maxi(1, int(round(float(amount) * self_missile_damage_scale)))
	hp -= final_damage

	if debug_attacks:
		print("[BOSS FRIENDLY FIRE] dmg=", final_damage, " hp=", hp, "/", max_hp, " vulnerable=", vulnerable)

	if hp <= 0:
		_die()

func _die() -> void:
	state = State.DEAD
	busy = true
	vulnerable = false
	_play("overheat")
	queue_free()

# -------------------------
# דמג' לשחקן (fallback)
# -------------------------
func _damage_Player(p: Node, amount: int) -> void:
	if p.has_method("take_damage"):
		p.call("take_damage", amount)
	elif p.has_method("hurt"):
		p.call("hurt", amount)

# -------------------------
# אנימציות
# -------------------------
func _set_state(s: State) -> void:
	if state == State.DEAD:
		return
	state = s
	match state:
		State.IDLE: _play("idle")
		State.WALK: _play("walk")
		State.LOCK: _play("lock")
		State.SHOOT: _play("shoot")
		State.SLAM: _play("slam")
		State.OVERHEAT: _play("overheat")

func _play(anim_name: String) -> void:
	if anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation(anim_name):
		if anim.animation != anim_name:
			anim.play(anim_name)
	else:
		print("Missing animation in SpriteFrames: ", anim_name)

# -------------------------
# ירי "כדור" עם fallback לטיל
# -------------------------
func _fire_bullet() -> void:
	if Player == null or not is_instance_valid(Player):
		if debug_attacks:
			print("[BULLET] ABORT: no Player")
		return
	if _fire_cd_left > 0.0:
		if debug_attacks:
			print("[BULLET] ABORT: cooldown=", _fire_cd_left)
		return

	var root := get_tree().current_scene
	if root == null:
		if debug_attacks:
			print("[BULLET] ABORT: no current_scene")
		return

	var proj: Node = null
	var use_missile_fallback := false

	if bullet_scene == null:
		use_missile_fallback = true
	else:
		proj = bullet_scene.instantiate()
		if not (proj.has_method("setup")
			or proj.has_method("set_direction")
			or proj.has_method("set_velocity")
			or proj.has_method("set_dir")
			or proj.has_method("set_target")
			or proj.has_method("start")):
			use_missile_fallback = true

	if use_missile_fallback:
		if missile_scene == null:
			if debug_attacks:
				print("[BULLET] ABORT: no bullet_scene + no missile_scene fallback")
			return
		proj = missile_scene.instantiate()

	# קודם להגדיר shooter/target כדי למנוע self-collision לפני שהסיגנלים עובדים
	if proj.has_method("set_shooter"):
		proj.call("set_shooter", self)
	if proj.has_method("set_target"):
		proj.call("set_target", Player)

	root.add_child(proj)

	if proj is Node2D:
		(proj as Node2D).global_position = muzzle.global_position

	var dir := (Player.global_position - muzzle.global_position).normalized()
	if dir.length() < 0.001:
		dir = Vector2.RIGHT

	if proj.has_method("setup"):
		var spd := bullet_speed_override if bullet_speed_override > 0.0 else 420.0
		proj.call("setup", dir, spd)
		if debug_attacks:
			print("[BULLET] setup dir=", dir, " spd=", spd, " proj=", proj)
	else:
		if proj.has_method("set_direction"):
			proj.call("set_direction", dir)
		elif proj.has_method("set_dir"):
			proj.call("set_dir", dir)
		elif proj.has_method("set_initial_direction"):
			proj.call("set_initial_direction", dir)

		if debug_attacks:
			print("[BULLET] dir-set dir=", dir, " proj=", proj)

	if proj.has_method("start"):
		proj.call("start")

	_fire_cd_left = fire_cooldown
