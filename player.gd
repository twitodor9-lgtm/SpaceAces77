extends Area2D
@export var ability_label_path: NodePath
@export var ability_label_duration: float = 0.8
var _ability_label_timer: float = 0.0
@onready var _ability_label: Label = get_node_or_null("/root/Main/UI/AbilityLabel") as Label

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
@onready var hidden_label: Label = null
@onready var loop_label: Label = null

var is_doing_loop := false

# =========================
# Shooting
# =========================
@export var bullet_scene: PackedScene = preload("res://Bullet.tscn")
@export var shoot_cooldown: float = 0.15
var can_shoot := true

# =========================
# Bombs
# =========================
@export var bomb_scene: PackedScene = preload("res://Bomb.tscn")
@export var bomb_cooldown: float = 1.0
var can_drop_bomb := true

# =========================
# Visual scale
# =========================
@export var base_scale: Vector2 = Vector2.ONE

# =========================
# Cloud hiding
# =========================
var _in_cloud: bool = false

func _ready() -> void:
	var canvas_layer = CanvasLayer.new()
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

	base_scale = Vector2(abs(base_scale.x), abs(base_scale.y))
	scale = base_scale

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("FLY")
				
	add_to_group("player")

	_ability_label = get_node_or_null(ability_label_path) as Label
	if _ability_label:
		_ability_label.text = ""
	print("ability_label_path=", ability_label_path, " label=", _ability_label)
	print("AbilityLabel=", _ability_label)
	_ability_label = get_tree().get_first_node_in_group("ability_label") as Label
	if is_instance_valid(_ability_label):
		_ability_label.visible = false
		_ability_label.text = ""

	# ✅ Lives init
	lives = max_lives
	_lives_label = get_node_or_null("/root/Main/UI2/LivesLabel") as Label
	_update_lives_label()

func _process(delta: float) -> void:
	if hidden_label and _in_cloud:
		hidden_label.position = Vector2(screen_size.x / 2 - 90, 50)
	
	# Abilities
	if Input.is_action_just_pressed("ability_way_jump"):
		var a = get_node_or_null(way_jump_path)
		if a and a.has_method("try_use"):
			a.try_use()
	if Input.is_action_just_pressed("ability_way_jump"):
		print("INPUT: way_jump pressed")

	if Input.is_action_just_pressed("ability_turbo"):
		var b = get_node_or_null(turbo_path)
		if b and b.has_method("try_use"):
			b.try_use()
	if Input.is_action_just_pressed("ability_turbo"):
		print("INPUT: turbo pressed")
	
	# שליטה רק אם לא בלופ
	if not is_doing_loop:
		if Input.is_action_pressed("ui_left"):
			rotation -= rotation_speed * delta
		if Input.is_action_pressed("ui_right"):
			rotation += rotation_speed * delta

	scale = base_scale

	# ✅ TURBO משפיע רק על מהירות התנועה
	var turbo_speed := forward_speed * _turbo_mult
	var velocity := Vector2(turbo_speed, 0.0).rotated(rotation)
	position += velocity * delta

	_wraparound()
	
	if Input.is_action_pressed("ui_select") and can_shoot and not is_doing_loop:
		shoot()

	if Input.is_action_pressed("drop_bomb") and can_drop_bomb and not is_doing_loop:
		drop_bomb()

	if Input.is_action_just_pressed("do_loop") and not is_doing_loop:
		_do_loop()

	# אחרי התנועה / בסוף _process
	if _ability_label_timer > 0.0:
		_ability_label_timer -= delta
	if _ability_label_timer <= 0.0:
		if is_instance_valid(_ability_label):
			_ability_label.text = ""

	# ⭐ STAR PUNCH – קריאה ישירה ל־Ability
	if Input.is_action_just_pressed("star_punch"):
		if has_node("Abilities/StarPunch"):
			$Abilities/StarPunch.try_use()
	if Input.is_action_just_pressed("dolphin_wave"):
		$Abilities/DolphinWaveAbility.try_use()
	if Input.is_action_just_pressed("dolphin_wave"):
		var n := $Abilities.get_node_or_null("DolphinWaveAbility")
		print("DolphinWaveAbility node=", n)
		if n:
			n.try_use()
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

func _wraparound() -> void:
	# ✅ חדש:
	# - אם יוצאים למעלה/צדדים => bounce חזרה
	# - למטה: אם יש קרקע בשלב => מאבדים חיים, אחרת bounce
	# - בזמן WayJump => wrap שמאל↔ימין בלבד

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

	# X bounds: wrap רק כשהוא פעיל (WayJump)
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

	# Y top: תמיד bounce
	if position.y < m:
		position.y = m
		_bounce(Vector2.DOWN)

	# Y bottom: קרקע/חלל
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
	tween.tween_property(self, "rotation", end_rot, 1.1)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

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

@export var way_jump_path: NodePath
@export var turbo_path: NodePath

var _invuln_until_ms: int = 0
var _turbo_mult: float = 1.0

func set_invulnerable(seconds: float) -> void:
	_invuln_until_ms = Time.get_ticks_msec() + int(seconds * 1000.0)

func is_invulnerable() -> bool:
	return Time.get_ticks_msec() < _invuln_until_ms

var _turbo_seq: int = 0

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
	print("SHOW_ABILITY_TEXT called: ", text, "  label=", _ability_label, "  path=", ability_label_path)

	if not is_instance_valid(_ability_label):
		print("❌ AbilityLabel is null/invalid")
		return

	_ability_label.text = text
	_ability_label.visible = true
	_ability_label_timer = ability_label_duration
	print("✅ AbilityLabel text set to: ", _ability_label.text)
