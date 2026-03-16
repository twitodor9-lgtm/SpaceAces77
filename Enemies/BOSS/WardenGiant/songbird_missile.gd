extends Area2D

@export var speed: float = 340.0
@export var turn_speed: float = 10.0
@export var lifetime: float = 3.2
@export var damage: int = 1
@export var shooter_immunity_time: float = 0.30

@export var weave_strength: float = 0.85
@export var separation_strength: float = 120.0

var target: Node2D = null
var shooter: Node2D = null
var vel: Vector2 = Vector2.RIGHT
var _seed: float = 0.0
var _can_hit_shooter: bool = false

func set_target(t: Node2D) -> void:
	target = t

func set_shooter(s: Node2D) -> void:
	shooter = s

func set_initial_direction(dir: Vector2) -> void:
	if dir.length() > 0.001:
		vel = dir.normalized()

func _ready() -> void:
	monitoring = true
	monitorable = true

	for i in range(1, 33):
		set_collision_mask_value(i, true)

	_seed = randf() * TAU
	add_to_group("enemy_projectiles")
	add_to_group("songbirds")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	if shooter_immunity_time <= 0.0:
		_can_hit_shooter = true
	else:
		_arm_after_delay()

	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func _arm_after_delay() -> void:
	await get_tree().create_timer(shooter_immunity_time).timeout
	if is_instance_valid(self):
		_can_hit_shooter = true

func _physics_process(delta: float) -> void:
	var desired: Vector2 = vel
	if target != null and is_instance_valid(target):
		desired = (target.global_position - global_position).normalized()

	var t: float = float(Time.get_ticks_msec()) / 1000.0
	var weave: Vector2 = Vector2(cos(t * 8.0 + _seed), sin(t * 8.0 + _seed)) * weave_strength
	desired = (desired + weave).normalized()

	var push: Vector2 = Vector2.ZERO
	var arr: Array = get_tree().get_nodes_in_group("songbirds")
	for n in arr:
		if n == self:
			continue
		var other: Node2D = n as Node2D
		if other == null:
			continue
		var d: float = global_position.distance_to(other.global_position)
		if d > 0.001 and d < 34.0:
			push += (global_position - other.global_position) / d

	if push.length() > 0.001:
		desired = (desired + push.normalized() * (separation_strength * 0.001)).normalized()

	vel = vel.lerp(desired, clampf(turn_speed * delta, 0.0, 1.0)).normalized()
	global_position += vel * speed * delta
	rotation = vel.angle()

func _on_body_entered(body: Node) -> void:
	_try_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _try_hit(hit: Node) -> void:
	if hit == null:
		return

	if shooter == null and hit.is_in_group("boss"):
		return

	if shooter != null and hit == shooter:
		if not _can_hit_shooter:
			return

		if _apply_damage(hit):
			queue_free()
		return

	if _apply_damage(hit):
		queue_free()

func _apply_damage(hit: Node) -> bool:
	if hit.has_method("apply_homing_missile_hit"):
		hit.call("apply_homing_missile_hit", damage)
		return true
	if hit.has_method("take_damage"):
		hit.call("take_damage", damage)
		return true
	if hit.has_method("hurt"):
		hit.call("hurt", damage)
		return true
	return false