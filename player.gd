extends Area2D

# =========================
# UI: Ability label
# =========================
@export var ability_label_path: NodePath
@export var ability_label_duration: float = 0.8
var _ability_label_timer: float = 0.0
var _ability_label: Label = null
var is_hidden_low: bool = false

# =========================
# Bounds / Ground / Lives
# =========================
@export var bounds_margin: float = 18.0
@export var crash_invuln: float = 1.0
@export var max_lives: int = 3
@export var show_lives_label: bool = true

var lives: int = 3
var _wrap_x_until_ms: int = 0
var _lives_label: Label = null

# =========================
# Flight
# =========================
@export var forward_speed: float = 250.0
@export var rotation_speed: float = 2.5

var screen_size: Vector2
var hidden_label: Label = null
var loop_label: Label = null
var is_doing_loop: bool = false

# =========================
# Shooting
# =========================
@export var bullet_scene: PackedScene = preload("res://Bullet.tscn")
@export var shoot_cooldown: float = 0.15
var can_shoot: bool = true

# =========================
# Bombs
# =========================
@export var bomb_scene: PackedScene = preload("res://Bomb.tscn")
@export var bomb_cooldown: float = 1.0
var can_drop_bomb: bool = true

# =========================
# Visual scale
# =========================
@export var base_scale: Vector2 = Vector2.ONE

# =========================
# Cloud hiding
# =========================
var _in_cloud: bool = false

# =========================
# Ability nodes (optional)
# =========================
@export var way_jump_path: NodePath
@export var turbo_path: NodePath

# =========================
# Invulnerability / Turbo
# =========================
var _invuln_until_ms: int = 0
var _turbo_mult: float = 1.0
var _turbo_seq: int = 0

# ============================================================
# DEFLECTOR SHIELD (absolute protection + ricochet)
# ============================================================
const ACTION_DEFLECTOR_SHIELD: StringName = &"ability_deflector_shield"
const DEFLECTOR_DEFAULT_KEY := KEY_F

var _shield_seq: int = 0
var _shield_until_ms: int = 0
var _shield_speed_mult: float = 1.15
var _shield_spread_deg: float = 16.0
var _shield_fx: DeflectorShieldFX = null


func _ready() -> void:
	# ---- UI labels (Hidden / Loop) ----
	var canvas_layer := CanvasLayer.new()
	add_child(canvas_layer)

	hidden_label = Label.new()
	hidden_label.text = "🌥️ HIDDEN 🌥️"
	hidden_label.add_theme_font_size_override("font_size", 32)
	hidden_label.add_theme_color_override("font_color", Color.YELLOW)
	hidden_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hidden_label.visible = false
	canvas_layer.add_child(hidden_label)

	loop_label = Label.new()
	loop_label.text = "🔁 LOOP!"
	loop_label.add_theme_font_size_override("font_size", 36)
	loop_label.add_theme_color_override("font_color", Color.ORANGE_RED)
	loop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loop_label.visible = false
	canvas_layer.add_child(loop_label)

	screen_size = get_viewport_rect().size
	hidden_label.position = Vector2(screen_size.x / 2 - 90, 50)
	loop_label.position = Vector2(screen_size.x / 2 - 70, 100)

	# ---- visual scale ----
	base_scale = Vector2(abs(base_scale.x), abs(base_scale.y))
	scale = base_scale

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("FLY")

	add_to_group("player")

	# ---- Ensure shield input action exists ----
	_ensure_deflector_shield_action()

	# ---- Resolve ability label ----
	_ability_label = null
	if ability_label_path != NodePath("") and has_node(ability_label_path):
		_ability_label = get_node_or_null(ability_label_path) as Label
	if _ability_label == null:
		_ability_label = get_node_or_null("/root/Main/UI/AbilityLabel") as Label
	if _ability_label == null:
		_ability_label = get_tree().get_first_node_in_group("ability_label") as Label

	if is_instance_valid(_ability_label):
		_ability_label.visible = false
		_ability_label.text = ""

	# ---- Lives init ----
	lives = max_lives
	_lives_label = get_node_or_null("/root/Main/UI2/LivesLabel") as Label
	_update_lives_label()

	# ---- Make sure we receive bullets ----
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func _ensure_deflector_shield_action() -> void:
	# creates action + default key (F) without touching project.godot
	if InputMap.has_action(ACTION_DEFLECTOR_SHIELD):
		return
	InputMap.add_action(ACTION_DEFLECTOR_SHIELD)
	var ev := InputEventKey.new()
	ev.physical_keycode = DEFLECTOR_DEFAULT_KEY
	InputMap.action_add_event(ACTION_DEFLECTOR_SHIELD, ev)


func _process(delta: float) -> void:
	# keep labels anchored
	if hidden_label and _in_cloud:
		hidden_label.position = Vector2(screen_size.x / 2 - 90, 50)

	# ---- Abilities ----
	if Input.is_action_just_pressed(ACTION_DEFLECTOR_SHIELD):
		var s := get_node_or_null("Abilities/Deflector Shield")
		if s == null and has_node("Abilities"):
			s = $Abilities.get_node_or_null("Deflector Shield")
		if s and s.has_method("try_use"):
			s.try_use()

	if Input.is_action_just_pressed("ability_way_jump"):
		var a := (get_node_or_null(way_jump_path) if way_jump_path != NodePath("") else null)
		if a and a.has_method("try_use"):
			a.try_use()

	if Input.is_action_just_pressed("ability_turbo"):
		var t := (get_node_or_null(turbo_path) if turbo_path != NodePath("") else null)
		if t and t.has_method("try_use"):
			t.try_use()

	# STAR PUNCH / Dolphin wave (if exist)
	if Input.is_action_just_pressed("star_punch") and has_node("Abilities/StarPunch"):
		$Abilities/StarPunch.try_use()

	if Input.is_action_just_pressed("dolphin_wave") and has_node("Abilities/DolphinWaveAbility"):
		$Abilities/DolphinWaveAbility.try_use()

	# ---- rotation controls (disabled during loop) ----
	if not is_doing_loop:
		if Input.is_action_pressed("ui_left"):
			rotation -= rotation_speed * delta
		if Input.is_action_pressed("ui_right"):
			rotation += rotation_speed * delta

	# keep fixed scale
	scale = base_scale

	# ---- movement ----
	var turbo_speed := forward_speed * _turbo_mult
	var velocity := Vector2(turbo_speed, 0.0).rotated(rotation)
	position += velocity * delta

	_wraparound()

	# ---- weapons (disabled during loop) ----
	if Input.is_action_pressed("ui_select") and can_shoot and not is_doing_loop:
		shoot()

	if Input.is_action_pressed("drop_bomb") and can_drop_bomb and not is_doing_loop:
		drop_bomb()

	if Input.is_action_just_pressed("do_loop") and not is_doing_loop:
		_do_loop()

	# ---- ability label timeout ----
	if _ability_label_timer > 0.0:
		_ability_label_timer -= delta
		if _ability_label_timer <= 0.0 and is_instance_valid(_ability_label):
			_ability_label.text = ""
			_ability_label.visible = false


func enable_horizontal_wrap(seconds: float) -> void:
	_wrap_x_until_ms = max(_wrap_x_until_ms, Time.get_ticks_msec() + int(seconds * 1000.0))


func _wrap_x_active() -> bool:
	return Time.get_ticks_msec() < _wrap_x_until_ms


func _bounce(normal: Vector2) -> void:
	var dir := Vector2(1, 0).rotated(rotation)
	dir = dir.bounce(normal)
	if dir.length() < 0.001:
		dir = normal
	rotation = dir.angle()


func _update_lives_label() -> void:
	if not show_lives_label:
		return
	if not is_instance_valid(_lives_label):
		return
	_lives_label.text = "Lives: %d" % lives


func _lose_life(reason: String) -> void:
	if is_invulnerable():
		return
	lives -= 1
	_update_lives_label()
	set_invulnerable(crash_invuln)
	print("PLAYER HIT:", reason, " lives=", lives)
	if lives <= 0:
		print("PLAYER DEAD")

func take_damage(amount: int = 1) -> void:
	for i in range(max(amount, 1)):
		_lose_life("DIRECT_HIT")


func _wraparound() -> void:
	screen_size = get_viewport_rect().size
	var m := bounds_margin

	var main := get_tree().current_scene
	var has_ground := true
	if main and main.has_method("stage_has_ground"):
		has_ground = bool(main.call("stage_has_ground"))

	var ground_y := screen_size.y
	if has_ground and main:
		var gl := main.get_node_or_null("GroundLine") as Node2D
		if gl:
			ground_y = gl.global_position.y

	# X bounds: wrap only when active (WayJump)
	if _wrap_x_active():
		if position.x < -m:
			position.x = screen_size.x + m
		elif position.x > screen_size.x + m:
			position.x = -m
	else:
		if position.x < m:
			position.x = m
			_bounce(Vector2.RIGHT)
		elif position.x > screen_size.x - m:
			position.x = screen_size.x - m
			_bounce(Vector2.LEFT)

	# Y top: always bounce
	if position.y < m:
		position.y = m
		_bounce(Vector2.DOWN)

	# Y bottom: ground/space behavior
	if has_ground:
		if position.y > ground_y:
			position.y = maxf(m, ground_y - m)
			_lose_life("GROUND")
			_bounce(Vector2.UP)
	else:
		if position.y > screen_size.y - m:
			position.y = screen_size.y - m
			_bounce(Vector2.UP)


# ============================================================
# LOOP MANEUVER
# ============================================================
func _do_loop() -> void:
	print("✈️ LOOP START")

	is_doing_loop = true
	can_shoot = false

	if loop_label:
		loop_label.visible = true

	get_tree().call_group("ground_enemies", "on_player_loop")
	get_tree().call_group("air_enemies", "on_player_loop")

	var end_rot := rotation + TAU
	var tween := create_tween()
	tween.tween_property(self, "rotation", end_rot, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	rotation = fmod(rotation, TAU)
	is_doing_loop = false
	can_shoot = true

	if loop_label:
		loop_label.visible = false


# ============================================================
# SHOOT
# ============================================================
func shoot() -> void:
	can_shoot = false
	var bullet = bullet_scene.instantiate()

	var spawn_pos := global_position
	if has_node("AnimatedSprite2D/GunPoint"):
		spawn_pos = $AnimatedSprite2D/GunPoint.global_position
	else:
		spawn_pos = global_position + Vector2(40, 0).rotated(rotation)

	bullet.global_position = spawn_pos
	bullet.rotation = rotation
	get_tree().current_scene.add_child(bullet)

	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true


# ============================================================
# BOMB
# ============================================================
func drop_bomb() -> void:
	can_drop_bomb = false
	var bomb = bomb_scene.instantiate()
	bomb.global_position = global_position
	get_tree().current_scene.add_child(bomb)

	await get_tree().create_timer(bomb_cooldown).timeout
	can_drop_bomb = true


# ============================================================
# CLOUD HIDING
# ============================================================
func enter_cloud() -> void:
	_in_cloud = true
	modulate.a = 0.5
	if hidden_label:
		hidden_label.visible = true


func exit_cloud() -> void:
	_in_cloud = false
	modulate.a = 1.0
	if hidden_label:
		hidden_label.visible = false


func is_hidden() -> bool:
	return _in_cloud


# ============================================================
# INVULNERABLE / TURBO
# ============================================================
func set_invulnerable(seconds: float) -> void:
	_invuln_until_ms = Time.get_ticks_msec() + int(seconds * 1000.0)


func is_invulnerable() -> bool:
	return Time.get_ticks_msec() < _invuln_until_ms


func apply_turbo(mult: float, duration: float) -> void:
	_turbo_seq += 1
	var seq := _turbo_seq

	_turbo_mult = mult
	print("Player: TURBO mult=", mult)

	await get_tree().create_timer(duration).timeout
	if _turbo_seq == seq:
		_turbo_mult = 1.0
		print("Player: TURBO END")


func show_ability_text(text: String) -> void:
	if not is_instance_valid(_ability_label):
		return
	_ability_label.text = text
	_ability_label.visible = true
	_ability_label_timer = ability_label_duration


# ============================================================
# DEFLECTOR SHIELD API (called by the ability node)
# ============================================================
func enable_deflector_shield(seconds: float, speed_mult: float = 1.15, spread_deg: float = 16.0) -> void:
	seconds = maxf(seconds, 0.05)

	_shield_seq += 1
	var seq := _shield_seq

	_shield_speed_mult = maxf(speed_mult, 0.1)
	_shield_spread_deg = maxf(spread_deg, 0.0)
	_shield_until_ms = Time.get_ticks_msec() + int(seconds * 1000.0)

	# full protection while shield is active
	set_invulnerable(seconds)

	_ensure_shield_fx()
	if is_instance_valid(_shield_fx):
		_shield_fx.start(seconds)

	await get_tree().create_timer(seconds).timeout
	if _shield_seq != seq:
		return

	_shield_until_ms = 0
	if is_instance_valid(_shield_fx):
		_shield_fx.stop()


func is_deflector_shield_active() -> bool:
	return Time.get_ticks_msec() < _shield_until_ms


func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return

	# detect enemy bullets
	var n := area.name.to_lower()
	var is_enemy_bullet := area.is_in_group("enemy_bullets") or area.is_in_group("EnemyBullets") or (n.find("bullet") != -1)

	# shield => deflect
	if is_enemy_bullet and is_deflector_shield_active():
		_deflect_enemy_bullet(area)
		return

	# normal hit
	if is_enemy_bullet:
		if not is_invulnerable():
			_lose_life("BULLET")
			set_invulnerable(crash_invuln)
		if is_instance_valid(area):
			area.queue_free()


func _deflect_enemy_bullet(b: Area2D) -> void:
	if not is_instance_valid(b):
		return
	if b.has_meta(&"deflected"):
		return
	b.set_meta(&"deflected", true)

	# Make it stop being "enemy_bullet" so it won't keep counting as enemy hits
	if b.is_in_group("enemy_bullets"):
		b.remove_from_group("enemy_bullets")
	if b.is_in_group("EnemyBullets"):
		b.remove_from_group("EnemyBullets")
	b.add_to_group("player_bullets")

	# Prefer bullet-native ricochet if supported
	if b.has_method("deflect_from"):
		b.call("deflect_from", global_position, _shield_speed_mult, _shield_spread_deg)
		if is_instance_valid(_shield_fx):
			_shield_fx.pulse()
		return

	# fallback: rotate outward + push away (works if bullet moves by rotation)
	var out_dir := (b.global_position - global_position).normalized()
	if out_dir.length() < 0.001:
		out_dir = Vector2.RIGHT
	if _shield_spread_deg > 0.0:
		out_dir = out_dir.rotated(deg_to_rad(randf_range(-_shield_spread_deg, _shield_spread_deg)))

	b.global_position += out_dir * 26.0
	b.rotation = out_dir.angle()

	if is_instance_valid(_shield_fx):
		_shield_fx.pulse()


func _ensure_shield_fx() -> void:
	if is_instance_valid(_shield_fx):
		return
	_shield_fx = DeflectorShieldFX.new()
	add_child(_shield_fx)
	_shield_fx.z_index = 2000
	_shield_fx.visible = false


class DeflectorShieldFX extends Node2D:
	var _t := 0.0
	var _dur := 1.0
	var _active := false
	var _pulse := 0.0

	func _ready() -> void:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat
		visible = false
		set_process(false)

	func start(seconds: float) -> void:
		_dur = maxf(seconds, 0.05)
		_t = 0.0
		_pulse = 0.0
		_active = true
		visible = true
		set_process(true)

	func stop() -> void:
		_active = false
		visible = false
		set_process(false)

	func pulse() -> void:
		_pulse = 1.0

	func _process(delta: float) -> void:
		if not _active:
			return
		_t += delta
		_pulse = maxf(_pulse - delta * 4.0, 0.0)
		rotation += delta * 1.8
		queue_redraw()
		if _t >= _dur:
			stop()

	func _draw() -> void:
		var u := clampf(_t / _dur, 0.0, 1.0)
		var fade := 1.0
		if u > 0.88:
			fade = lerpf(1.0, 0.0, (u - 0.88) / 0.12)

		var r := 26.0 + sin(_t * 10.0) * 1.6 + _pulse * 4.0
		var thick := 5.0 + _pulse * 2.5

		draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, Color(0.35, 0.75, 1.0, 0.55 * fade), thick)
		draw_arc(Vector2.ZERO, r * 0.86, 0.0, TAU, 96, Color(1.0, 1.0, 1.0, 0.18 * fade), maxf(thick - 2.0, 1.0))

		for i in range(6):
			var ang := (float(i) / 6.0) * TAU + _t * 2.6
			var v := Vector2.RIGHT.rotated(ang)
			draw_line(v * (r * 0.75), v * (r * 1.05), Color(0.8, 0.95, 1.0, 0.22 * fade), 2.0)
