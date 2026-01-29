extends Area2D

signal boss_died

@export var health: int = 300
@export var max_health: int = 300

# Movement
@export var enter_speed: float = 240.0
@export var hover_speed: float = 6.0
@export var y_clamp_ratio_top: float = 0.15
@export var y_clamp_ratio_bottom: float = 0.65

# Shooting (reuse your existing bullet scene)
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 260.0

# Attack A: spread burst
@export var burst_interval: float = 1.1
@export var burst_bullets: int = 7
@export var burst_spread_deg: float = 18.0

# Attack B: “beam” (rapid stream after charge)
@export var beam_interval: float = 4.0
@export var beam_charge_time: float = 0.7
@export var beam_duration: float = 1.2
@export var beam_tick: float = 0.06

var _state := 0 # 0=ENTER, 1=FIGHT, 2=CHARGE, 3=BEAM
var _t := 0.0

var _burst_cd := 0.0
var _beam_cd := 0.0
var _beam_fire_cd := 0.0

@onready var muzzle: Marker2D = $Muzzle

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	if max_health <= 0:
		max_health = health
	if health <= 0:
		health = max_health

	# Spawn just outside the visible right edge, upper area
	var r := _get_visible_world_rect()
	global_position = Vector2(r.position.x + r.size.x + 220.0, r.position.y + r.size.y * 0.30)
	print("BOSS READY:", get_path())

	_burst_cd = 1.0
	_beam_cd = 2.0

func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var r := _get_visible_world_rect()

	# Anchor position (boss “arena” position)
	var anchor_x: float = r.position.x + r.size.x * 0.78

	var min_y: float = r.position.y + r.size.y * y_clamp_ratio_top
	var max_y: float = r.position.y + r.size.y * y_clamp_ratio_bottom

	var desired_y: float = (player.global_position.y if player != null else (r.position.y + r.size.y * 0.35))
	var target_y: float = clampf(desired_y, min_y, max_y)

	var anchor_pos: Vector2 = Vector2(anchor_x, target_y)




	if _state == 0:
		# ENTER
		global_position = global_position.move_toward(anchor_pos, enter_speed * delta)
		if global_position.distance_to(anchor_pos) < 8.0:
			_state = 1
		return

	# Hover tracking (fight states)
	global_position = global_position.lerp(anchor_pos, 1.0 - pow(0.001, hover_speed * delta))

	# Timers
	_burst_cd = max(0.0, _burst_cd - delta)
	_beam_cd = max(0.0, _beam_cd - delta)

	match _state:
		1: # FIGHT
			if _burst_cd <= 0.0:
				_fire_burst(player)
				_burst_cd = burst_interval

			if _beam_cd <= 0.0:
				_state = 2
				_t = 0.0
				modulate = Color(1, 0.75, 0.75) # telegraph tint
		2: # CHARGE
			_t += delta
			if _t >= beam_charge_time:
				_state = 3
				_t = 0.0
				_beam_fire_cd = 0.0
				modulate = Color(1, 1, 1)
		3: # BEAM
			_t += delta
			_beam_fire_cd = max(0.0, _beam_fire_cd - delta)
			if _beam_fire_cd <= 0.0:
				_fire_beam_tick(player)
				_beam_fire_cd = beam_tick

			if _t >= beam_duration:
				_state = 1
				_beam_cd = beam_interval
func _fire_burst(player: Node2D) -> void:
	if bullet_scene == null or muzzle == null:
		return

	var base_dir: Vector2 = Vector2.LEFT
	if player != null:
		base_dir = (player.global_position - muzzle.global_position).normalized()

	for i in range(burst_bullets):
		var t: float = 0.0
		if burst_bullets > 1:
			t = float(i) / float(burst_bullets - 1)

		var angle: float = lerpf(-burst_spread_deg, burst_spread_deg, t)
		var dir: Vector2 = base_dir.rotated(deg_to_rad(angle))

		_spawn_bullet(dir)



		

func _fire_beam_tick(player: Node2D) -> void:
	if bullet_scene == null or muzzle == null:
		return

	var dir := Vector2.LEFT
	if player:
		dir = (player.global_position - muzzle.global_position).normalized()

	_spawn_bullet(dir)

func _spawn_bullet(dir: Vector2) -> void:
	var b := bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = muzzle.global_position
	if b.has_method("setup"):
		b.setup(dir, bullet_speed)

@export var max_damage_per_hit: int = 25

func take_damage(amount: int) -> void:
	print("BOSS HIT amount=", amount, " health_before=", health)

	var dmg: int = mini(amount, max_damage_per_hit)
	health -= dmg

	print("BOSS AFTER dmg=", dmg, " health_after=", health)

	if health <= 0:
		emit_signal("boss_died")
		queue_free()

	


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
func get_health_ratio() -> float:
	if max_health <= 0:
		return 0.0
	return float(health) / float(max_health)
